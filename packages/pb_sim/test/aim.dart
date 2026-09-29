import 'package:pb_sim/pb_sim.dart';

/// 테스트용 조준: 지금 턴 진영의 [slot] 해적이 지금 자리·바람에서 상대 배 로컬 칸
/// ([tx], [ty]) 을 지나는 궤적을 찾아 FIRE 커맨드로 돌려준다. 다른 블록에 가로막히는
/// 것은 보지 않는다. [highArc] 면 가장 높은 각도, 아니면 가장 낮은 각도를 고른다.
FireCommand aimAt(
  MatchState state, {
  required int slot,
  required int tx,
  required int ty,
  int t = 1000,
  int power = maxFirePower,
  bool highArc = false,
}) {
  final side = state.activeSide;
  final shooter = state.sides[side];
  final frame = state.sides[1 - side].frame;
  final spec = shooter.crew.pirates[slot].spec;
  final cabin = shooter.cabins[slot];
  final (x, y) = shooter.frame.cellCenter(cabin.x, cabin.y);
  final wind = state.wind * state.rules.windAccel;
  FireCommand? found;
  for (var angle = 1000; angle <= 85000; angle += 250) {
    final p = Projectile.launch(
      id: 0,
      side: side,
      slot: slot,
      spec: spec,
      x: x,
      y: y,
      angle: angle,
      power: power,
    );
    while (!p.isExpired && p.y >= 0) {
      final x0 = p.x;
      final y0 = p.y;
      p.advance(wind);
      final hit = traceCells(
        frame.toLocalX(x0),
        y0,
        frame.toLocalX(p.x),
        p.y,
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
