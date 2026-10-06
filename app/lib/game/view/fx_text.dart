import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';
import 'package:pirate_busters/app/app_theme.dart';
import 'package:pirate_busters/game/view/fx_layer.dart';
import 'package:pirate_busters/game/view/hit_weight.dart';

/// 피해 숫자 단계 (설계서 §10.4, A32): 한 방 크기에 따라 크기·색이 다르다.
enum DamageStyle {
  /// 작음: 흰색.
  small(18, 0xFFFFFFFF, 0xFF3A2A1A),

  /// 큼: 크고 주황이며 튀며 흔들린다.
  big(26, 0xFFFFA43A, 0xFF4A1E00),

  /// 치명: 가장 크고 빨강.
  crit(30, 0xFFFF4A3A, 0xFF3A0000);

  const DamageStyle(this.fontSize, this.color, this.outline);

  final double fontSize;
  final int color;
  final int outline;

  /// [weight] 한 방의 숫자 단계. 치명이면 [crit].
  static DamageStyle of(HitWeight weight, {bool crit = false}) => crit
      ? DamageStyle.crit
      : weight.level == HitLevel.light
      ? small
      : big;

  /// 튀며 흔들리는가.
  bool get wobbles => this != small;
}

/// 피해 숫자와 이름표 (설계서 §10.4). 글자는 화면이 l10n 으로 만들어 넘긴다 (§14.2).
extension FxText on FxLayer {
  /// 숫자가 떠 있는 시간(초)과 사라지기 시작하는 때.
  static const double life = 0.9;
  static const double fadeFrom = 0.55;

  /// 피해 숫자 (설계서 §10.4): 튀어 올랐다가 작아지며 사라지고, 특별한 결과는 아래에
  /// 이름표 [tag] 를 붙인다. [style] 은 한 방 크기의 단계다.
  void damageNumber(
    Vector2 at,
    String label, {
    String? tag,
    DamageStyle style = DamageStyle.small,
  }) {
    TextPaint paint(double size, int color, int outline) => TextPaint(
      style: TextStyle(
        fontFamily: AppFonts.display,
        fontSize: size,
        color: Color(color),
        shadows: [
          for (final o in const [(-1.5, 0.0), (1.5, 0.0), (0.0, -1.5)])
            Shadow(color: Color(outline), offset: Offset(o.$1, o.$2)),
          Shadow(color: Color(outline), offset: const Offset(0, 2.5)),
        ],
      ),
    );
    spawn(
      TextComponent(
        children: [
          ScaleEffect.to(
            Vector2.all(1),
            EffectController(duration: style.wobbles ? 0.26 : 0.18),
          ),
          MoveByEffect(Vector2(0, -34), EffectController(duration: life)),
          if (style.wobbles)
            RotateEffect.by(
              0.12,
              EffectController(
                duration: 0.06,
                reverseDuration: 0.06,
                repeatCount: 3,
              ),
            ),
          // 글자 그림자까지 함께 사라지게 투명도 대신 작아지며 사라진다.
          ScaleEffect.to(
            Vector2.zero(),
            EffectController(
              duration: life - fadeFrom,
              startDelay: fadeFrom,
              curve: Curves.easeIn,
            ),
          ),
          RemoveEffect(delay: life),
          if (tag != null)
            TextComponent(
              text: tag,
              position: Vector2(0, style.fontSize + 2),
              textRenderer: paint(11, 0xFFFFFFFF, 0xFF000000),
            ),
        ],
        text: label,
        position: at.clone(),
        scale: Vector2.all(style.wobbles ? 2.1 : 1.7),
        anchor: Anchor.center,
        priority: 10,
        textRenderer: paint(style.fontSize, style.color, style.outline),
      ),
    );
  }

  /// 이름표만 띄운다(피해 숫자가 없는 특별한 결과: 설치·수리).
  void tag(Vector2 at, String label) => damageNumber(at, label);
}
