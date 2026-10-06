import 'dart:ui';

import 'package:flame/components.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/game/view/plank_join.dart';

/// 선체 마감 (설계서 §3.4 선체 틀, §10.2 배 장식): 틀의 V 자 계단을 비스듬한
/// 선체 판으로 메우고, 바깥 둘레 외곽선·용골 띠·선수 기움대·선미 키를 그린다.
/// 판정에 들지 않고(맞지 않는다), 붙은 칸이 부서지면 같이 사라진다. 그리기만 한다.
/// 격자 x 가 클수록 뱃머리다(상대 쪽, 오른쪽 배는 컴포넌트가 좌우를 뒤집는다).
abstract final class HullTrim {
  static final Paint _wood = Paint()..filterQuality = FilterQuality.medium;
  static final Paint _dark = Paint()
    ..color = const Color(0xFF2A160B)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.5
    ..strokeCap = StrokeCap.round;
  static final Paint _keel = Paint()..color = const Color(0xFF3B2414);
  static final Paint _pole = Paint()
    ..color = const Color(0xFF5A3A22)
    ..strokeWidth = 5
    ..strokeCap = StrokeCap.round;

  /// 틀 계단 하나: 줄 `y` 의 가장자리 칸 `low` 와 한 줄 위 가장자리 칸 `high`.
  /// `left` 면 선미 쪽(x 작은 쪽) 계단이다.
  static List<({int y, int low, int high, bool left})> steps(
    HullSpec hull,
    bool Function(int x, int y) filled,
  ) => [
    for (var y = 0; y < hull.height - 1; y++)
      if (hull.frameInset(y) > hull.frameInset(y + 1)) ...[
        if (filled(hull.frameInset(y), y) &&
            filled(hull.frameInset(y + 1), y + 1))
          (
            y: y,
            low: hull.frameInset(y),
            high: hull.frameInset(y + 1),
            left: true,
          ),
        if (filled(hull.width - 1 - hull.frameInset(y), y) &&
            filled(hull.width - 1 - hull.frameInset(y + 1), y + 1))
          (
            y: y,
            low: hull.width - 1 - hull.frameInset(y),
            high: hull.width - 1 - hull.frameInset(y + 1),
            left: false,
          ),
      ],
  ];

  /// 비스듬한 선체 판 [step] 의 삼각형: 아래 줄 가장자리 바닥 → 위 줄 가장자리 바닥
  /// → 아래 줄 가장자리 위.
  static Path wedge(
    ({int y, int low, int high, bool left}) step,
    Rect Function(int x, int y) cellRect,
  ) {
    final low = cellRect(step.low, step.y);
    final high = cellRect(step.high, step.y + 1);
    final lowX = step.left ? low.left : low.right;
    final highX = step.left ? high.left : high.right;
    return Path()
      ..moveTo(lowX, low.bottom)
      ..lineTo(highX, low.top)
      ..lineTo(lowX, low.top)
      ..close();
  }

  /// 선체 판·외곽선·용골 띠·기움대·키를 그린다. 타일을 다 그린 뒤 부른다.
  static void paint(
    Canvas canvas, {
    required HullSpec hull,
    required List<int> materials,
    required Sprite Function(int material, int x, int y) tileAt,
    required Rect Function(int x, int y) cellRect,
  }) {
    final width = hull.width;
    bool filled(int x, int y) =>
        x >= 0 &&
        x < width &&
        y >= 0 &&
        y < hull.height &&
        materials[y * width + x] != ShipGrid.emptyCell &&
        !BlockMaterial.values[materials[y * width + x]].rig;
    final found = steps(hull, filled);
    final hidden = <(int, int, int)>{};
    for (final s in found) {
      final path = wedge(s, cellRect);
      final low = cellRect(s.low, s.y);
      final sprite = tileAt(materials[s.y * width + s.low], s.low, s.y);
      canvas
        ..save()
        ..clipPath(path);
      final bounds = path.getBounds();
      canvas
        ..drawImageRect(sprite.image, sprite.src, bounds, _wood)
        ..restore();
      // 계단 변은 판에 덮인다: 아래 칸 옆변과 위 칸들의 바닥 변.
      hidden.add((s.low, s.y, s.left ? PlankJoin.left : PlankJoin.right));
      final from = s.left ? s.high : s.low + 1;
      final to = s.left ? s.low - 1 : s.high;
      for (var x = from; x <= to; x++) {
        hidden.add((x, s.y + 1, PlankJoin.down));
      }
      final high = cellRect(s.high, s.y + 1);
      canvas.drawLine(
        Offset(s.left ? low.left : low.right, low.bottom),
        Offset(s.left ? high.left : high.right, low.top),
        _dark,
      );
    }
    PlankJoin.outline(canvas, materials, width, cellRect, hidden: hidden);
    _keelBand(canvas, filled, width, cellRect);
    _bowsprit(canvas, filled, hull, cellRect);
    _rudder(canvas, filled, hull, cellRect);
  }

  /// 용골 줄 바닥의 짙은 띠.
  static void _keelBand(
    Canvas canvas,
    bool Function(int x, int y) filled,
    int width,
    Rect Function(int x, int y) cellRect,
  ) {
    for (var x = 0; x < width; x++) {
      if (!filled(x, 0)) continue;
      final r = cellRect(x, 0);
      canvas.drawRect(
        Rect.fromLTRB(r.left, r.bottom - 5, r.right, r.bottom),
        _keel,
      );
    }
  }

  /// 뱃머리 맨 앞 칸 가장 높은 블록에서 앞으로 비스듬히 뻗는 기움대(bowsprit).
  static void _bowsprit(
    Canvas canvas,
    bool Function(int x, int y) filled,
    HullSpec hull,
    Rect Function(int x, int y) cellRect,
  ) {
    final x = hull.width - 1;
    for (var y = hull.height - 1; y >= 0; y--) {
      if (!filled(x, y)) continue;
      final r = cellRect(x, y);
      final from = Offset(r.right - 4, r.top + r.height * 0.35);
      canvas.drawLine(
        from,
        from + Offset(r.width * 1.3, -r.height * 0.75),
        _pole,
      );
      return;
    }
  }

  /// 선미 맨 뒤 칸 가장 낮은 블록 아래로 늘어진 키.
  static void _rudder(
    Canvas canvas,
    bool Function(int x, int y) filled,
    HullSpec hull,
    Rect Function(int x, int y) cellRect,
  ) {
    final x = hull.frameInset(0);
    if (!filled(x, 0)) return;
    final r = cellRect(x, 0);
    final rudder = Path()
      ..moveTo(r.left + 2, r.top + 6)
      ..lineTo(r.left - r.width * 0.32, r.top + 10)
      ..lineTo(r.left - r.width * 0.26, r.bottom + r.height * 0.18)
      ..lineTo(r.left + 4, r.bottom + 2)
      ..close();
    canvas
      ..drawPath(rudder, Paint()..color = const Color(0xFF6B4528))
      ..drawPath(rudder, _dark);
  }
}
