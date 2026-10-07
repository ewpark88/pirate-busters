import 'package:pb_sim/src/combat/ability_effects.dart';
import 'package:pb_sim/src/combat/barrier_effects.dart';
import 'package:pb_sim/src/match/match_state.dart';
import 'package:pb_sim/src/match/sim_event.dart';
import 'package:pb_sim/src/pirate/ability.dart';
import 'package:pb_sim/src/pirate/crew.dart';
import 'package:pb_sim/src/projectile/projectile.dart';
import 'package:pb_sim/src/ship/motion.dart';
import 'package:pb_sim/src/ship/ship_grid.dart';

/// 보급탄이 상대 배를 맞혔다: 효과는 쏜 쪽 내 배 [ship] 에 난다 (설계서 §4.2 보급,
/// §4.8, ADR-090). 수리(톡·램프)는 흘수선 아래 가운데에서 가까운 ‘구멍’부터, 그다음
/// 고유 능력(배수·치유와 쿨다운·램프·방벽). 보급 배율 `PirateSpec.ammoValue`(%) 는
/// 수리량·배수량·치유량에만 곱한다(쿨다운·연료는 정수 그대로, BALANCE.md A4.2).
/// 코리 방벽은 월드 [x] 에 선다.
void onSupportHit(
  MatchState state,
  Projectile p,
  SideState ship, {
  required int x,
}) {
  final spec = p.spec;
  _repairAround(
    state,
    ship,
    ship.grid.width ~/ 2,
    0,
    spec.ammoParam,
    spec.ammoValue,
  );
  if (p.abilityDone) return;
  final value = spec.abilityValue;
  switch (spec.ability) {
    case Ability.bail:
      addFlood(state, ship, -(value * spec.ammoValue ~/ 100));
    case Ability.coral:
      placeCoral(state, p, x);
    case Ability.cooldownCut:
      _heal(state, ship, cookHeal * spec.ammoValue ~/ 100);
      // 아군 전체(쏜 쿡 포함, BALANCE.md A4.2).
      for (var slot = 0; slot < ship.crew.size; slot++) {
        final pirate = ship.crew.pirates[slot];
        final next = pirate.cooldown - value;
        pirate.cooldown = next < 0 ? 0 : next;
      }
    case Ability.lantern:
      refuel(ship, value);
      final mine = state.turn + 2;
      ship.status
        ..trailBoostTurn = mine
        ..windIgnoreTurn = mine;
    case _:
      return;
  }
  p.abilityDone = true;
  state.events.add(
    SimEvent(
      SimEventKind.supported,
      side: ship.side,
      slot: p.slot,
      value: spec.ability.index,
    ),
  );
}

/// 쿡 치유량(지원 배율 100% 기준, BALANCE.md A4.2, 임시값 ADR-078).
const int cookHeal = 40;

/// 배 위 아군 해적 모두를 [amount] 만큼(최대 체력까지) 치유한다 (보급탄은 상대에 쏘므로
/// 범위 대신 아군 전체, ADR-090).
void _heal(MatchState state, SideState ship, int amount) {
  for (var slot = 0; slot < ship.crew.size; slot++) {
    final pirate = ship.crew.pirates[slot];
    if (pirate.status != PirateStatus.aboard) continue;
    final before = pirate.hp;
    final next = before + amount;
    pirate.hp = next > pirate.spec.hp ? pirate.spec.hp : next;
    if (pirate.hp == before) continue;
    state.events.add(
      SimEvent(
        SimEventKind.healed,
        side: ship.side,
        slot: slot,
        value: pirate.hp - before,
      ),
    );
  }
}

/// 보급탄 수리: ([cx], [cy]) 에서 가까운 ‘구멍’ 단계 블록 [count] 칸을 고친다. 고치는 양은
/// 최대 내구도 × [percent]% (설계서 §4.2 톡, §2.5 부서진 칸은 못 고침).
void _repairAround(
  MatchState state,
  SideState ship,
  int cx,
  int cy,
  int count,
  int percent,
) {
  final grid = ship.grid;
  final holes = <(int, int)>[];
  for (var i = 0; i < grid.cellCount; i++) {
    final x = i % grid.width;
    final y = i ~/ grid.width;
    if (grid.hasBlock(x, y) && grid.stageAt(x, y) == DamageStage.holed) {
      final d = (x - cx) * (x - cx) + (y - cy) * (y - cy);
      holes.add((d, i));
    }
  }
  holes.sort((a, b) => a.$1 != b.$1 ? a.$1 - b.$1 : a.$2 - b.$2);
  for (final (_, i) in holes.take(count)) {
    final x = i % grid.width;
    final y = i ~/ grid.width;
    final amount = grid.materialAt(x, y)!.durability * percent ~/ 100;
    if (grid.repair(x, y, amount)) {
      state.events.add(
        SimEvent(
          SimEventKind.repaired,
          side: ship.side,
          cell: i,
          y: grid.hpAt(x, y),
        ),
      );
    }
  }
}
