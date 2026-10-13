import 'dart:ui';

import 'package:flame/components.dart';

/// 맞는 순간의 부드러운 섬광 (설계서 §10.4 ‘맞은 곳이 하얗게 번쩍’, 게임 정리 S4).
/// 예전 원반 그림 대신 가운데가 희고 바깥이 주황으로 번지는 빛을 [life] 초 동안
/// 키우며 끈다. 그리기만 한다.
class GlowFlash extends PositionComponent {
  GlowFlash(Vector2 at, this.radius, {this.life = .14, this.delay = 0})
    : super(position: at.clone(), anchor: Anchor.center);

  /// 다 퍼졌을 때 반지름(월드 px).
  final double radius;
  final double life;
  final double delay;
  double _age = 0;
  final Paint _paint = Paint()..blendMode = BlendMode.plus;

  /// [t] (0~1) 의 밝기: 처음에 가장 밝고 빠르게 꺼진다.
  static double alphaAt(double t) {
    final k = (1 - t).clamp(0, 1).toDouble();
    return k * k;
  }

  @override
  void update(double dt) {
    _age += dt;
    if (_age - delay >= life) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final t = (_age - delay) / life;
    if (t < 0) return;
    final r = radius * (.6 + .4 * t);
    // 반지름 1 짜리 빛을 한 번만 만들어 키워 그린다. 밝기는 붓의 투명도로 곱한다.
    _paint
      ..shader = _unit
      ..color = Color.fromRGBO(255, 255, 255, alphaAt(t));
    canvas
      ..save()
      ..scale(r)
      ..drawCircle(Offset.zero, 1, _paint)
      ..restore();
  }

  static final Shader _unit = Gradient.radial(
    Offset.zero,
    1,
    const [Color(0xFFFFFCEB), Color(0x8CFFBE5A), Color(0x00FF8030)],
    const [0, .45, 1],
  );
}

/// 묵직한 한 방의 충격파 (설계서 §10.4): 얇아지며 퍼지는 흰 고리. 예전 톱니 고리
/// 그림 대신 코드로 그린다.
class ShockRing extends PositionComponent {
  ShockRing(Vector2 at, this.radius, {this.life = .38, this.delay = 0})
    : super(position: at.clone(), anchor: Anchor.center);

  final double radius;
  final double life;
  final double delay;
  double _age = 0;
  final Paint _paint = Paint()..style = PaintingStyle.stroke;

  /// [t] 의 반지름 비율: 빠르게 퍼지고 끝에서 느려진다.
  static double spreadAt(double t) {
    final k = 1 - t.clamp(0, 1);
    return .25 + .75 * (1 - k * k * k);
  }

  @override
  void update(double dt) {
    _age += dt;
    if (_age - delay >= life) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final t = (_age - delay) / life;
    if (t < 0) return;
    final r = radius * spreadAt(t);
    _paint
      ..strokeWidth = 1.5 + 4 * (1 - t)
      ..color = Color.fromRGBO(255, 248, 230, .45 * (1 - t));
    // 수면 위에서 보는 고리라 위아래로 조금 눌린다.
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: r * 2, height: r * 1.4),
      _paint,
    );
  }
}
