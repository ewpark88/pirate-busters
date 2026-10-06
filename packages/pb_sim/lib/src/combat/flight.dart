import 'package:pb_sim/src/combat/barrier_effects.dart';
import 'package:pb_sim/src/combat/block_damage.dart';
import 'package:pb_sim/src/combat/hit_effects.dart';
import 'package:pb_sim/src/combat/launch.dart';
import 'package:pb_sim/src/combat/unique_effects.dart';
import 'package:pb_sim/src/combat/volley.dart';
import 'package:pb_sim/src/match/barrier.dart';
import 'package:pb_sim/src/match/match_state.dart';
import 'package:pb_sim/src/match/sim_event.dart';
import 'package:pb_sim/src/math/fx.dart';
import 'package:pb_sim/src/pirate/ability.dart';
import 'package:pb_sim/src/pirate/ammo.dart';
import 'package:pb_sim/src/projectile/grid_trace.dart';
import 'package:pb_sim/src/projectile/projectile.dart';
import 'package:pb_sim/src/ship/material.dart';
import 'package:pb_sim/src/ship/support.dart';

/// 탄 하나를 떨어질 때까지 틱 단위로 진행하고 날아간 틱 수를 돌려준다.
/// 여러 발·갈라지는 탄종도 [runVolley] 로 함께 계산한다.
int resolveShot(MatchState state, Projectile p, int ms) =>
    runVolley(state, [p], ms);

/// 탄이 맞는 배의 진영: 지원탄은 내 배, 나머지는 상대 배 (설계서 §4.1 지원).
int targetSideOf(Projectile p) =>
    p.spec.ammo == AmmoType.support ? p.side : 1 - p.side;

/// 한 틱 진행한 결과: 맞은 칸(없으면 null), 해수면에 닿았는지, 끝 지점.
typedef TraceStep = ({
  TraceHit? hit,
  Barrier? wall,
  bool sea,
  int x,
  int y,
  SideState target,
  int at,
});

/// 탄 [p] 를 한 틱 옮기고 그 구간이 맞는 배·해수면에 닿는지 본다(상태·이벤트는
/// 바꾸지 않는다). 틱 사이 구간을 맞는 배 로컬 격자에서 DDA 로 훑는다. 맞는 배는
/// 파도에 흔들리므로 발사 시각 [ms](실제 시각)부터 [tick] 틱 뒤의 위치를 다시 잡는다.
TraceStep traceStep(
  MatchState state,
  Projectile p,
  int wind,
  int ms,
  int tick,
) {
  final x0 = p.x;
  final y0 = p.y;
  p.advance(wind);
  var x1 = p.x;
  var y1 = p.y;
  // 상대 산호 방벽을 지나면 막힌다(코리, ADR-078).
  final wall = barrierCrossed(state, p, x0, y0, x1, y1);
  // 어뢰(바라)는 수면에서 멈추지 않고 물속으로 들어간다(ADR-078).
  final sea = y1 < 0 && !p.submerged;
  if (sea) {
    // 해수면과 만나는 지점까지만 배를 훑는다. 발사는 해수면 위에서만 하므로
    // y0 ≥ 0 > y1 이라 나누는 수가 0 이 아니다.
    x1 = y0 <= 0 ? x0 : x0 + roundDiv((x1 - x0) * y0, y0 - y1);
    y1 = 0;
  }
  final target = state.sides[targetSideOf(p)];
  // 지원탄은 제 배에서 떠나므로 내려올 때만 닿는다.
  final canHit = target.side != p.side || p.vy < 0;
  final at = msAfterTicks(ms, tick);
  final grid = target.grid;
  final (lx0, ly0) = toShipLocal(state, target.side, at, x0, y0);
  final (lx1, ly1) = toShipLocal(state, target.side, at, x1, y1);
  final hit = canHit
      ? traceCells(
          lx0,
          ly0,
          lx1,
          ly1,
          (cx, cy) =>
              (grid.hasBlock(cx, cy) && grid.indexOf(cx, cy) != p.passedNet) ||
              target.isExposedPirateAt(cx, cy),
        )
      : null;
  return (
    hit: hit,
    wall: wall,
    sea: sea,
    x: x1,
    y: y1,
    target: target,
    at: at,
  );
}

/// 탄 [p] 를 한 틱 진행하고 닿은 곳의 효과를 낸다. 끝났으면 true.
/// 이벤트의 [SimEvent.value] 에 [tick] 을 넣는다.
bool stepShot(MatchState state, Projectile p, int wind, int ms, int tick) {
  final step = traceStep(state, p, wind, ms, tick);
  final target = step.target;
  final hit = step.hit;
  final wall = step.wall;
  if (wall != null) {
    hitBarrier(state, p, wall, tick: tick);
    return true;
  }
  if (p.submerged && p.y < -torpedoDepthLimit) return true;
  if (hit != null && passNet(p, target, hit.cx, hit.cy, events: state.events)) {
    return false;
  }
  if (hit != null) {
    final (wx, wy) = fromShipLocal(state, target.side, step.at, hit.x, hit.y);
    state.events.add(
      SimEvent(
        SimEventKind.impact,
        side: target.side,
        cell: target.grid.indexOf(hit.cx, hit.cy),
        x: wx,
        y: wy,
        value: tick,
      ),
    );
    return onHullHit(state, p, target, cx: hit.cx, cy: hit.cy, x: wx, y: wy);
  }
  if (step.sea) return onSeaHit(state, p, target, step.x, tick);
  return p.isExpired;
}

/// 망사 칸 ([cx], [cy]) 에 걸린 탄 (설계서 §3.2, BALANCE.md A3.2): 공중 계열은
/// 막혀 그 칸에 맞고(false), 나머지는 속도 50% 로 지나간다(true). [events] 가 있으면
/// 망사를 탄의 블록 피해만큼 깎는다(미리 계산에는 null).
bool passNet(
  Projectile p,
  SideState target,
  int cx,
  int cy, {
  List<SimEvent>? events,
}) {
  final grid = target.grid;
  if (grid.materialAt(cx, cy) != BlockMaterial.net) return false;
  if (p.spec.family == Family.air) return false;
  if (p.spec.ability == Ability.shred) {
    // 라이언은 망사(돛)를 늦춰지지 않고 찢어 없앤다(ADR-078).
    p.passedNet = grid.indexOf(cx, cy);
    if (events != null &&
        damageBlock(grid, target.side, cx, cy, grid.hpAt(cx, cy), events)) {
      for (final i in collapseUnsupported(grid)) {
        events.add(
          SimEvent(SimEventKind.blockCollapsed, side: target.side, cell: i),
        );
      }
    }
    return true;
  }
  p
    ..passedNet = grid.indexOf(cx, cy)
    ..vx = p.vx * netSlowPercent ~/ 100
    ..vy = p.vy * netSlowPercent ~/ 100;
  if (events != null &&
      damageBlock(grid, target.side, cx, cy, p.spec.blockDamage, events)) {
    for (final i in collapseUnsupported(grid)) {
      events.add(
        SimEvent(SimEventKind.blockCollapsed, side: target.side, cell: i),
      );
    }
  }
  return true;
}

/// 망사를 지나간 탄의 속도 비율(%) (BALANCE.md A3.2, 임시값 ADR-050).
const int netSlowPercent = 50;

/// 발사 전 [state] 에서 지금 턴 진영의 [slot] 해적이 쏠 탄의, 처음 닿는 곳(배 또는
/// 해수면)까지의 틱별 월드 위치 (렌더용 예측). 판정과 같은 [traceStep] 을 쓰므로
/// 계산을 미룬 분열탄이 탭 없이 떨어질 틱과 같다. 상태는 바꾸지 않는다.
({List<int> xs, List<int> ys}) predictFirstHit(
  MatchState state, {
  required int slot,
  required int angle,
  required int power,
  required int ms,
}) {
  final p = launchShot(state, slot: slot, angle: angle, power: power, ms: ms);
  final wind = state.wind * state.rules.windAccel;
  final xs = <int>[p.x];
  final ys = <int>[p.y];
  for (var tick = 1; !p.isExpired; tick++) {
    final step = traceStep(state, p, wind, ms, tick);
    final hit = step.hit;
    if (step.wall != null) {
      xs.add(step.x);
      ys.add(step.y);
      break;
    }
    if (hit != null && passNet(p, step.target, hit.cx, hit.cy)) {
      xs.add(step.x);
      ys.add(step.y);
      continue;
    }
    if (hit != null) {
      final (wx, wy) = fromShipLocal(
        state,
        step.target.side,
        step.at,
        hit.x,
        hit.y,
      );
      xs.add(wx);
      ys.add(wy);
      break;
    }
    xs.add(step.x);
    ys.add(step.y);
    if (step.sea) break;
  }
  return (xs: xs, ys: ys);
}

/// [from] 번째 이벤트부터(이번 발사) 블록이 부서지거나 무너졌으면 부서지는 연출만큼
/// 턴 타이머를 더 멈춘다 (설계서 §2.3).
int breakPauseOf(MatchState state, {required int from}) {
  final events = state.events;
  for (var i = from; i < events.length; i++) {
    final k = events[i].kind;
    if (k == SimEventKind.blockDestroyed || k == SimEventKind.blockCollapsed) {
      return state.rules.breakPauseMs;
    }
  }
  return 0;
}
