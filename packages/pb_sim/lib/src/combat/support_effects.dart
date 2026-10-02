import 'package:pb_sim/src/combat/ability_effects.dart';
import 'package:pb_sim/src/combat/barrier_effects.dart';
import 'package:pb_sim/src/match/match_state.dart';
import 'package:pb_sim/src/match/sim_event.dart';
import 'package:pb_sim/src/pirate/ability.dart';
import 'package:pb_sim/src/pirate/crew.dart';
import 'package:pb_sim/src/projectile/projectile.dart';
import 'package:pb_sim/src/ship/motion.dart';
import 'package:pb_sim/src/ship/ship_grid.dart';

/// 지원탄이 내 배 [ship] 의 칸 ([cx], [cy]) 에 닿았다 (설계서 §4.2 지원, §4.8).
/// 수리(톡)를 한 뒤 고유 능력(배수·쿨다운·램프, ADR-075)을 낸다. 지원 배율
/// `PirateSpec.ammoValue`(%) 는 수리량과 배수량에만 곱한다(쿨다운·연료는 정수 그대로,
/// BALANCE.md A4.2).
void onSupportHit(
  MatchState state,
  Projectile p,
  SideState ship, {
  required int cx,
  required int cy,
  required int x,
}) {
  final spec = p.spec;
  _repairAround(state, ship, cx, cy, spec.ammoParam, spec.ammoValue);
  if (p.abilityDone) return;
  final value = spec.abilityValue;
  switch (spec.ability) {
    case Ability.bail:
      addFlood(state, ship, -(value * spec.ammoValue ~/ 100));
    case Ability.coral:
      placeCoral(state, p, x);
    case Ability.cooldownCut:
      _heal(state, ship, cx, cy, cookHeal * spec.ammoValue ~/ 100);
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

/// 쿡 치유 범위: 착지 칸에서 가로·세로 2칸 안 선실 (ADR-078).
const int cookHealRange = 2;

/// 착지 칸 둘레 선실의 배 위 해적을 [amount] 만큼(최대 체력까지) 치유한다.
void _heal(MatchState state, SideState ship, int cx, int cy, int amount) {
  for (var slot = 0; slot < ship.crew.size; slot++) {
    final pirate = ship.crew.pirates[slot];
    if (pirate.status != PirateStatus.aboard) continue;
    final c = ship.cabins[slot];
    if ((c.x - cx).abs() > cookHealRange || (c.y - cy).abs() > cookHealRange) {
      continue;
    }
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

/// 지원탄 수리: 착지한 칸에서 가까운 ‘구멍’ 단계 블록 [count] 칸을 고친다. 고치는 양은
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
        SimEvent(SimEventKind.repaired, side: ship.side, cell: i),
      );
    }
  }
}
