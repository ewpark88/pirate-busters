import 'dart:math' as math;
import 'dart:ui';

/// 보스 배 위 붉은 왕관 표식 (설계서 §5.4·§13.4, ADR-096). 보스 전용 그림 없이
/// 도형으로 그린다. 판정과 무관하다.
abstract final class BossMark {
  static final Paint _glow = Paint()
    ..color = const Color(0x55E0402F)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
  static final Paint _fill = Paint()..color = const Color(0xFFD8392B);
  static final Paint _rim = Paint()
    ..color = const Color(0xFF3A1210)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3
    ..strokeJoin = StrokeJoin.round;
  static final Paint _gem = Paint()..color = const Color(0xFFFFC24A);

  /// 보스 판이면 보스 배 진영(사람이 두지 않는 쪽), 아니면 null.
  static int? sideFor({required bool isBoss, required Set<int> humanSides}) {
    if (!isBoss) return null;
    for (final side in const [0, 1]) {
      if (!humanSides.contains(side)) return side;
    }
    return null;
  }

  /// [side] 배 위에 왕관을 그리는가: 보스 진영이고 판이 아직 안 끝났다.
  static bool showsOn(int side, {required int? bossSide, required bool over}) =>
      bossSide == side && !over;

  /// 왕관 바닥 가운데가 [base] 에 오도록 너비 [width] 로 그린다.
  /// [t] 는 초 단위 시계(천천히 위아래로 떠 있는 움직임).
  static void crown(Canvas canvas, Offset base, double width, double t) {
    final w = width;
    final h = w * 0.62;
    final bob = math.sin(t * 2.2) * w * 0.05;
    final b = base.translate(0, bob);
    final left = b.dx - w / 2;
    final top = b.dy - h;
    canvas.drawCircle(b.translate(0, -h / 2), w * 0.62, _glow);
    final path = Path()
      ..moveTo(left, b.dy)
      ..lineTo(left, top + h * 0.25)
      ..lineTo(left + w * 0.25, top + h * 0.55)
      ..lineTo(b.dx, top)
      ..lineTo(left + w * 0.75, top + h * 0.55)
      ..lineTo(left + w, top + h * 0.25)
      ..lineTo(left + w, b.dy)
      ..close();
    canvas
      ..drawPath(path, _fill)
      ..drawPath(path, _rim);
    final band = Rect.fromLTRB(left, b.dy - h * 0.22, left + w, b.dy);
    canvas
      ..drawRect(band, _rim)
      ..drawCircle(Offset(b.dx, b.dy - h * 0.11), w * 0.07, _gem);
    for (final x in [left, b.dx, left + w]) {
      final tip = Offset(x, x == b.dx ? top : top + h * 0.25);
      canvas.drawCircle(tip, w * 0.07, _gem);
    }
  }
}
