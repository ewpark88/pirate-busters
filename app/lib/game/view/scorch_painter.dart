import 'dart:ui';

import 'package:flame/components.dart';
import 'package:pirate_busters/game/sprites.dart';
import 'package:pirate_busters/game/view/explosion_fx.dart';

/// 그을음 자국 (설계서 §10.4 ‘맞은 칸에 그을음 자국이 남는다’). 블록이 남아 있는
/// 동안 타일 위에 겹친다. 모양(돌림)은 칸 번호로 정해져 리플레이에서도 같다.
abstract final class ScorchPainter {
  static final Paint _paint = Paint()..color = const Color(0x9EFFFFFF);

  /// 칸 [cell] 위에 칸 번호 [index] 로 고른 방향의 그을음을 그린다.
  static void draw(Canvas canvas, BattleSprites sprites, Rect cell, int index) {
    final size = cell.width * 1.25;
    canvas
      ..save()
      ..translate(cell.center.dx, cell.center.dy)
      ..rotate((index * 2.39996) % 6.2832);
    sprites
        .get(ExplosionFx.scorch)
        .render(
          canvas,
          size: Vector2(size, size * 208 / 240),
          anchor: Anchor.center,
          overridePaint: _paint,
        );
    canvas.restore();
  }
}
