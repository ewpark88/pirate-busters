import 'dart:math' as math;
import 'dart:ui';

/// 조준 표시 (설계서 §10.4): 새총 고무줄, 각도 호, 힘 링, 고른 간격의 테두리 점이
/// 발사 방향으로 흐르며 멀어질수록 흐려지는 궤적 점선. 점선 색은 등급을 따른다
/// (§10.5). 그리기만 하고 값은 조준 입력에서 받는다.
abstract final class AimPainter {
  /// 각도 호와 힘 링의 반지름(월드 px).
  static const double arcRadius = 17;
  static const double ringRadius = 20;

  /// 가장 세게 당겼을 때 고무줄 길이(월드 px).
  static const double maxBand = 18;

  /// 궤적 점 간격(월드 px, 호 길이 기준)과 흐르는 속도(px/초).
  static const double dotStep = 7;
  static const double flowSpeed = 10;

  /// 점선은 힘 링 바깥에서 시작한다.
  static const double dotSkip = ringRadius + 3;

  static const Color _rubber = Color(0xFFE8C9A0);
  static const Color _guide = Color(0xFFFFFFFF);

  /// 외곽선 색 (설계서 §10.1).
  static const Color outline = Color(0xFF14161C);

  static Paint _stroke(Color c, double width, double op) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..color = c.withValues(alpha: op.clamp(0, 1));

  /// 궤적 점 [i](0 ~ [last])의 불투명도: 앞 1 에서 끝 0.45 로 흐려진다. 점이 호 길이로
  /// 고르게 찍히므로 번호 비율이 거리 비율이다.
  static double dotAlpha(int i, int last) =>
      last <= 0 ? 1 : 1 - .55 * (i / last).clamp(0, 1);

  /// 폴리라인 [path] 위에서 호 길이 `skip + phase + k·step` 자리의 점을 찍는다.
  /// [phase] 는 흐름 값(0 ≤ phase < step).
  static List<Offset> resample(
    List<Offset> path,
    double step, {
    double skip = 0,
    double phase = 0,
  }) {
    final out = <Offset>[];
    var next = skip + phase;
    var walked = 0.0;
    for (var i = 1; i < path.length; i++) {
      final a = path[i - 1];
      final seg = path[i] - a;
      final len = seg.distance;
      while (len > 0 && next <= walked + len) {
        out.add(a + seg * ((next - walked) / len));
        next += step;
      }
      walked += len;
    }
    return out;
  }

  /// 궤적 점선. [pts] 는 발사 쪽부터 순서대로. 점마다 외곽선 테를 두르고 앞에서
  /// 끝으로 작아지며 흐려진다. 맨 앞 점은 [fadeIn](0~1)만큼만 보여 흐를 때 깜빡이지
  /// 않는다.
  static void trajectory(
    Canvas c,
    List<Offset> pts,
    Color color, {
    double fadeIn = 1,
  }) {
    final last = pts.length - 1;
    for (var i = 0; i <= last; i++) {
      final a = dotAlpha(i, last) * (i == 0 ? fadeIn.clamp(0, 1) : 1);
      final t = last <= 0 ? 0 : i / last;
      final r = 3.2 - 1.4 * t;
      c
        ..drawCircle(
          pts[i],
          r + 1.2,
          Paint()..color = outline.withValues(alpha: a),
        )
        ..drawCircle(pts[i], r, Paint()..color = color.withValues(alpha: a));
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
    final arc = Rect.fromCircle(center: from, radius: arcRadius);
    final ring = Rect.fromCircle(center: from, radius: ringRadius);
    final sweep = 2 * math.pi * power.clamp(0, 1);
    c
      ..drawLine(from + side, tip, _stroke(_rubber, 1.6, .95))
      ..drawLine(from - side, tip, _stroke(_rubber, 1.6, .95))
      ..drawCircle(tip, 2.2, Paint()..color = _rubber)
      ..drawLine(
        from,
        from + Offset(facing * (arcRadius + 4), 0),
        _stroke(_guide, 1, .45),
      )
      // 각도 호와 힘 링은 외곽선을 한 겹 깔아 밝은 하늘에서도 보이게 한다.
      ..drawArc(arc, start, -facing * rad, false, _stroke(outline, 3.6, .8))
      ..drawArc(arc, start, -facing * rad, false, _stroke(_guide, 2, .95))
      ..drawCircle(from, ringRadius, _stroke(outline, 4, .35))
      ..drawCircle(from, ringRadius, _stroke(_guide, 2.4, .35))
      ..drawArc(ring, -math.pi / 2, sweep, false, _stroke(outline, 4, .8))
      ..drawArc(ring, -math.pi / 2, sweep, false, _stroke(color, 2.4, .95));
  }
}
