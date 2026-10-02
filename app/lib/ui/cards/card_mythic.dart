import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// 신화 카드의 움직임 (설계서 §10.5): 오로라 띠 세 줄이 좌우로 흐르고(6초 왕복),
/// 삼지창 뒤 점선 후광이 12초에 한 바퀴 돈다. 그림이 아니라 도형으로 그린다.
/// 좌표는 카드 캔버스(252×358), 해적과 앞면 그림보다 뒤에 놓는다.
class MythicMotion extends StatelessWidget {
  const MythicMotion(this.clock, {super.key});

  /// 공용 시계(초). 없으면 멈춘 그림이다.
  final ValueListenable<double>? clock;

  @override
  Widget build(BuildContext context) {
    final clock = this.clock;
    return Positioned.fill(
      child: IgnorePointer(
        child: clock == null
            ? const CustomPaint(painter: MythicPainter(0))
            : ValueListenableBuilder<double>(
                valueListenable: clock,
                builder: (context, t, _) =>
                    CustomPaint(painter: MythicPainter(t)),
              ),
      ),
    );
  }
}

class MythicPainter extends CustomPainter {
  const MythicPainter(this.seconds);

  final double seconds;

  /// 오로라가 좌우로 흐르는 폭(px)과 왕복 시간(초).
  static const double auroraShift = 24;
  static const double auroraPeriod = 6;

  /// 후광이 한 바퀴 도는 시간(초).
  static const double haloPeriod = 12;

  /// 오로라가 보이는 창(카드 캔버스 좌표): 해적 창의 위쪽.
  static const Rect _window = Rect.fromLTWH(18, 24, 216, 120);

  /// 후광 중심: 카드 위쪽 가운데의 삼지창 문장.
  static const Offset haloCenter = Offset(126, 14);
  static const double haloRadius = 19;

  static const List<Color> _bands = [
    Color(0xFF7AF0FF),
    Color(0xFFFF9AE8),
    Color(0xFF9AFFC0),
  ];

  /// 시각 [t] 의 오로라 가로 이동량(px): −[auroraShift] ~ +[auroraShift].
  static double shiftAt(double t) =>
      auroraShift * math.sin(t / auroraPeriod * 2 * math.pi);

  /// 시각 [t] 의 후광 회전각(라디안).
  static double haloAngleAt(double t) => t / haloPeriod * 2 * math.pi;

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..save()
      ..clipRRect(RRect.fromRectAndRadius(_window, const Radius.circular(9)));
    final shift = shiftAt(seconds);
    for (final (i, color) in _bands.indexed) {
      // 띠마다 높이와 흐르는 방향을 달리해 겹쳐 흐르게 한다.
      final y = _window.top + 26 + i * 26;
      final dx = shift * (i.isEven ? 1 : -1);
      final path = Path()..moveTo(_window.left - 40 + dx, y);
      for (var x = -40.0; x <= _window.width + 40; x += 36) {
        path
          ..relativeQuadraticBezierTo(9, -12, 18, 0)
          ..relativeQuadraticBezierTo(9, 12, 18, 0);
      }
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 9
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4)
          ..color = color.withValues(alpha: .3),
      );
    }
    canvas.restore();
    // 삼지창 뒤 점선 후광.
    final angle = haloAngleAt(seconds);
    final dot = Paint()..color = const Color(0xCCBFF8FF);
    for (var i = 0; i < 16; i++) {
      final a = angle + i / 16 * 2 * math.pi;
      canvas.drawCircle(
        haloCenter + Offset(math.cos(a), math.sin(a)) * haloRadius,
        1.6,
        dot,
      );
    }
  }

  @override
  bool shouldRepaint(MythicPainter old) => old.seconds != seconds;
}
