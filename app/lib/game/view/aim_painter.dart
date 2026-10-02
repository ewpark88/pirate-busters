import 'dart:math' as math;
import 'dart:ui';

/// 조준 표시 (설계서 §10.4): 새총 고무줄, 각도 호, 힘 링, 멀어질수록 흐려지는 궤적
/// 점선. 점선 색은 등급을 따른다(§10.5). 그리기만 하고 값은 조준 입력에서 받는다.
abstract final class AimPainter {
  /// 각도 호와 힘 링의 반지름(월드 px).
  static const double arcRadius = 15;
  static const double ringRadius = 20;

  /// 가장 세게 당겼을 때 고무줄 길이(월드 px).
  static const double maxBand = 18;

  static const Color _rubber = Color(0xFFE8C9A0);
  static const Color _guide = Color(0xFFFFFFFF);

  static Paint _stroke(Color c, double width, double op) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..color = c.withValues(alpha: op.clamp(0, 1));

  /// 궤적 점 [i](0 ~ [last])의 불투명도: 멀어질수록 흐려진다.
  static double dotAlpha(int i, int last) =>
      last <= 0 ? 1 : 1 - .75 * (i / last).clamp(0, 1);

  /// 궤적 점선. [pts] 는 발사 지점부터 순서대로.
  static void trajectory(Canvas c, List<Offset> pts, Color color) {
    final last = pts.length - 1;
    for (var i = 0; i <= last; i++) {
      final a = dotAlpha(i, last);
      c.drawCircle(
        pts[i],
        2 + 1.5 * a,
        Paint()..color = color.withValues(alpha: a),
      );
    }
  }

  /// 조준 방향 단위 벡터(화면 좌표, 위가 −y). [angleMdeg] 는 상대 쪽 수평이 0.
  static Offset direction(int facing, int angleMdeg) {
    final rad = angleMdeg * math.pi / 180000;
    return Offset(facing * math.cos(rad), -math.sin(rad));
  }

  /// 고무줄을 당긴 끝점: 조준 방향의 반대로 [stretch](0~1)만큼.
  static Offset pulled(
    Offset from,
    int facing,
    int angleMdeg,
    double stretch,
  ) =>
      from - direction(facing, angleMdeg) * (4 + maxBand * stretch.clamp(0, 1));

  /// 발사 지점 [from] 둘레에 고무줄·각도 호·힘 링을 그린다. [power] 는 0~1.
  static void sling(
    Canvas c,
    Offset from, {
    required int facing,
    required int angleMdeg,
    required double stretch,
    required double power,
    required Color color,
  }) {
    final dir = direction(facing, angleMdeg);
    final side = Offset(-dir.dy, dir.dx) * 4;
    final tip = pulled(from, facing, angleMdeg, stretch);
    final rad = angleMdeg * math.pi / 180000;
    // 수평에서 조준 방향까지의 호. 오른쪽을 보면 반시계, 왼쪽을 보면 시계 방향.
    final start = facing > 0 ? 0.0 : math.pi;
    c
      ..drawLine(from + side, tip, _stroke(_rubber, 1.6, .95))
      ..drawLine(from - side, tip, _stroke(_rubber, 1.6, .95))
      ..drawCircle(tip, 2.2, Paint()..color = _rubber)
      ..drawLine(
        from,
        from + Offset(facing * (arcRadius + 4), 0),
        _stroke(_guide, 1, .45),
      )
      ..drawArc(
        Rect.fromCircle(center: from, radius: arcRadius),
        start,
        -facing * rad,
        false,
        _stroke(_guide, 1.4, .85),
      )
      ..drawCircle(from, ringRadius, _stroke(_guide, 2.4, .22))
      ..drawArc(
        Rect.fromCircle(center: from, radius: ringRadius),
        -math.pi / 2,
        2 * math.pi * power.clamp(0, 1),
        false,
        _stroke(color, 2.4, .95),
      );
  }
}
