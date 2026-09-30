import 'package:pb_sim/src/combat/impact.dart';
import 'package:pb_sim/src/match/match_state.dart';
import 'package:pb_sim/src/match/sim_event.dart';
import 'package:pb_sim/src/match/turn_effects.dart';
import 'package:pb_sim/src/pirate/ammo.dart';
import 'package:pb_sim/src/projectile/projectile.dart';
import 'package:pb_sim/src/ship/ship_grid.dart';
import 'package:pb_sim/src/world/world.dart';

/// 두 배 사이 거리 구분 (설계서 §2.6 거리에 따른 계열 상성).
enum Reach { near, mid, far }

/// 가까울 때 간격 16칸 이하, 멀 때 36칸 이상 (설계서 §2.6).
Reach reachOf(MatchState state) {
  final gap = (state.sides[0].bowX - state.sides[1].bowX).abs();
  if (gap <= 16 * cellUnit) return Reach.near;
  if (gap >= 36 * cellUnit) return Reach.far;
  return Reach.mid;
}

/// 탄 [p] 가 [target] 배 로컬 칸 ([cx], [cy]), 월드 ([x], [y]) 에 닿았다 (설계서 §4.8).
/// 탄이 계속 날아가면(관통) false, 끝나면 true.
bool onHullHit(
  MatchState state,
  Projectile p,
  SideState target, {
  required int cx,
  required int cy,
  required int x,
  required int y,
}) {
  final spec = p.spec;
  final events = state.events;
  void impact({int blockPercent = 100, int piratePercent = 100}) =>
      resolveImpact(
        target,
        spec: spec,
        cx: cx,
        cy: cy,
        x: x,
        y: y,
        events: events,
        blockPercent: blockPercent,
        centerPiratePercent: piratePercent,
      );
  switch (spec.ammo) {
    case AmmoType.pierce:
      // 칸마다 피해를 주며 뚫는다. 블록이 버티면(철판 등) 멈춘다.
      impact();
      if (!target.grid.hasBlock(cx, cy) && p.pierceLeft > 1) {
        p.pierceLeft--;
        return false;
      }
      return true;
    case AmmoType.mine:
      _attachMine(state, p, target, target.grid.indexOf(cx, cy));
      return true;
    case AmmoType.assault:
      // 착지 반경의 해적을 물어뜯고, 살아남으면 다음 상대 턴 시작에 또 문다.
      impact();
      for (var i = 0; i < spec.ammoValue; i++) {
        state.effects.add(
          TurnEffect(
            kind: EffectKind.biteAgain,
            owner: p.side,
            ownerSlot: p.slot,
            target: target.side,
            trigger: target.side,
            turnsLeft: i + 1,
            spec: spec,
            cell: target.grid.indexOf(cx, cy),
          ),
        );
      }
      return true;
    case AmmoType.support:
      _repairAround(state, target, cx, cy, spec.ammoParam, spec.ammoValue);
      return true;
    case AmmoType.flock when spec.ammoParam == 1 && !p.divided:
      _markDrop(state, p, target, x);
      return true;
    case AmmoType.skip:
      // 수면에서 튕긴 뒤 맞으면 흘수선 명중 ×1.5 (설계서 §4.3 계열 기준 수치).
      impact(blockPercent: p.bounced ? 150 : 100);
      return true;
    case AmmoType.sniper:
      impact(piratePercent: spec.ammoValue);
      return true;
    case AmmoType.explosive ||
        AmmoType.fire ||
        AmmoType.split ||
        AmmoType.burst ||
        AmmoType.chain ||
        AmmoType.flock ||
        AmmoType.homing:
      impact();
      return true;
  }
}

/// 탄 [p] 가 [target] 쪽 바다 ([x], 0) 에 닿았다. 물수제비는 튕기고, 설치탄은 배 밑에
/// 붙고, 투하 표시는 그 자리를 표시한다. 탄이 계속 날면 false.
bool onSeaHit(
  MatchState state,
  Projectile p,
  SideState target,
  int x,
  int tick,
) {
  final spec = p.spec;
  if (spec.ammo == AmmoType.skip && p.bouncesLeft > 0) {
    p
      ..bouncesLeft -= 1
      ..bounced = true
      ..x = x
      ..y = 0
      ..vy = -p.vy * 55 ~/ 100
      ..vx = p.vx * 85 ~/ 100;
    state.events.add(
      SimEvent(SimEventKind.bounce, side: target.side, x: x, value: tick),
    );
    return false;
  }
  if (spec.ammo == AmmoType.mine) {
    final cell = _hullCellBelow(target, x);
    if (cell >= 0) {
      _attachMine(state, p, target, cell);
      return true;
    }
  }
  if (spec.ammo == AmmoType.flock && spec.ammoParam == 1 && !p.divided) {
    _markDrop(state, p, target, x);
    return true;
  }
  state.events.add(
    SimEvent(SimEventKind.splash, side: target.side, x: x, value: tick),
  );
  resolveSplash(target, spec: spec, x: x, events: state.events);
  return true;
}

/// 설치탄: 붙은 칸에서 `ammoValue` 턴 뒤 내 턴 시작에 터진다. 멀 때는 도달에
/// 1턴 더 걸린다 (설계서 §2.6).
void _attachMine(MatchState state, Projectile p, SideState target, int cell) {
  final delay = p.spec.ammoValue + (reachOf(state) == Reach.far ? 1 : 0);
  state.effects.add(
    TurnEffect(
      kind: EffectKind.mineBlast,
      owner: p.side,
      ownerSlot: p.slot,
      target: target.side,
      trigger: p.side,
      turnsLeft: delay,
      spec: p.spec,
      cell: cell,
    ),
  );
  state.events.add(
    SimEvent(SimEventKind.mineAttached, side: target.side, cell: cell),
  );
}

/// 펠리: 떨어진 곳을 표시하고 다음 내 턴 시작에 소형 폭탄을 떨군다 (설계서 §4.2).
void _markDrop(MatchState state, Projectile p, SideState target, int x) {
  state.effects.add(
    TurnEffect(
      kind: EffectKind.flockDrop,
      owner: p.side,
      ownerSlot: p.slot,
      target: target.side,
      trigger: p.side,
      turnsLeft: 1,
      spec: p.spec,
      x: x,
    ),
  );
}

/// 바다 [x] 아래 선체 칸: 그 세로줄에서 흘수선에 가장 가까운 블록. 선체 밖이면 −1.
int _hullCellBelow(SideState target, int x) {
  final grid = target.grid;
  final lx = target.frame.toLocalX(x);
  if (lx < 0 || lx >= grid.width * cellUnit) return -1;
  final cx = lx ~/ cellUnit;
  final water = (target.draft ~/ cellUnit).clamp(0, grid.height - 1);
  for (var d = 0; d < grid.height; d++) {
    for (final cy in [water - d, water + d]) {
      if (cy >= 0 && cy < grid.height && grid.hasBlock(cx, cy)) {
        return grid.indexOf(cx, cy);
      }
    }
  }
  return -1;
}

/// 지원탄: 착지한 칸에서 가까운 ‘구멍’ 단계 블록 [count] 칸을 고친다. 고치는 양은
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
