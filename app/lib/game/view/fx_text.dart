import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/painting.dart';
import 'package:pirate_busters/app/app_theme.dart';
import 'package:pirate_busters/game/view/fx_layer.dart';

/// 피해 숫자와 이름표 (설계서 §10.4). 글자는 화면이 l10n 으로 만들어 넘긴다 (§14.2).
extension FxText on FxLayer {
  /// 피해 숫자 (설계서 §10.4): 튀어 올랐다가 사라지고, 특별한 결과는 아래에 이름표
  /// [tag] 를 붙인다. 글자는 화면이 l10n 으로 만들어 넘긴다 (§14.2).
  void damageNumber(Vector2 at, String label, {String? tag}) {
    TextPaint paint(double size, int color) => TextPaint(
      style: TextStyle(
        fontFamily: AppFonts.display,
        fontSize: size,
        color: Color(color),
        shadows: const [Shadow(blurRadius: 3)],
      ),
    );
    spawn(
      TextComponent(
        children: [
          ScaleEffect.to(Vector2.all(1), EffectController(duration: 0.18)),
          MoveByEffect(Vector2(0, -34), EffectController(duration: 0.9)),
          RemoveEffect(delay: 0.9),
          if (tag != null)
            TextComponent(
              text: tag,
              position: Vector2(0, 20),
              textRenderer: paint(11, 0xFFFFFFFF),
            ),
        ],
        text: label,
        position: at.clone(),
        scale: Vector2.all(1.7),
        anchor: Anchor.center,
        priority: 10,
        textRenderer: paint(18, 0xFFFFE082),
      ),
    );
  }

  /// 이름표만 띄운다(피해 숫자가 없는 특별한 결과: 설치·수리).
  void tag(Vector2 at, String label) => damageNumber(at, label);
}
