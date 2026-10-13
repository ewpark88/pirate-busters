import 'package:pb_sim/src/match/sim_event.dart';
import 'package:pb_sim/src/pirate/pirate_spec.dart';

/// 해적의 위치 상태. 순서는 해시에 들어가므로 바꾸지 않는다.
enum PirateStatus {
  /// 선실(또는 망대)에 타고 있다. 쏠 수 있다.
  aboard,

  /// 쓰러졌다(KO). 바다에 빠져도 KO 다 (설계서 §2.3).
  down,

  /// 강습 해적이 적 배 위에 서 있다 (설계서 §2.3, §4.8, ADR-110). 쏠 수 없고,
  /// 살아 있는 해적으로 센다.
  boarding,
}

/// 출전 해적 한 명의 전투 상태. 슬롯 번호 = 출전 순서.
class PirateState {
  PirateState(this.spec) : hp = spec.hp;

  final PirateSpec spec;
  int hp;
  PirateStatus status = PirateStatus.aboard;

  /// 적 배 위에 섰을 때 밟은 칸(적 배 칸 번호, 그 위에 선다). 아니면 −1.
  /// [PirateStatus.boarding] 일 때만 해시에 들어간다.
  int boardCell = -1;
}

/// 한 진영의 출전 해적 (설계서 §2.3). 모두 판 시작부터 선실·망대에 타고 교대는 없다.
class Crew {
  Crew(List<PirateSpec> lineup)
    : pirates = List.unmodifiable([for (final s in lineup) PirateState(s)]);

  /// 슬롯 순서의 해적.
  final List<PirateState> pirates;

  /// 이 배에 올라온 강습 해적의 진영 해적 (ADR-110). 처음 올라올 때 정한다.
  Crew? foe;

  int get size => pirates.length;

  /// 슬롯의 해적. 슬롯 번호가 범위 밖이면 null.
  PirateState? pirateAt(int slot) =>
      slot >= 0 && slot < pirates.length ? pirates[slot] : null;

  /// 이번 턴에 이미 쏜 슬롯. 턴이 끝나면 비운다.
  late final List<bool> firedThisTurn = List.filled(pirates.length, false);

  /// 슬롯 해적이 배 위에 타 있고 이번 턴에 아직 안 쐈는가 (설계서 §2.3).
  bool canFire(int slot) {
    final p = pirateAt(slot);
    return p != null && p.status == PirateStatus.aboard && !firedThisTurn[slot];
  }

  /// 전멸: 모두 KO (설계서 §2.7).
  bool get allDown => pirates.every((p) => p.status == PirateStatus.down);

  /// 남은 체력 합 (턴 제한 판정, 설계서 §2.7).
  int get hpLeft {
    var n = 0;
    for (final p in pirates) {
      if (p.status != PirateStatus.down) n += p.hp;
    }
    return n;
  }

  /// 시작 체력 합.
  int get hpStart {
    var n = 0;
    for (final p in pirates) {
      n += p.spec.hp;
    }
    return n;
  }

  /// 쐈다.
  void markFired(int slot) => firedThisTurn[slot] = true;

  /// 슬롯 해적에게 [amount] 피해. [side] 는 이벤트용 진영.
  void damage(int slot, int amount, int side, List<SimEvent> events) {
    final p = pirateAt(slot);
    if (p == null || amount <= 0 || p.status == PirateStatus.down) return;
    final dealt = amount > p.hp ? p.hp : amount;
    p.hp -= dealt;
    events.add(
      SimEvent(SimEventKind.pirateHit, side: side, slot: slot, value: dealt),
    );
    if (p.hp > 0) return;
    p.status = PirateStatus.down;
    events.add(SimEvent(SimEventKind.pirateDown, side: side, slot: slot));
  }

  /// 선실이 무너지거나 돛대가 부러졌다. 타 있던 해적은 바다로 떨어져 KO 다
  /// (설계서 §2.3). 적 배 위에 선 강습 해적은 내 선실이 부서져도 떨어지지 않는다.
  void fall(int slot, int side, List<SimEvent> events) {
    final p = pirateAt(slot);
    if (p == null || p.status != PirateStatus.aboard) return;
    _drop(p, slot, side, events);
  }

  /// 적 배 위에 선 강습 해적이 흔들리거나 받침을 잃어 바다로 떨어진다(KO).
  /// 밟은 칸([PirateState.boardCell])은 화면이 떨어지는 자리로 쓰게 남긴다.
  void fallFromBoard(int slot, int side, List<SimEvent> events) {
    final p = pirateAt(slot);
    if (p == null || p.status != PirateStatus.boarding) return;
    _drop(p, slot, side, events);
  }

  void _drop(PirateState p, int slot, int side, List<SimEvent> events) {
    events.add(SimEvent(SimEventKind.pirateFell, side: side, slot: slot));
    p
      ..hp = 0
      ..status = PirateStatus.down;
    events.add(SimEvent(SimEventKind.pirateDown, side: side, slot: slot));
  }

  /// 내 턴 끝: 이번 턴에 쏜 기록을 비운다.
  void endOwnTurn() {
    for (var slot = 0; slot < pirates.length; slot++) {
      firedThisTurn[slot] = false;
    }
  }
}
