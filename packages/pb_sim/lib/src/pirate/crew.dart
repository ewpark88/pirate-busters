import 'package:pb_sim/src/match/match_state.dart';
import 'package:pb_sim/src/match/sim_event.dart';
import 'package:pb_sim/src/math/fx.dart';
import 'package:pb_sim/src/pirate/pirate_spec.dart';

/// 바다에서 헤엄쳐 돌아오는 시간: 4초 (설계서 §2.3).
const int swimTicks = 4 * simTickHz;

/// 선실이 부서져 떨어질 때 입는 피해: 최대 체력의 20%.
const int fallDamagePercent = 20;

/// 해적의 위치 상태.
enum PirateStatus {
  /// 교대 대기열에서 기다린다.
  queued,

  /// 선실에 타고 있다. 발사할 수 있다.
  aboard,

  /// 바다에 떨어져 헤엄치고 있다. 맞으면 죽는다.
  swimming,

  /// 쓰러졌다.
  down,
}

/// 덱의 해적 한 명의 전투 상태.
class PirateState {
  PirateState(this.spec) : hp = spec.hp;

  final PirateSpec spec;
  int hp;
  PirateStatus status = PirateStatus.queued;

  /// 탄 선실 슬롯. 대기 중이거나 쓰러졌으면 −1.
  int slot = -1;

  /// 남은 재장전 틱. 0 이면 발사할 수 있다.
  int reload = 0;

  /// 헤엄 남은 틱.
  int swim = 0;
}

/// 한 진영의 해적들 (설계서 §2.3, §3.1). 덱 앞에서부터 선실 슬롯에 타고, 나머지는
/// 교대 대기열에 선다. 선실의 해적이 쓰러지면 대기열의 다음 해적이 들어간다.
class Crew {
  Crew(List<PirateSpec> deck, int slotCount)
    : pirates = [for (final s in deck) PirateState(s)],
      _slotPirate = List<int>.filled(slotCount, -1) {
    for (var slot = 0; slot < slotCount; slot++) {
      _boardNext(slot);
    }
  }

  /// 덱 순서의 해적.
  final List<PirateState> pirates;

  /// 슬롯 → 해적 번호(덱 순서). 비었으면 −1.
  final List<int> _slotPirate;

  /// 다음에 탈 대기열 해적 번호.
  int _nextQueued = 0;

  int get slotCount => _slotPirate.length;

  /// 슬롯의 해적 번호. 비었으면 −1.
  int pirateIndexAt(int slot) =>
      slot >= 0 && slot < _slotPirate.length ? _slotPirate[slot] : -1;

  /// 슬롯의 해적. 비었으면 null.
  PirateState? pirateAt(int slot) {
    final i = pirateIndexAt(slot);
    return i < 0 ? null : pirates[i];
  }

  /// 슬롯 해적이 선실에 타 있고 재장전이 끝났는가.
  bool canFire(int slot) {
    final p = pirateAt(slot);
    return p != null && p.status == PirateStatus.aboard && p.reload == 0;
  }

  /// 살아 있는 해적이 하나도 없다 (전멸, 설계서 §2.4).
  bool get allDown => pirates.every((p) => p.status == PirateStatus.down);

  /// 슬롯 해적에게 [amount] 피해. [side] 는 이벤트용 진영.
  void damage(int slot, int amount, int side, List<SimEvent> events) {
    final p = pirateAt(slot);
    if (p == null || amount <= 0) return;
    if (p.status != PirateStatus.aboard && p.status != PirateStatus.swimming) {
      return;
    }
    // 헤엄치는 해적은 맞으면 죽는다 (설계서 §2.3).
    final dealt = p.status == PirateStatus.swimming ? p.hp : amount;
    p.hp = dealt >= p.hp ? 0 : p.hp - dealt;
    events.add(
      SimEvent(SimEventKind.pirateHit, side: side, slot: slot, value: dealt),
    );
    if (p.hp == 0) _down(slot, side, events);
  }

  /// 선실이 부서지거나 무너졌다. 타 있던 해적이 다치고 바다로 떨어진다.
  void fall(int slot, int side, List<SimEvent> events) {
    final p = pirateAt(slot);
    if (p == null || p.status != PirateStatus.aboard) return;
    damage(slot, roundDiv(p.spec.hp * fallDamagePercent, 100), side, events);
    if (p.status != PirateStatus.aboard) return;
    p
      ..status = PirateStatus.swimming
      ..swim = swimTicks;
    events.add(SimEvent(SimEventKind.pirateFell, side: side, slot: slot));
  }

  /// 한 틱: 재장전과 헤엄 시간을 줄인다.
  void tick(int side, List<SimEvent> events) {
    for (var slot = 0; slot < _slotPirate.length; slot++) {
      final p = pirateAt(slot);
      if (p == null) continue;
      if (p.reload > 0) p.reload--;
      if (p.status == PirateStatus.swimming && --p.swim == 0) {
        p.status = PirateStatus.aboard;
        events.add(
          SimEvent(SimEventKind.pirateReturned, side: side, slot: slot),
        );
      }
    }
  }

  void _down(int slot, int side, List<SimEvent> events) {
    pirateAt(slot)!
      ..status = PirateStatus.down
      ..slot = -1
      ..swim = 0;
    _slotPirate[slot] = -1;
    events.add(SimEvent(SimEventKind.pirateDown, side: side, slot: slot));
    _boardNext(slot, side: side, events: events);
  }

  /// 대기열의 다음 해적을 [slot] 에 태운다. 판 시작 탑승은 [events] 가 null 이고
  /// 재장전 없이 바로 쏠 수 있다. 교대로 들어온 해적은 재장전부터 한다.
  void _boardNext(int slot, {int side = 0, List<SimEvent>? events}) {
    if (_nextQueued >= pirates.length) return;
    final index = _nextQueued++;
    final p = pirates[index]
      ..status = PirateStatus.aboard
      ..slot = slot;
    _slotPirate[slot] = index;
    if (events == null) return;
    p.reload = p.spec.reloadTicks;
    events.add(
      SimEvent(
        SimEventKind.pirateBoarded,
        side: side,
        slot: slot,
        value: index,
      ),
    );
  }
}
