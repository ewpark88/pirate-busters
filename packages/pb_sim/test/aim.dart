import 'package:pb_sim/pb_sim.dart';

/// 테스트용 조준: [side] 의 [slot] 해적이 지금 자리에서 상대 배 로컬 칸
/// ([tx], [ty]) 을 지나는 궤적을 찾아 FIRE 커맨드로 돌려준다. 다른 블록에 가로막히는
/// 것은 보지 않는다. [highArc] 면 가장 높은 각도, 아니면 가장 낮은 각도를 고른다.
FireCommand aimAt(
  Match match, {
  required int side,
  required int slot,
  required int tx,
  required int ty,
  int power = maxFirePower,
  bool highArc = false,
}) {
  final state = match.state;
  final shooter = state.sides[side];
  final frame = state.sides[1 - side].frame;
  final spec = shooter.crew.pirateAt(slot)!.spec;
  final cabin = shooter.cabins[slot];
  final (x, y) = shooter.frame.cellCenter(cabin.x, cabin.y);
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
      p.advance(state.wind);
      final hit = traceCells(
        frame.toLocalX(x0),
        y0,
        frame.toLocalX(p.x),
        p.y,
        (cx, cy) => cx == tx && cy == ty,
      );
      if (hit != null) {
        found = FireCommand(
          tick: state.tick,
          side: side,
          slot: slot,
          angle: angle,
          power: power,
        );
        break;
      }
    }
    if (found != null && !highArc) return found;
  }
  return found ?? (throw StateError('($tx, $ty) 에 닿는 궤적이 없다'));
}
