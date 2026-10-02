// art/pb_v0.22_main/tools/flame/pb_rarity.dart·tools/rarity_fx.js 에서 가져와 고쳤다
// (docs/ASSETS.md): 크기를 선실 한 칸 해적에 맞추고(ADR-057) 신화 고리를 넣었다.
import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:pirate_busters/game/anim/rarity_fx.dart';
import 'package:pirate_busters/game/coords.dart';

/// 해적 몸에 붙는 등급 연출 (설계서 §10.5): 발밑 고리, 외곽 빛, 발사 순간 반짝.
/// 새 이미지 없이 도형만 그린다. 모두 시간의 순수 함수이고 판정과 무관하다.
abstract final class RarityPainter {
  /// 발밑 고리 가로 반지름(월드 px): 선실 칸 안에 든다.
  static const double auraRx = 11;
  static const double auraRy = 3;

  static Paint _fill(Color c, double op) =>
      Paint()..color = c.withValues(alpha: op.clamp(0, 1));

  static Paint _stroke(Color c, double width, double op) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..color = c.withValues(alpha: op.clamp(0, 1));

  /// 카드 반짝임과 같은 네 갈래 별.
  static void spark(
    Canvas c,
    Offset p,
    double r,
    Color color,
    double op,
    double rotDeg,
  ) {
    if (r <= 0 || op <= 0) return;
    final q = r * .18;
    final path = Path()
      ..moveTo(0, -r)
      ..quadraticBezierTo(q, -q, r, 0)
      ..quadraticBezierTo(q, q, 0, r)
      ..quadraticBezierTo(-q, q, -r, 0)
      ..quadraticBezierTo(-q, -q, 0, -r)
      ..close();
    c
      ..save()
      ..translate(p.dx, p.dy)
      ..rotate(rotDeg * math.pi / 180)
      ..drawPath(path, _fill(color, op))
      ..restore();
  }

  /// 무지개 색 (신화 고리·프리즘 꼬리).
  static Color hue(double deg) =>
      HSLColor.fromAHSL(1, deg % 360, .9, .72).toColor();

  /// 해적 뒤 외곽 빛: 영웅부터 등급색으로 번진다. 신화는 색이 도는 무지개다.
  /// 발 [foot] 기준, [sec] 는 흐른 시간.
  static void glow(
    Canvas c,
    Offset foot,
    RarityTier t,
    double alpha, {
    double sec = 0,
  }) {
    final base = t.color;
    if (base == null || t.glow <= 0) return;
    final color = t.aura > 2 ? hue(sec * 90) : base;
    final body = Rect.fromCenter(
      center: foot.translate(0, -Coords.pirateHeight / 2),
      width: Coords.pirateHeight * .62,
      height: Coords.pirateHeight * .9,
    );
    c.drawOval(
      body,
      Paint()
        ..color = color.withValues(alpha: .55 * alpha)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, t.glow * .5),
    );
  }

  /// 발밑 고리. [foot] 은 발 위치, [sec] 는 흐른 시간, [alpha] 는 해적 투명도.
  /// [fewer] 면 떠오르는 반짝임을 절반으로 줄인다(저사양 모드).
  static void aura(
    Canvas c,
    Offset foot,
    RarityTier t,
    double sec, {
    double alpha = 1,
    bool fewer = false,
  }) {
    final color = t.color;
    final hi = t.hi;
    if (t.aura == 0 || color == null || hi == null || alpha <= 0) return;
    final p = .5 + .5 * math.sin(sec * 3);
    const rx = auraRx;
    const ry = auraRy;
    c
      ..drawOval(
        Rect.fromCenter(center: foot, width: rx * 2 + 2, height: ry * 2 + 1),
        _fill(color, (.18 + .12 * p) * alpha),
      )
      ..drawOval(
        Rect.fromCenter(center: foot, width: rx * 2, height: ry * 2),
        _stroke(color, 1, (.6 + .3 * p) * alpha),
      );
    if (t.aura > 1) {
      // 전설: 도는 점선 고리와 옅은 빛기둥.
      final ring = Rect.fromCenter(
        center: foot,
        width: (rx + 2.5) * 2,
        height: (ry + 1) * 2,
      );
      final dash = _stroke(hi, .8, .85 * alpha);
      for (var i = 0; i < 12; i++) {
        c.drawArc(ring, i / 12 * 2 * math.pi + sec * .8, .3, false, dash);
      }
      final top = foot.dy - Coords.pirateHeight;
      final column = Path()
        ..moveTo(foot.dx - rx, foot.dy)
        ..lineTo(foot.dx - rx * .5, top)
        ..lineTo(foot.dx + rx * .5, top)
        ..lineTo(foot.dx + rx, foot.dy)
        ..close();
      c.drawPath(column, _fill(hi, (.07 + .05 * p) * alpha));
    }
    if (t.aura > 2) {
      // 신화: 무지개 고리가 돌고 빛 구슬 두 개가 발밑을 돈다.
      final ring = Rect.fromCenter(
        center: foot,
        width: (rx + 4) * 2,
        height: (ry + 1.6) * 2,
      );
      for (var h = 0; h < 6; h++) {
        c.drawArc(
          ring,
          h / 6 * 2 * math.pi + sec,
          .8 / 6 * 2 * math.pi,
          false,
          _stroke(hue(h * 60 + sec * 90), .9, .9 * alpha),
        );
      }
      for (var o = 0; o < 2; o++) {
        final a = sec * 2.2 + o * math.pi;
        final orb = foot.translate(
          math.cos(a) * (rx + 1),
          -Coords.pirateHeight * .35 + math.sin(a) * 3,
        );
        c.drawCircle(orb, 1.2, _fill(o == 0 ? color : hi, alpha));
      }
    }
    final motes = fewer ? (t.motes + 1) ~/ 2 : t.motes;
    for (var i = 0; i < motes; i++) {
      const life = 1.6;
      final u = ((sec + i * life / motes) % life) / life;
      final m = foot.translate(
        math.sin(i * 2.3) * rx * .8 + math.sin(sec * 2 + i) * 1.3,
        -2 - u * Coords.pirateHeight * .8,
      );
      spark(
        c,
        m,
        1.8 * (1 - u * .5),
        i.isOdd ? hi : color,
        math.sin(math.pi * u) * alpha,
        sec * 90,
      );
    }
  }

  /// 발사 순간 손끝 반짝. [t] 는 공격 동작을 시작한 뒤 흐른 시간(초).
  static void glint(Canvas c, Offset hand, RarityTier tier, double t) {
    final hi = tier.hi;
    final color = tier.color;
    if (tier.glint == 0 || hi == null || color == null || t < 0 || t > .5) {
      return;
    }
    final u = t / .5;
    final s = math.sin(math.pi * u);
    spark(c, hand, (3.5 + 2.8 * tier.glint) * s, hi, s, u * 90);
    if (tier.glint > 1) spark(c, hand, 9 * s, color, s * .5, 45 + u * 90);
  }
}
