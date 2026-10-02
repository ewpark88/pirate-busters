import 'dart:math' as math;
import 'dart:ui';

import 'package:pirate_busters/game/view/aim_painter.dart';

/// 조준 표시의 새총 쪽 (설계서 §10.4): 나무 갈래와 고무줄, 탄알을 담은 가죽 주머니,
/// 각도 부채꼴, 10칸 힘 링. 점선과 같은 외곽선·등급색(§10.5)으로 한 벌을
/// 이룬다. 그리기만 한다.
abstract final class AimSling {
  /// 힘 링 칸 수와 칸 사이 틈(라디안).
  static const int segments = 10;
  static const double segmentGap = .14;

  static const Color _rubber = Color(0xFFE8C9A0);
  static const Color _leather = Color(0xFF7A4B26);
  static const Color _wood = Color(0xFFA9743A);
  static const Color _white = Color(0xFFFFFFFF);
  static const Color _outline = AimPainter.outline;

  static Paint _stroke(Color c, double width, double op) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..color = c.withValues(alpha: op.clamp(0, 1));

  static Paint _fill(Color c, [double op = 1]) =>
      Paint()..color = c.withValues(alpha: op.clamp(0, 1));

  /// 힘 링 [i] 번째 칸(위에서 시계 방향)이 채워진 비율 0~1. [power] 는 0~1.
  static double segmentFill(int i, double power) =>
      (power.clamp(0, 1) * segments - i).clamp(0, 1).toDouble();

  static void draw(
    Canvas c,
    Offset from, {
    required int facing,
    required int angleMdeg,
    required double stretch,
    required double power,
    required Color color,
  }) {
    _arc(c, from, facing, angleMdeg);
    _ring(c, from, power, color);
    _band(c, from, facing, angleMdeg, stretch, color);
  }

  /// 수평에서 조준 방향까지 옅은 부채꼴과 호, 점선 수평 안내.
  static void _arc(Canvas c, Offset from, int facing, int angleMdeg) {
    const r = AimPainter.arcRadius;
    final rad = angleMdeg * math.pi / 180000;
    final start = facing > 0 ? 0.0 : math.pi;
    final sweep = -facing * rad;
    final box = Rect.fromCircle(center: from, radius: r);
    c
      ..drawArc(box, start, sweep, true, _fill(_white, .13))
      ..drawArc(box, start, sweep, false, _stroke(_outline, 3.4, .8))
      ..drawArc(box, start, sweep, false, _stroke(_white, 1.8, .95));
    // 수평 안내: 짧은 점선.
    for (var x = 2.0; x < r + 4; x += 4) {
      final a = from + Offset(facing * x, 0);
      final b = from + Offset(facing * (x + 2), 0);
      c.drawLine(a, b, _stroke(_white, 1, .5));
    }
  }

  /// 어두운 트랙 위 10칸 링. 채워진 칸은 등급색, 100% 면 바깥에 빛 테.
  static void _ring(Canvas c, Offset from, double power, Color color) {
    const r = AimPainter.ringRadius;
    final box = Rect.fromCircle(center: from, radius: r);
    c.drawCircle(from, r, _stroke(_outline, 3.6, .5));
    const seg = 2 * math.pi / segments;
    for (var i = 0; i < segments; i++) {
      final s = -math.pi / 2 + i * seg + segmentGap / 2;
      const full = seg - segmentGap;
      final f = segmentFill(i, power);
      final rest = _stroke(_white, 2, .22)..strokeCap = StrokeCap.butt;
      c.drawArc(box, s, full, false, rest);
      if (f > 0) {
        final lit = _stroke(color, 2.2, 1)..strokeCap = StrokeCap.butt;
        c.drawArc(box, s, full * f, false, lit);
      }
    }
    if (power >= 1) {
      c.drawCircle(
        from,
        r + 3.2,
        _stroke(color, 2, .45)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
      );
    }
  }

  /// 갈래 끝 두 나무 마디에서 주머니까지 고무줄. 세게 당길수록 가늘어진다.
  static void _band(
    Canvas c,
    Offset from,
    int facing,
    int angleMdeg,
    double stretch,
    Color color,
  ) {
    final dir = AimPainter.direction(facing, angleMdeg);
    final side = Offset(-dir.dy, dir.dx) * 4.5;
    final tip = AimPainter.pulled(from, facing, angleMdeg, stretch);
    final w = 2.2 - .9 * stretch.clamp(0, 1);
    for (final prong in [from + side, from - side]) {
      c
        ..drawLine(prong, tip, _stroke(_outline, w + 1.6, .75))
        ..drawLine(prong, tip, _stroke(_rubber, w, 1));
    }
    for (final prong in [from + side, from - side]) {
      c
        ..drawCircle(prong, 2.2, _fill(_outline, .85))
        ..drawCircle(prong, 1.5, _fill(_wood));
    }
    // 가죽 주머니: 조준 방향으로 돌린 둥근 사각형 안에 등급색 탄알.
    c
      ..save()
      ..translate(tip.dx, tip.dy)
      ..rotate(math.atan2(dir.dy, dir.dx));
    final pouch = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: 6, height: 8),
      const Radius.circular(2.4),
    );
    c
      ..drawRRect(pouch.inflate(.9), _fill(_outline, .85))
      ..drawRRect(pouch, _fill(_leather))
      ..drawCircle(const Offset(1, 0), 2.5, _fill(_outline, .9))
      ..drawCircle(const Offset(1, 0), 1.9, _fill(color))
      ..drawCircle(const Offset(.3, -.7), .7, _fill(_white, .85))
      ..restore();
  }
}
