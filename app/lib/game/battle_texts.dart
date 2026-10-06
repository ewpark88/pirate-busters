import 'package:pirate_busters/game/emotion_cues.dart';
import 'package:pirate_busters/game/hit_tag.dart';

/// 전장에 그리는 글자 (설계서 §10.4, §14.2). 화면이 l10n·NumberFormat 으로 바꿔
/// 넣는다. 기본값은 테스트용이다.
mixin BattleTexts {
  /// 피해 숫자 글자.
  String Function(int amount) damageText = (amount) => '$amount';

  /// 명중 이름표와 남은 턴 수 글자.
  String Function(HitTag tag) tagText = (tag) => tag.name;
  String Function(int turns) turnsText = (turns) => '$turns';

  /// 감정 연출 강조 문구 (설계서 §10.4).
  String Function(Emphasis e) emphasisText = (e) => e.name;

  /// 조준 각도·힘 글자.
  String Function(int degrees) aimAngleText = (d) => '$d°';
  String Function(int percent) aimPowerText = (p) => '$p%';
}
