import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart' show FontWeight, TextStyle;
import 'package:pirate_busters/app/app_theme.dart';
import 'package:pirate_busters/game/view/aim_painter.dart';

/// 조준 숫자 (설계서 §10.4 ‘각도 숫자와 힘(%)을 함께 보여준다’): 각도 호 바깥에
/// 각도, 발사 지점 아래에 힘 알약. 글자는 화면이 l10n 으로 만들어 넘긴다(§14.2).
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

  /// 각도 글자 자리: 수평과 조준 방향의 가운데(호의 가운데) 쪽으로 호 바깥 30px.
  /// 점선(조준 방향)과 겹치지 않는다.
  static Offset angleAt(Offset from, Offset dir) {
    final horizontal = Offset(dir.dx.sign == 0 ? 1 : dir.dx.sign, 0);
    final mid = dir + horizontal;
    final len = mid.distance;
    return from + (len == 0 ? horizontal : mid / len) * 30;
  }

  /// 힘 알약 가운데: 발사 지점 아래 28px.
  static Offset powerAt(Offset from) => from + const Offset(0, 28);

  static void draw(
    Canvas c,
    Offset from,
    Offset dir, {
    required String angle,
    required String power,
  }) {
    _text.render(
      c,
      angle,
      Vector2(angleAt(from, dir).dx, angleAt(from, dir).dy),
      anchor: Anchor.center,
    );
    final at = powerAt(from);
    final size = _text.getLineMetrics(power).size;
    final pill = RRect.fromRectAndRadius(
      Rect.fromCenter(center: at, width: size.x + 10, height: size.y + 4),
      Radius.circular((size.y + 4) / 2),
    );
    c
      ..drawRRect(pill, _pill)
      ..drawRRect(pill, _pillEdge);
    _text.render(c, power, Vector2(at.dx, at.dy), anchor: Anchor.center);
  }
}
