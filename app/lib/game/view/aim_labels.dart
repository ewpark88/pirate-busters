import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart' show FontWeight, TextStyle;
import 'package:pirate_busters/app/app_theme.dart';
import 'package:pirate_busters/game/view/aim_painter.dart';

/// 조준 숫자 (설계서 §10.4 ‘각도 숫자와 힘(%)을 함께 보여준다’): 발사 지점
/// 아래 한 줄에 각도·힘 알약을 나란히. 글자는 화면이 l10n 으로 만들어 넘긴다(§14.2).
abstract final class AimLabels {
  static final TextPaint _text = TextPaint(
    style: const TextStyle(
      // Black Han Sans 에는 ‘°’ 가 없어 본문 글꼴 굵게 쓴다.
      fontFamily: AppFonts.body,
      fontWeight: FontWeight.w700,
      fontSize: 9,
      color: Color(0xFFFFFFFF),
      shadows: [
        Shadow(color: AimPainter.outline, blurRadius: 2),
        Shadow(color: AimPainter.outline, offset: Offset(0.6, 0.6)),
      ],
    ),
  );

  static final Paint _pill = Paint()..color = const Color(0xD914161C);
  static final Paint _pillEdge = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1
    ..color = const Color(0xFFC9962E);

  /// 숫자 줄 가운데: 발사 지점 아래 32px. 각도 알약과 힘 알약이 이 줄에 나란히
  /// 놓여 힘 링·점선과 겹치지 않는다.
  static Offset powerAt(Offset from) => from + const Offset(0, 32);

  /// 알약 사이 틈(px).
  static const double gap = 3;

  /// 가로 [wa]·[wp] 인 각도·힘 알약의 가운데: 줄 가운데에 둘을 붙여 놓는다.
  static (Offset, Offset) rowAt(Offset from, double wa, double wp) {
    final mid = powerAt(from);
    final left = mid.dx - (wa + gap + wp) / 2;
    return (
      Offset(left + wa / 2, mid.dy),
      Offset(left + wa + gap + wp / 2, mid.dy),
    );
  }

  static void draw(
    Canvas c,
    Offset from, {
    required String angle,
    required String power,
  }) {
    final (a, p) = rowAt(from, _width(angle), _width(power));
    _pillText(c, a, angle);
    _pillText(c, p, power);
  }

  static double _width(String text) => _text.getLineMetrics(text).size.x + 10;

  /// 어두운 알약에 금테를 두르고 가운데에 글자를 쓴다. 각도·힘이 같은 모양이다.
  static void _pillText(Canvas c, Offset at, String text) {
    final h = _text.getLineMetrics(text).size.y + 4;
    final pill = RRect.fromRectAndRadius(
      Rect.fromCenter(center: at, width: _width(text), height: h),
      Radius.circular(h / 2),
    );
    c
      ..drawRRect(pill, _pill)
      ..drawRRect(pill, _pillEdge);
    _text.render(c, text, Vector2(at.dx, at.dy), anchor: Anchor.center);
  }
}
