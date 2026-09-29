import 'package:pb_sim/pb_sim.dart';

/// 테스트용 조준: 지금 턴 진영의 [slot] 해적이 커맨드 시각 [t] 에 상대 배 로컬 칸
/// ([tx], [ty]) 을 지나는 궤적을 찾아 FIRE 커맨드로 돌려준다. 시뮬레이션과 같은
/// 발사 계산(파도·기울기, `launchShot`)과 파도에 흔들리는 표적(`frameAtMs`)을 쓴다.
/// 다른 블록에 가로막히는 것은 보지 않는다. [highArc] 면 가장 높은 각도, 아니면 가장
/// 낮은 각도를 고른다.
FireCommand aimAt(
  MatchState state, {
  required int slot,
  required int tx,
  required int ty,
  int t = 1000,
  int power = maxFirePower,
  bool highArc = false,
}) {
  final target = 1 - state.activeSide;
  final ms = realMs(state, effectiveMs(state, t));
  final wind = state.wind * state.rules.windAccel;
  FireCommand? found;
  for (var angle = 1000; angle <= 85000; angle += 250) {
    final p = launchShot(
      state,
      slot: slot,
      angle: angle,
      power: power,
      ms: ms,
    );
    while (!p.isExpired && p.y >= 0) {
      final x0 = p.x;
      final y0 = p.y;
      p.advance(wind);
      final frame = frameAtMs(state, target, msAfterTicks(ms, p.age));
      final hit = traceCells(
        frame.toLocalX(x0),
        frame.toLocalY(y0),
        frame.toLocalX(p.x),
        frame.toLocalY(p.y),
        (cx, cy) => cx == tx && cy == ty,
      );
      if (hit != null) {
        found = FireCommand(t: t, slot: slot, angle: angle, power: power);
        break;
      }
    }
    if (found != null && !highArc) return found;
  }
  return found ?? (throw StateError('($tx, $ty) 에 닿는 궤적이 없다'));
}
