// art/pb_v0.22_main/tools/weapons_fx.js(baseTrail)·tools/rarity_fx.js(trail) 에서
// 가져와 고쳤다 (docs/ASSETS.md). 크기는 앱의 발사체(32×24)에 맞춰 절반이다.
import 'dart:math' as math;
import 'dart:ui';

import 'package:pirate_busters/game/anim/rarity_fx.dart';
import 'package:pirate_busters/game/view/rarity_painter.dart';

/// 발사체 꼬리 (설계서 §10.1 고유 꼬리, §10.5 등급 꼬리). 그리기만 한다.
///
/// 점 목록은 오래된 것부터 최신 순이다. 고유 꼬리를 먼저 그리고 등급 꼬리를 겹친다.
abstract final class TrailPainter {
  static Paint _fill(Color c, double op) =>
      Paint()..color = c.withValues(alpha: op.clamp(0, 1));

  static Paint _stroke(Color c, double width, double op) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..color = c.withValues(alpha: op.clamp(0, 1));

  /// 해적 고유 꼬리: smoke | fire | lava | spark | bubble | water | wind | none.
  static void base(
    Canvas c,
    List<Offset> pts,
    String trail,
    double sec, {
    Color? color,
  }) {
    final n = pts.length;
    if (n < 2 || trail == 'none') return;
    for (var i = 0; i < n; i++) {
      final p = pts[i];
      final u = i / n;
      switch (trail) {
        case 'smoke':
          if (i.isOdd) continue;
          c.drawCircle(p, 1 + 2 * u, _fill(const Color(0xFF8A848E), .45 * u));
        case 'fire':
          c.drawCircle(
            p.translate(0, -(1 - u)),
            1 + 2.5 * u,
            _fill(Color(i.isOdd ? 0xFFFFB627 : 0xFFFF5A2A), .8 * u),
          );
        case 'lava':
          if (i.isEven) {
            c.drawCircle(
              p.translate(0, -3 * (1 - u)),
              1.5 + 2.5 * (1 - u),
              _fill(const Color(0xFF3A3440), .55 * u),
            );
          } else {
            c.drawCircle(p, .75 + 1.25 * u, _fill(const Color(0xFFFF6A2A), u));
          }
        case 'spark':
          if (i == 0) continue;
          c.drawLine(
            pts[i - 1],
            p,
            _stroke(color ?? const Color(0xFFFFD24A), .5 + 1.5 * u, .9 * u),
          );
        case 'bubble':
          if (i.isOdd) continue;
          c.drawCircle(
            p.translate(math.sin(i * 2 + sec * 5) * 1.5, -1.5),
            .75 + 1.25 * u,
            _stroke(const Color(0xFFDFF3FF), .7, .9 * u),
          );
        case 'water':
          c.drawCircle(
            p.translate(0, math.sin(i * 1.3)),
            .6 + 1.1 * u,
            _fill(const Color(0xFFBFE9FF), .85 * u),
          );
        case 'wind':
          if (i % 3 != 0) continue;
          c.drawPath(
            Path()
              ..moveTo(p.dx - 4, p.dy - 2.5)
              ..relativeQuadraticBezierTo(4, -2, 7, 1),
            _stroke(const Color(0xFFE8F4FF), .9, .8 * u),
          );
      }
    }
  }

  /// 등급 꼬리. 일반 등급은 고유 꼬리만 보인다. [water] 는 물속 구간(등급색 거품).
  static void tier(
    Canvas c,
    List<Offset> pts,
    RarityTier t,
    double sec, {
    bool water = false,
  }) {
    final n = pts.length;
    final color = t.color;
    final hi = t.hi;
    if (n < 2 || color == null || hi == null) return;
    if (water) {
      for (var j = 0; j < n; j += 2) {
        final w = j / n;
        c.drawCircle(
          pts[j].translate(
            math.sin(j * 2.1 + sec * 6) * 1.5,
            -2 - (1 - w) * 5,
          ),
          .75 + 1.5 * w,
          _stroke(j % 4 != 0 ? hi : color, .9, .9 * w),
        );
      }
      return;
    }
    switch (t.trail) {
      case 'dots':
        for (var i = 0; i < n; i++) {
          final u = i / n;
          c.drawCircle(
            pts[i],
            .75 + 1.75 * u,
            _fill(i.isOdd ? hi : color, .9 * u),
          );
        }
      case 'prism':
        for (var i = 1; i < n; i++) {
          c.drawLine(
            pts[i - 1],
            pts[i],
            _stroke(
              RarityPainter.hue(i * 26 + sec * 240),
              1.5 + 2.5 * i / n,
              .9 * i / n,
            ),
          );
        }
        _stars(c, pts, color, hi, sec);
      case 'ribbon' || 'ribbon+stars':
        final path = Path()..moveTo(pts[0].dx, pts[0].dy);
        for (final p in pts.skip(1)) {
          path.lineTo(p.dx, p.dy);
        }
        c
          ..drawPath(path, _stroke(color, 5, .35))
          ..drawPath(path, _stroke(hi, 2, .9));
        if (t.trail == 'ribbon+stars') _stars(c, pts, color, hi, sec);
    }
  }

  static void _stars(
    Canvas c,
    List<Offset> pts,
    Color color,
    Color hi,
    double sec,
  ) {
    final n = pts.length;
    for (var i = 0; i < n; i += 3) {
      final u = i / n;
      RarityPainter.spark(
        c,
        pts[i].translate(math.sin(i * 1.7) * 3, math.cos(i * 1.3) * 3),
        1.5 + 2 * u,
        i.isOdd ? hi : color,
        u,
        sec * 200 + i * 30,
      );
    }
  }
}
