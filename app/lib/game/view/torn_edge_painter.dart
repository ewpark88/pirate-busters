import 'dart:ui';

import 'package:pirate_busters/game/view/damage_style.dart';

/// 부서진 칸과 맞닿은 남은 블록의 변을 찢긴 판자·말린 철판으로 그리고, 부서진 칸
/// 아래 블록 윗면에 파편을 얹는다 (설계서 §10.2, 에셋 v0.26, ADR-052·070).
///
/// `o` 는 남은 블록 칸의 왼쪽 위(단위 공간), `side` 는 부서진 칸이 있는 변
/// (`l`·`r`·`t`·`b`)이다. 판정은 격자 그대로이고 모양은 칸 번호 해시로 정해진다.
abstract final class TornEdgePainter {
  static const double _c = DamageStyle.unit;

  /// 나무 블록의 찢긴 변. 좌우 변은 판자 3장이 장마다 다르게 부러지고(안으로
  /// 패이거나 밖으로 튀어나옴), 위아래 변은 판자 한 장이 가로로 쪼개진다.
  /// [holeWet] 이면 부서진 칸이 흘수선 아래라 패인 곳이 물 찬 색이다.
  static void wood(
    Canvas canvas,
    Offset o,
    int c,
    int r,
    String side,
    WoodPalette w, {
    required bool holeWet,
  }) {
    double k(int n) => DamageStyle.rnd(c, r, n);
    final dark = DamageStyle.fill(
      holeWet ? DamageStyle.wet : DamageStyle.interior,
    );
    final inner = DamageStyle.stroke(w.inner, 1.1);
    final edge = DamageStyle.stroke(DamageStyle.outline, .9);
    if (side == 'l' || side == 'r') {
      final right = side == 'r';
      final wall = right ? o.dx + _c : o.dx;
      final dir = right ? 1.0 : -1.0;
      for (var i = 0; i < 3; i++) {
        final (y0, y1) = DamageStyle.planks[i];
        final kk = k(50 + i + (right ? 0 : 7));
        final bite = kk < .55 ? 2 + kk * 18 : 0.0; // 칸 안으로 패인 깊이
        final stick = kk < .55 ? 0.0 : 3 + (kk - .55) * 22; // 튀어나온 길이
        final t1 = (y0 + y1) / 2 + (k(60 + i) - .5) * 4;
        final ex = wall + dir * (stick - bite);
        final sl = (k((right ? 70 : 72) + i) - .5) * 7;
        final tip = [
          Offset(ex + sl, o.dy + y0 + .5),
          Offset(ex + 2.2 * (sl < 0 ? 1 : -1), o.dy + t1),
          Offset(ex - sl * .6, o.dy + y1 - .5),
        ];
        if (bite > 0) {
          canvas.drawPath(
            DamageStyle.poly([
              Offset(wall, o.dy + y0),
              Offset(wall, o.dy + y1),
              ...tip.reversed,
            ]),
            dark,
          );
        } else {
          final inset = wall - dir * .5;
          final plank = DamageStyle.poly([
            Offset(inset, o.dy + y0 + .4),
            Offset(inset, o.dy + y1 - .4),
            ...tip.reversed,
          ]);
          canvas
            ..drawPath(plank, DamageStyle.fill(w.base))
            ..drawPath(plank, DamageStyle.stroke(DamageStyle.outline, 1));
        }
        final sx = tip[1].dx;
        canvas
          ..drawPath(DamageStyle.poly(tip, close: false), inner)
          ..drawPath(
            DamageStyle.poly([
              for (final p in tip) p.translate(dir * .9, 0),
            ], close: false),
            edge,
          )
          ..drawLine(
            Offset(sx - dir * 2, o.dy + t1 - 1),
            Offset(sx - dir * 2 + dir * (4 + kk * 5), o.dy + t1 - 2 - kk * 2),
            DamageStyle.stroke(w.fresh, .9),
          );
      }
      return;
    }
    // 위·아래: 맞닿은 판자 한 장이 결 방향(가로)으로 길게 쪼개진다.
    final top = side == 't';
    final edgeY = top ? o.dy : o.dy + _c;
    final off = top ? 1.0 : -1.0;
    final jag = [
      for (var i = 0; i <= 5; i++)
        Offset(
          o.dx + i / 5 * _c,
          edgeY +
              off * (1.5 + k(80 + i + (top ? 0 : 20)) * (i.isOdd ? 5 : 2.5)),
        ),
    ];
    canvas
      ..drawPath(
        DamageStyle.poly([
          Offset(o.dx, edgeY),
          Offset(o.dx + _c, edgeY),
          ...jag.reversed,
        ]),
        dark,
      )
      ..drawPath(DamageStyle.poly(jag, close: false), inner)
      ..drawPath(
        DamageStyle.poly([
          for (final p in jag) p.translate(0, off),
        ], close: false),
        edge,
      );
    final spike = DamageStyle.stroke(w.fresh, 1);
    for (var i = 0; i < 2; i++) {
      final from = Offset(o.dx + 5 + k(90 + i) * 20, edgeY + off * 2 + off * 4);
      canvas.drawLine(
        from,
        from.translate(6 + k(92 + i) * 6, -off * (3 + k(94 + i) * 3)),
        spike,
      );
    }
  }

  /// 철판 블록의 찢긴 변: 얕은 패임, 바깥으로 말린 철판 조각, 달궈진 주황 선.
  static void iron(
    Canvas canvas,
    Offset o,
    int c,
    int r,
    String side, {
    required bool holeWet,
  }) {
    final k = DamageStyle.rnd(c, r, 101);
    final dark = DamageStyle.fill(
      holeWet ? DamageStyle.wet : DamageStyle.interior,
    );
    final curlFill = DamageStyle.fill(DamageStyle.ironHi);
    final curlEdge = DamageStyle.stroke(DamageStyle.outline, 1.1);
    if (side == 'l' || side == 'r') {
      final e = side == 'r' ? o.dx + _c : o.dx;
      final d = side == 'r' ? -1.0 : 1.0;
      final y0 = o.dy + 4 + k * 8;
      final y1 = o.dy + 20 + k * 6;
      final curl = Path()
        ..moveTo(e, y0 - 3)
        ..relativeQuadraticBezierTo(-d * 7, 3, -d * 6, 9)
        ..relativeQuadraticBezierTo(d * 2, -4, d * 6, -5)
        ..close();
      canvas
        ..drawPath(
          DamageStyle.poly([
            Offset(e, o.dy),
            Offset(e + d * (2 + k * 3), y0),
            Offset(e + d, (y0 + y1) / 2),
            Offset(e + d * (4 + k * 2), y1),
            Offset(e, o.dy + _c),
          ]),
          dark,
        )
        ..drawPath(curl, curlFill)
        ..drawPath(curl, curlEdge)
        ..drawLine(
          Offset(e + d, y0),
          Offset(e + d, y1),
          DamageStyle.stroke(DamageStyle.ironHot, 1.2, .75),
        );
      return;
    }
    final e = side == 't' ? o.dy : o.dy + _c;
    final d = side == 't' ? 1.0 : -1.0;
    final curl = Path()
      ..moveTo(o.dx + 10, e)
      ..relativeQuadraticBezierTo(3, -d * 8, 9, -d * 7)
      ..relativeQuadraticBezierTo(-4, d * 3, -5, d * 7)
      ..close();
    canvas
      ..drawPath(
        DamageStyle.poly([
          Offset(o.dx, e),
          Offset(o.dx + 8, e + d * (2 + k * 4)),
          Offset(o.dx + 16, e + d * 1.5),
          Offset(o.dx + 24, e + d * (3 + k * 3)),
          Offset(o.dx + _c, e),
        ]),
        dark,
      )
      ..drawPath(curl, curlFill)
      ..drawPath(curl, curlEdge);
  }

  /// 파편: 블록 칸 [o] 의 윗면에 부러진 판자 조각 2개.
  static void debris(Canvas canvas, Offset o, int c, int r, WoodPalette w) {
    final a = DamageStyle.rnd(c, r, 190);
    final b = DamageStyle.rnd(c, r, 191);
    final len = 9 + b * 5;
    final at = Offset(o.dx + 4 + a * 10, o.dy);
    final outline = DamageStyle.stroke(DamageStyle.outline, .9);
    canvas
      ..save()
      ..translate(at.dx, at.dy);
    DamageStyle.rotated(canvas, Offset.zero, -8 + a * 16, () {
      final plank = Rect.fromLTWH(0, -3.5, len, 3.5);
      canvas
        ..drawRect(plank, DamageStyle.fill(w.base))
        ..drawRect(plank, outline)
        ..drawPath(
          Path()
            ..moveTo(len, -3.5)
            ..relativeLineTo(2, 1.2)
            ..relativeLineTo(-1.5, 1)
            ..relativeLineTo(1.5, 1.3),
          DamageStyle.stroke(w.fresh, .8),
        );
    });
    canvas.restore();
    DamageStyle.rotated(canvas, Offset(o.dx + 21 + b * 6, o.dy), 20 * a, () {
      final chip = Rect.fromLTWH(o.dx + 19 + b * 6, o.dy - 2.2, 4, 2.2);
      canvas
        ..drawRect(chip, DamageStyle.fill(w.fresh))
        ..drawRect(chip, DamageStyle.stroke(DamageStyle.outline, .6));
    });
  }
}
