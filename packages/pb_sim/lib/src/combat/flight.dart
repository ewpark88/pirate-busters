import 'package:pb_sim/src/combat/hit_effects.dart';
import 'package:pb_sim/src/combat/launch.dart';
import 'package:pb_sim/src/combat/volley.dart';
import 'package:pb_sim/src/match/match_state.dart';
import 'package:pb_sim/src/match/sim_event.dart';
import 'package:pb_sim/src/math/fx.dart';
import 'package:pb_sim/src/pirate/ammo.dart';
import 'package:pb_sim/src/projectile/grid_trace.dart';
import 'package:pb_sim/src/projectile/projectile.dart';

/// 탄 하나를 떨어질 때까지 틱 단위로 진행하고 날아간 틱 수를 돌려준다.
/// 여러 발·갈라지는 탄종도 [runVolley] 로 함께 계산한다.
int resolveShot(MatchState state, Projectile p, int ms) =>
    runVolley(state, [p], ms);

/// 탄이 맞는 배의 진영: 지원탄은 내 배, 나머지는 상대 배 (설계서 §4.1 지원).
int targetSideOf(Projectile p) =>
    p.spec.ammo == AmmoType.support ? p.side : 1 - p.side;

/// 탄 [p] 를 한 틱 진행한다. 끝났으면 true.
///
/// 틱 사이 구간을 맞는 배 로컬 격자에서 DDA 로 훑고, 해수면(y = 0) 아래로 내려가면
/// 바다에 닿는다. 맞는 배는 파도에 흔들리므로 발사 시각 [ms](실제 시각)부터 [tick]
/// 틱 뒤의 위치를 다시 잡는다. 이벤트의 [SimEvent.value] 에 [tick] 을 넣는다.
bool stepShot(MatchState state, Projectile p, int wind, int ms, int tick) {
  final x0 = p.x;
  final y0 = p.y;
  p.advance(wind);
  var x1 = p.x;
  var y1 = p.y;
  final hitsSea = y1 < 0;
  if (hitsSea) {
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
          (cx, cy) => grid.hasBlock(cx, cy) || target.isExposedPirateAt(cx, cy),
        )
      : null;
  if (hit != null) {
    final (wx, wy) = fromShipLocal(state, target.side, at, hit.x, hit.y);
    state.events.add(
      SimEvent(
        SimEventKind.impact,
        side: target.side,
        cell: grid.indexOf(hit.cx, hit.cy),
        x: wx,
        y: wy,
        value: tick,
      ),
    );
    return onHullHit(state, p, target, cx: hit.cx, cy: hit.cy, x: wx, y: wy);
  }
  if (hitsSea) return onSeaHit(state, p, target, x1, tick);
  return p.isExpired;
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
