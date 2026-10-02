import 'dart:ui';

import 'package:pirate_busters/game/view/damage_style.dart';

/// 부서진 칸의 배 속과 나무 금·구멍 칸의 손상을 그린다(철판은 `IronDamagePainter`) (설계서 §10.2, 에셋 v0.26
/// 피해 표현 v3, ADR-070). `o` 는 칸 왼쪽 위(단위 공간), (c, r) 은 칸 번호이고
/// 모양은 [DamageStyle.rnd] 로 정해져 리플레이에서도 같다.
abstract final class DamagePainter {
  static const double _c = DamageStyle.unit;

  /// 변 이름 → 그 변에서 반대쪽으로 가는 그라데이션 (x1, y1, x2, y2).
  static const Map<String, (double, double, double, double)> _fromSide = {
    'l': (0, 0, 1, 0),
    'r': (1, 0, 0, 0),
    't': (0, 0, 0, 1),
    'b': (0, 1, 0, 0),
  };

  /// 부서진 칸 안쪽(배 속). [sides] 는 블록이 남은 이웃 변, [openSide] 는 설계도
  /// 바깥(하늘)과 맞닿은 변. 흘수선 아래([wet])는 물이 찬 안쪽이다.
  static void interior(
    Canvas canvas,
    Offset o,
    int c,
    int r, {
    required bool wet,
    required List<String> sides,
    String? openSide,
  }) {
    final a = wet ? DamageStyle.wet : DamageStyle.interior;
    final b = wet ? DamageStyle.wetBeam : DamageStyle.interiorBeam;
    final cell = o & const Size(_c, _c);
    void fade(String side, double mid, double midAlpha) {
      final g = _fromSide[side]!;
      canvas.drawRect(
        cell,
        Paint()
          ..shader = Gradient.linear(
            o + Offset(g.$1 * _c, g.$2 * _c),
            o + Offset(g.$3 * _c, g.$4 * _c),
            [a, a.withValues(alpha: midAlpha), a.withValues(alpha: 0)],
            [0, mid, 1],
          ),
      );
    }

    if (openSide != null && sides.isNotEmpty) {
      // 하늘 쪽으로 옅어진다: 열린 변의 반대편에서 시작.
      fade(_opposite(openSide), .55, .8);
      return;
    }
    if (sides.length == 1) {
      fade(sides.first, .5, .85);
      return;
    }
    canvas.drawRect(cell, DamageStyle.fill(a));
    // 안쪽 벽 판자(세로)와 들보(가로) — 아주 어둡게.
    final wall = DamageStyle.stroke(b, 1.2, .8);
    for (final xx in const [6.0, 17.0, 27.0]) {
      canvas.drawLine(o + Offset(xx, 0), o + Offset(xx, _c), wall);
    }
    if (DamageStyle.rnd(c, r, 9) > .45) {
      final by = 13 + DamageStyle.rnd(c, r, 10) * 6;
      canvas
        ..drawRect(Rect.fromLTWH(o.dx, o.dy + by, _c, 4), DamageStyle.fill(b))
        ..drawLine(
          o + Offset(0, by),
          o + Offset(_c, by),
          DamageStyle.stroke(const Color(0xFF4A2A16), .8, .6),
        );
    }
    if (!wet) return;
    canvas.drawLine(
      o + const Offset(0, 3),
      o + const Offset(_c, 3),
      DamageStyle.stroke(const Color(0xFF4AA0A8), 1, .5),
    );
    final bubble = DamageStyle.stroke(const Color(0xFF8AD0D8), .6, .7);
    for (var i = 0; i < 3; i++) {
      canvas.drawCircle(
        o +
            Offset(
              4 + DamageStyle.rnd(c, r, 20 + i) * 24,
              8 + DamageStyle.rnd(c, r, 30 + i) * 20,
            ),
        .8 + DamageStyle.rnd(c, r, 40 + i) * 1.2,
        bubble,
      );
    }
  }

  static String _opposite(String side) =>
      const {'l': 'r', 'r': 'l', 't': 'b', 'b': 't'}[side]!;

  /// 나무 금: 손상 이웃 변([entry], 없으면 해시)에서 판자 결을 따라 가는 쐐기.
  static void crackWood(
    Canvas canvas,
    Offset o,
    int c,
    int r,
    WoodPalette w,
    String? entry,
  ) {
    double k(int n) => DamageStyle.rnd(c, r, n);
    final pi = k(110) < .6 ? 1 : (k(111) < .5 ? 0 : 2);
    final (y0, y1) = DamageStyle.planks[pi];
    final ym = (y0 + y1) / 2 + (k(112) - .5) * 3;
    final pts = <Offset>[];
    if (entry == null || entry == 'l' || entry == 'r') {
      final sgn = entry == 'r' ? -1 : 1;
      final sx = sgn == 1 ? 0.0 : _c;
      final len = 18 + k(113) * 10;
      final sag = pi < 2 && k(119) > .5;
      pts.add(Offset(sx, ym));
      for (var i = 1; i < 6; i++) {
        final u = i / 5;
        pts.add(
          Offset(
            sx + sgn * len * u,
            ym + (k(114 + i) - .5) * 3.2 + (sag ? 2.5 * u : 0),
          ),
        );
      }
    } else {
      final sgn = entry == 't' ? 1 : -1;
      final sy = sgn == 1 ? 0.0 : _c;
      final sx = 8 + k(120) * 16;
      final dir = k(121) > .5 ? 1 : -1;
      pts.addAll([
        Offset(sx, sy),
        Offset(sx + 2, sy + sgn * 5),
        Offset(sx - 1, sy + sgn * 9),
        for (var i = 1; i < 4; i++)
          Offset(sx + i * 4 * dir, sy + sgn * (10 + i * 1.2)),
      ]);
    }
    final abs = [for (final p in pts) o + p];
    final fill = DamageStyle.fill(DamageStyle.crack);
    final b = abs[2];
    canvas
      ..drawPath(DamageStyle.taper(abs, 3.2, .3), fill)
      ..drawPath(
        DamageStyle.poly([
          for (final p in abs.take(abs.length - 1)) p.translate(0, 1.6),
        ], close: false),
        DamageStyle.stroke(w.fresh, .8, .55),
      )
      ..drawPath(
        DamageStyle.taper([b, b.translate(4, -3), b.translate(7, -4)], 1.6, .2),
        fill,
      );
  }

  /// 나무 구멍: 가운데 판자가 결 방향으로 뜯기고 판자 조각이 매달린다.
  static void holeWood(
    Canvas canvas,
    Offset o,
    int c,
    int r,
    WoodPalette w, {
    required bool wet,
  }) {
    double k(int n) => DamageStyle.rnd(c, r, n);
    final (y0, y1) = DamageStyle.planks[1];
    final mid = (y0 + y1) / 2;
    final l = 4 + k(140) * 6;
    final rr = 26 - k(141) * 6;
    final top = [
      for (var i = 0; i < 7; i++)
        Offset(l + i * (rr - l) / 6, y0 - k(142 + i) * (i.isOdd ? 5 : 2)),
    ];
    final bot = [
      for (var i = 0; i < 7; i++)
        Offset(l + i * (rr - l) / 6, y1 + k(150 + i) * (i.isOdd ? 5 : 2)),
    ];
    final shape = DamageStyle.poly([
      for (final p in [
        ...top,
        Offset(rr + 2, mid),
        ...bot.reversed,
        Offset(l - 2, mid + 1),
      ])
        o + p,
    ]);
    canvas
      ..drawPath(
        shape,
        DamageStyle.fill(wet ? DamageStyle.wet : DamageStyle.interior),
      )
      ..drawLine(
        o + Offset(l + 2, mid),
        o + Offset(rr - 2, mid),
        DamageStyle.stroke(
          wet ? DamageStyle.wetBeam : DamageStyle.interiorBeam,
          3,
        ),
      )
      ..drawPath(shape, DamageStyle.stroke(DamageStyle.outline, 1.2))
      // 뜯긴 판자 끝(새 나무).
      ..drawPath(
        DamageStyle.poly([
          for (final p in top) o + p.translate(0, 1),
        ], close: false),
        DamageStyle.stroke(w.fresh, 1.3),
      )
      ..drawPath(
        DamageStyle.poly([
          for (final p in bot) o + p.translate(0, -1),
        ], close: false),
        DamageStyle.stroke(w.fresh, 1.1, .8),
      );
    // 매달린 판자 조각.
    final hx = o.dx + rr - 3;
    final hy = o.dy + y0;
    DamageStyle.rotated(canvas, Offset(hx, hy + 1), 18 + k(160) * 25, () {
      final plank = Rect.fromLTWH(hx - 13, hy + .5, 13, 5);
      canvas
        ..drawRect(plank, DamageStyle.fill(w.base))
        ..drawRect(plank, DamageStyle.stroke(DamageStyle.outline, 1))
        ..drawPath(
          Path()
            ..moveTo(hx - 13, hy + .5)
            ..relativeLineTo(-2, 1.5)
            ..relativeLineTo(2, 1.2)
            ..relativeLineTo(-1.5, 1.3)
            ..relativeLineTo(1.5, 1),
          DamageStyle.stroke(w.fresh, .9),
        )
        ..drawCircle(
          Offset(hx - 1.5, hy + 2.5),
          .9,
          DamageStyle.fill(DamageStyle.ironHi),
        );
    });
    if (!wet) return;
    canvas.drawPath(
      Path()
        ..moveTo(o.dx + l + 3, o.dy + y1 + 2)
        ..relativeQuadraticBezierTo(2, 4, 0, 7)
        ..moveTo(o.dx + l + 8, o.dy + y1 + 1)
        ..relativeQuadraticBezierTo(2, 5, -1, 9),
      DamageStyle.stroke(const Color(0xFF6AD0FF), 1.4, .8),
    );
  }
}
