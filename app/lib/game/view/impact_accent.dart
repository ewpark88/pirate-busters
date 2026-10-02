// art/pb_v0.22_main/tools/flame/pb_rarity.dart(drawImpactAccent·drawSlash·
// drawRepairAccent·drawScreenFlash) 에서 가져와 고쳤다 (docs/ASSETS.md).
import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:pirate_busters/game/anim/rarity_fx.dart';
import 'package:pirate_busters/game/view/rarity_painter.dart';

/// 명중 위에 덧그리는 등급 연출 (설계서 §10.5): 등급색 고리, 별 조각, 전설·신화의
/// 화면 번쩍. 강습은 베기 궤적, 지원은 수리 고리에 같은 규칙을 쓴다. 도형만 그린다.
enum AccentKind { impact, slash, repair }

class ImpactAccent extends Component {
  ImpactAccent(
    this.at,
    this.tier, {
    this.kind = AccentKind.impact,
    this.facing = 1,
    this.fewer = false,
    super.priority = 6,
  });

  final Vector2 at;
  final RarityTier tier;
  final AccentKind kind;

  /// 베기 방향(+1 오른쪽).
  final int facing;

  /// 저사양 모드: 별 조각을 절반으로 (설계서 §12).
  final bool fewer;

  /// 히트스톱 길이(초, 설계서 §10.4). 그동안 연출 dt 가 0 이라 고리는 멈춰 있다가
  /// 풀리면 퍼지기 시작한다.
  static const double hitStop = 0.07;
  static const double life = 0.9;

  double _t = 0;

  @override
  void update(double dt) {
    _t += dt;
    if (_t > life) removeFromParent();
  }

  static double _easeOut(double u) {
    final v = u.clamp(0.0, 1.0);
    return 1 - (1 - v) * (1 - v);
  }

  // Paint 는 하나를 고쳐 쓴다(프레임 부담, A13).
  static final Paint _strokePaint = Paint()..style = PaintingStyle.stroke;
  static final Paint _fillPaint = Paint();
  static final Paint _flashPaint = Paint()..blendMode = BlendMode.screen;

  static Paint _stroke(Color c, double width, double op) => _strokePaint
    ..strokeWidth = width
    ..color = c.withValues(alpha: op.clamp(0, 1));

  int get _shards => fewer ? (tier.shards + 1) ~/ 2 : tier.shards;

  @override
  void render(Canvas canvas) {
    final p = at.toOffset();
    switch (kind) {
      case AccentKind.impact:
        _impact(canvas, p, _t);
      case AccentKind.slash:
        _slash(canvas, p, _t);
        _impact(canvas, p, _t);
      case AccentKind.repair:
        _repair(canvas, p, _t);
    }
  }

  void _impact(Canvas c, Offset p, double t) {
    final color = tier.color;
    final hi = tier.hi;
    if (t < 0 || color == null || hi == null) return;
    for (var k = 0; k < tier.ring; k++) {
      final tt = t - k * .09;
      final u = tt / .42;
      if (tt < 0 || u > 1) continue;
      final r = 10 + 60 * _easeOut(u);
      c.drawOval(
        Rect.fromCenter(center: p, width: r * 2, height: r * 1.6),
        _stroke(k.isEven ? color : hi, 3 * (1 - u) + .5, 1 - u),
      );
    }
    const shardLife = .75;
    if (t <= shardLife) {
      final u = t / shardLife;
      final n = _shards;
      for (var i = 0; i < n; i++) {
        final a = -math.pi / 2 + (i / n - .5) * 2.6;
        final speed = 110.0 + (i * 37 % 90) * .5;
        RarityPainter.spark(
          c,
          p.translate(
            math.cos(a) * speed * t,
            math.sin(a) * speed * t + 210 * t * t,
          ),
          3.5 * (1 - u * .6),
          i.isOdd ? hi : color,
          1 - u * u,
          t * 400 + i * 40,
        );
      }
    }
    // 전설·신화: 명중 순간 화면이 등급색으로 번쩍인다.
    if (tier.aura >= 2 && t < .25) {
      c.drawRect(
        Rect.fromCenter(center: p, width: 8000, height: 8000),
        _flashPaint
          ..color = (tier.aura > 2 ? RarityPainter.hue(t * 1400) : color)
              .withValues(alpha: .18 * (1 - t / .25)),
      );
    }
  }

  /// 강습 베기: 흰 초승달 한 겹, 등급마다 겹이 늘어난다.
  void _slash(Canvas c, Offset p, double t) {
    if (t < 0 || t > .32) return;
    final u = t / .32;
    final color = tier.color;
    final hi = tier.hi;
    // 등급색이 없으면(일반) 흰 초승달 한 겹만 그린다.
    final layers = color != null && hi != null ? tier.ring + 1 : 1;
    final sweep = 2.6 * _easeOut(u / .5);
    final op = u < .5 ? 1.0 : 1 - (u - .5) / .5;
    const a0 = -1.9;
    for (var k = 0; k < layers; k++) {
      final r = 17 * (1 + k * .22);
      final col = (k.isOdd ? color : hi) ?? const Color(0xFFFFFFFF);
      Offset on(double a, double rr) =>
          Offset(p.dx + facing * math.cos(a) * rr, p.dy + math.sin(a) * rr);
      final outer = on(a0 + sweep, r);
      final inner = on(a0, r * .82);
      final path = Path()
        ..moveTo(on(a0, r).dx, on(a0, r).dy)
        ..arcToPoint(outer, radius: Radius.circular(r), clockwise: facing > 0)
        ..arcToPoint(
          inner,
          radius: Radius.elliptical(r * .78, r * .9),
          clockwise: facing <= 0,
        )
        ..close();
      c.drawPath(
        path,
        _fillPaint..color = col.withValues(alpha: op * (k == 0 ? .95 : .55)),
      );
    }
  }

  /// 지원 수리: 등급 고리와 반짝임. 공용 초록 수리 효과 위에 겹친다.
  void _repair(Canvas c, Offset p, double t) {
    final color = tier.color;
    final hi = tier.hi;
    if (t < 0 || color == null || hi == null) return;
    for (var k = 0; k < tier.ring; k++) {
      final tt = t - .05 - k * .09;
      final u = tt / .5;
      if (tt < 0 || u > 1) continue;
      c.drawCircle(
        p,
        7 + 30 * _easeOut(u),
        _stroke(k.isEven ? color : hi, 2.5 * (1 - u) + .5, 1 - u),
      );
    }
    final n = _shards;
    for (var i = 0; i < n; i++) {
      final tt = t - i * .04;
      if (tt < 0 || tt > .8) continue;
      final v = tt / .8;
      final a = i / n * 2 * math.pi;
      RarityPainter.spark(
        c,
        p.translate(math.cos(a) * (9 + 15 * v), math.sin(a) * 6 - 20 * v),
        2.5 * (1 - v * .5),
        i.isOdd ? hi : color,
        1 - v,
        tt * 300,
      );
    }
  }
}
