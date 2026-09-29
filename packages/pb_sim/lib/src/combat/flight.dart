import 'package:pb_sim/src/combat/impact.dart';
import 'package:pb_sim/src/combat/launch.dart';
import 'package:pb_sim/src/match/match_state.dart';
import 'package:pb_sim/src/match/sim_event.dart';
import 'package:pb_sim/src/math/fx.dart';
import 'package:pb_sim/src/projectile/grid_trace.dart';
import 'package:pb_sim/src/projectile/projectile.dart';

/// 탄 하나를 떨어질 때까지 틱 단위로 진행하고 날아간 틱 수를 돌려준다.
///
/// 턴제라 한 번에 탄 하나만 난다. 탄은 쏜 진영의 배에는 닿지 않는다(아군 지원
/// 사격은 M5). 틱 사이 구간을 상대 배 로컬 격자에서 DDA 로 훑고, 해수면(y = 0)
/// 아래로 내려가면 물보라로 끝난다. 이벤트의 [SimEvent.value] 에 착탄 틱을 넣는다.
/// 맞는 배는 파도에 흔들리므로 발사 시각 [ms](실제 시각)부터 틱마다 위치를 다시 잡는다.
int resolveShot(MatchState state, Projectile p, int ms) {
  final wind = state.wind * state.rules.windAccel;
  while (true) {
    if (_advanceOne(state, p, wind, ms)) return p.age;
  }
}

/// 탄이 끝났으면 true.
bool _advanceOne(MatchState state, Projectile p, int wind, int ms) {
  final x0 = p.x;
  final y0 = p.y;
  p.advance(wind);
  var x1 = p.x;
  var y1 = p.y;
  final hitsSea = y1 < 0;
  if (hitsSea) {
    // 해수면과 만나는 지점까지만 배를 훑는다.
    x1 = x0 + roundDiv((x1 - x0) * y0, y0 - y1);
    y1 = 0;
  }

  final target = state.sides[1 - p.side];
  final frame = frameAtMs(state, target.side, msAfterTicks(ms, p.age));
  final grid = target.grid;
  final hit = traceCells(
    frame.toLocalX(x0),
    frame.toLocalY(y0),
    frame.toLocalX(x1),
    frame.toLocalY(y1),
    (cx, cy) => grid.hasBlock(cx, cy) || target.isExposedPirateAt(cx, cy),
  );
  if (hit != null) {
    final wx = frame.toWorldX(hit.x);
    state.events.add(
      SimEvent(
        SimEventKind.impact,
        side: target.side,
        cell: grid.indexOf(hit.cx, hit.cy),
        x: wx,
        y: frame.toWorldY(hit.y),
        value: p.age,
      ),
    );
    resolveImpact(
      target,
      spec: p.spec,
      cx: hit.cx,
      cy: hit.cy,
      x: wx,
      y: frame.toWorldY(hit.y),
      events: state.events,
    );
    return true;
  }
  if (hitsSea) {
    state.events.add(
      SimEvent(SimEventKind.splash, side: target.side, x: x1, value: p.age),
    );
    resolveSplash(target, spec: p.spec, x: x1, events: state.events);
    return true;
  }
  return p.isExpired;
}
