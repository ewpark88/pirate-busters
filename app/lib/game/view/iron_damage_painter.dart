import 'dart:math' as math;
import 'dart:ui';

import 'package:pirate_busters/game/view/damage_style.dart';

/// 철판 블록의 금·구멍 (설계서 §10.2, 에셋 v0.26 피해 표현 v3, ADR-070).
/// `o` 는 칸 왼쪽 위(단위 공간), (c, r) 은 칸 번호다.
abstract final class IronDamagePainter {
  /// 철판 금: 움푹 팬 자국 + 아래쪽 반사선 + 빠진 리벳.
  static void crack(Canvas canvas, Offset o, int c, int r) {
    final ctr =
        o +
        Offset(
          10 + DamageStyle.rnd(c, r, 130) * 12,
          10 + DamageStyle.rnd(c, r, 131) * 12,
        );
    DamageStyle.radialEllipse(
      canvas,
      ctr,
      9,
      7,
      [
        const Color(0xBF20262C),
        DamageStyle.ironDark.withValues(alpha: .35),
        DamageStyle.ironDark.withValues(alpha: 0),
      ],
      [0, .7, 1],
    );
    canvas
      ..drawPath(
        Path()
          ..moveTo(ctr.dx - 7, ctr.dy + 4)
          ..relativeQuadraticBezierTo(7, 5, 14, 0),
        DamageStyle.stroke(DamageStyle.ironHi, 1.2, .8),
      )
      ..drawCircle(
        o + const Offset(27, 27),
        1.9,
        DamageStyle.fill(const Color(0xFF0B0D10)),
      )
      ..drawCircle(
        o + const Offset(29.5, 30.5),
        1.4,
        DamageStyle.fill(DamageStyle.ironHi),
      )
      ..drawCircle(
        o + const Offset(29.5, 30.5),
        1.4,
        DamageStyle.stroke(DamageStyle.outline, .5),
      );
  }

  /// 철판 구멍: 바깥으로 젖혀진 꽃잎 6장, 달궈진 주황 테두리와 빛.
  static void hole(
    Canvas canvas,
    Offset o,
    int c,
    int r, {
    required bool wet,
  }) {
    double k(int n) => DamageStyle.rnd(c, r, n);
    final ctr = o + Offset(16 + (k(170) - .5) * 6, 16 + (k(171) - .5) * 6);
    const n = 6;
    Offset around(double an, double d) =>
        ctr + Offset(math.cos(an) * d, math.sin(an) * d);
    final core = [
      for (var i = 0; i < n; i++) around(i / n * 2 * math.pi + k(172), 5.5),
    ];
    canvas.drawCircle(ctr, 10, DamageStyle.fill(const Color(0xFFFF6A2A), .25));
    final edge = DamageStyle.stroke(DamageStyle.outline, 1);
    for (var i = 0; i < n; i++) {
      final tip = around(
        (i + .5) / n * 2 * math.pi + k(172),
        10 + k(175 + i) * 3,
      );
      final petal = DamageStyle.poly([core[i], tip, core[(i + 1) % n]]);
      canvas
        ..drawPath(
          petal,
          DamageStyle.fill(i.isOdd ? DamageStyle.ironHi : DamageStyle.ironBase),
        )
        ..drawPath(petal, edge);
    }
    final hole = DamageStyle.poly(core);
    canvas
      ..drawPath(
        hole,
        DamageStyle.fill(wet ? DamageStyle.wet : DamageStyle.interior),
      )
      ..drawPath(hole, DamageStyle.stroke(DamageStyle.ironHot, 1.3));
  }
}
