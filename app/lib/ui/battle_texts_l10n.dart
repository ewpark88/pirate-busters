import 'dart:ui';

import 'package:intl/intl.dart';
import 'package:pirate_busters/game/battle_game.dart';
import 'package:pirate_busters/game/emotion_cues.dart';
import 'package:pirate_busters/game/hit_tag.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';

/// 전장에 그리는 글자를 l10n·숫자 형식으로 넣는다 (설계서 §10.4, §14.2).
void applyBattleTexts(BattleGame game, AppLocalizations l10n, Locale locale) {
  final number = NumberFormat.decimalPattern(locale.toLanguageTag());
  game
    ..damageText = ((amount) => l10n.damagePopup(number.format(amount)))
    ..turnsText = number.format
    ..aimAngleText = ((d) => l10n.aimAngle(number.format(d)))
    ..aimPowerText = ((p) => l10n.aimPower(number.format(p)))
    // 감정 연출 강조 문구 (설계서 §10.4).
    ..emphasisText = ((e) => switch (e) {
      Emphasis.boom => l10n.emphasisBoom,
      Emphasis.doubleHit => l10n.emphasisDoubleHit,
      Emphasis.cabin => l10n.emphasisCabin,
      Emphasis.mast => l10n.emphasisMast,
    })
    // 명중 이름표 (설계서 §10.4).
    ..tagText = (tag) => switch (tag) {
      HitTag.crit => l10n.hitTagCrit,
      HitTag.pierce => l10n.hitTagPierce,
      HitTag.chain => l10n.hitTagChain,
      HitTag.burn => l10n.hitTagBurn,
      HitTag.mine => l10n.hitTagMine,
      HitTag.bite => l10n.hitTagBite,
      HitTag.repair => l10n.hitTagRepair,
      HitTag.seal => l10n.hitTagSeal,
      HitTag.pull => l10n.hitTagPull,
      HitTag.wind => l10n.hitTagWind,
      HitTag.blind => l10n.hitTagBlind,
      HitTag.bail => l10n.hitTagBail,
      HitTag.boost => l10n.hitTagBoost,
      HitTag.heal => l10n.hitTagHeal,
      HitTag.wall => l10n.hitTagWall,
      HitTag.revive => l10n.hitTagRevive,
      HitTag.intercept => l10n.hitTagIntercept,
    };
}
