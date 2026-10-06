import 'dart:ui';

import 'package:flame/components.dart';

/// 선실 칸 안쪽과 돛대 그리기. 선실 칸은 블록 재질 타일을 테두리로 남기고 그 안에
/// 안쪽 벽 타일과 바닥 널을 그려, 해적이 칸 안에 서 있는 방으로 보이게 한다
/// (설계서 §10.2, ADR-057). 그리기만 한다. 판정은 격자 그대로다.
abstract final class CabinPainter {
  /// 재질 타일이 보이는 테두리 두께(월드 px).
  static const double frame = 2;

  static final Paint _edge = Paint()
    ..color = const Color(0xCC14161C)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;

  static final Paint _floor = Paint()..color = const Color(0xFF6B4A2B);

  /// 칸 [cell] 안에서 방으로 보이는 영역.
  static Rect inner(Rect cell) => cell.deflate(frame);

  /// [cell] 칸에 안쪽 벽 [wall] 과 바닥 널을 그린다.
  static void room(Canvas canvas, Rect cell, Sprite wall) {
    final r = inner(cell);
    wall.render(
      canvas,
      position: Vector2(r.left, r.top),
      size: Vector2(r.width, r.height),
    );
    canvas
      ..drawRect(Rect.fromLTRB(r.left, r.bottom - 2, r.right, r.bottom), _floor)
      ..drawRect(r, _edge);
  }
}
