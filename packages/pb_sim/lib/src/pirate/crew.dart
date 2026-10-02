import 'package:pb_sim/src/match/sim_event.dart';
import 'package:pb_sim/src/math/fx.dart';
import 'package:pb_sim/src/pirate/ability.dart';
import 'package:pb_sim/src/pirate/pirate_spec.dart';

/// 선실이 부서져 떨어질 때 입는 피해: 최대 체력의 20% (ADR-010).
const int fallDamagePercent = 20;

/// 해적의 위치 상태. 순서는 해시에 들어가므로 바꾸지 않는다.
enum PirateStatus {
  /// 선실에 타고 있다. 쿨다운이 끝났으면 쏠 수 있다.
  aboard,

  /// 바다에 떨어졌다. 다음 내 턴 시작에 돌아오고, 그 전에 맞으면 KO.
  swimming,

  /// 쓰러졌다(KO).
  down,
}

/// 출전 해적 한 명의 전투 상태. 선실 슬롯 번호 = 출전 순서.
class PirateState {
  PirateState(this.spec) : hp = spec.hp;

  final PirateSpec spec;
  int hp;
  PirateStatus status = PirateStatus.aboard;

  /// 한 번 되살아났는가(데비, ADR-078). 해시에 들어간다.
  bool revived = false;

  /// 남은 쿨다운. 0 이면 쏠 수 있다. 쏘면 `cooldownTurns + 1` 이 되고 내 턴이
  /// 끝날 때마다 1 줄어서, 같은 턴에 다시 쏘지 못하고 `cooldownTurns` 만큼 내 턴을
  /// 건너뛴다 (설계서 §2.3).
  int cooldown = 0;
}

/// 한 진영의 출전 해적 (설계서 §2.3, §3.1). 모두 판 시작부터 선실에 타고 교대는
/// 없다. 쓰러진 해적의 선실은 판이 끝날 때까지 빈다.
class Crew {
  Crew(List<PirateSpec> lineup)
    : pirates = List.unmodifiable([for (final s in lineup) PirateState(s)]);

  /// 슬롯 순서의 해적.
  final List<PirateState> pirates;

  int get size => pirates.length;

  /// 슬롯의 해적. 슬롯 번호가 범위 밖이면 null.
  PirateState? pirateAt(int slot) =>
      slot >= 0 && slot < pirates.length ? pirates[slot] : null;

  /// 이번 턴에 이미 쏜 슬롯 (설계서 §2.3 “서로 다른 해적”). 턴이 끝나면 비운다.
  late final List<bool> firedThisTurn = List.filled(pirates.length, false);

  /// 슬롯 해적이 선실에 타 있고 쿨다운이 끝났고 이번 턴에 아직 안 쐈는가.
  bool canFire(int slot) {
    final p = pirateAt(slot);
    return p != null &&
        p.status == PirateStatus.aboard &&
        p.cooldown == 0 &&
        !firedThisTurn[slot];
  }

  /// 전멸: 모두 KO (설계서 §2.4).
  bool get allDown => pirates.every((p) => p.status == PirateStatus.down);

  /// 쐈다. 쿨다운을 건다.
  void markFired(int slot) {
    final p = pirates[slot];
    p.cooldown = p.spec.cooldownTurns + 1;
    firedThisTurn[slot] = true;
  }

  /// 슬롯 해적에게 [amount] 피해. [side] 는 이벤트용 진영.
  void damage(int slot, int amount, int side, List<SimEvent> events) {
    final p = pirateAt(slot);
    if (p == null || amount <= 0 || p.status == PirateStatus.down) return;
    // 바다에 빠진 해적은 맞으면 KO (설계서 §2.3).
    final dealt = p.status == PirateStatus.swimming ? p.hp : amount;
    p.hp = dealt >= p.hp ? 0 : p.hp - dealt;
    events.add(
      SimEvent(SimEventKind.pirateHit, side: side, slot: slot, value: dealt),
    );
    if (p.hp > 0) return;
    // 해골 선장 데비는 한 번 체력 절반으로 되살아난다 (설계서 §4.2, ADR-078).
    if (p.spec.ability == Ability.summon && !p.revived) {
      p
        ..revived = true
        ..hp = p.spec.hp ~/ 2;
      events.add(SimEvent(SimEventKind.revived, side: side, slot: slot));
      return;
    }
    p.status = PirateStatus.down;
    events.add(SimEvent(SimEventKind.pirateDown, side: side, slot: slot));
  }

  /// 선실이 부서지거나 무너졌다. 타 있던 해적이 다치고 바다로 떨어진다.
  void fall(int slot, int side, List<SimEvent> events) {
    final p = pirateAt(slot);
    if (p == null || p.status != PirateStatus.aboard) return;
    damage(slot, roundDiv(p.spec.hp * fallDamagePercent, 100), side, events);
    if (p.status != PirateStatus.aboard) return;
    p.status = PirateStatus.swimming;
    events.add(SimEvent(SimEventKind.pirateFell, side: side, slot: slot));
  }

  /// 내 턴 시작: 바다에 빠진 해적이 배로 돌아온다.
  void startOwnTurn(int side, List<SimEvent> events) {
    for (var slot = 0; slot < pirates.length; slot++) {
      final p = pirates[slot];
      if (p.status != PirateStatus.swimming) continue;
      p.status = PirateStatus.aboard;
      events.add(SimEvent(SimEventKind.pirateReturned, side: side, slot: slot));
    }
  }

  /// 내 턴 끝: 쿨다운을 1 줄인다 (턴 끝 처리 4번째, 설계서 §2.3).
  void endOwnTurn() {
    for (var slot = 0; slot < pirates.length; slot++) {
      final p = pirates[slot];
      if (p.cooldown > 0) p.cooldown--;
      firedThisTurn[slot] = false;
    }
  }
}
