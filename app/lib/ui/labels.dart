import 'package:flutter/material.dart';
import 'package:pb_ai/pb_ai.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';

/// 규칙 값 → 화면 이름·아이콘·색. 글자는 모두 ARB 에서 온다 (설계서 §14).
abstract final class Labels {
  static String material(AppLocalizations l10n, BlockMaterial m) => switch (m) {
    BlockMaterial.pine => l10n.materialPine,
    BlockMaterial.oak => l10n.materialOak,
    BlockMaterial.iron => l10n.materialIron,
    BlockMaterial.cork => l10n.materialCork,
    BlockMaterial.net => l10n.materialNet,
  };

  static String module(AppLocalizations l10n, ModuleKind k) => switch (k) {
    ModuleKind.gunPort => l10n.moduleGunPort,
    ModuleKind.magazine => l10n.moduleMagazine,
    ModuleKind.pump => l10n.modulePump,
    ModuleKind.workshop => l10n.moduleWorkshop,
    ModuleKind.mast => l10n.moduleMast,
    ModuleKind.lookout => l10n.moduleLookout,
    ModuleKind.captain => l10n.moduleCaptain,
    ModuleKind.fuelTank => l10n.moduleFuelTank,
  };

  /// 조선소 격자에서 재질 색 (에셋 타일 색에 맞춤).
  static Color materialColor(BlockMaterial m) => switch (m) {
    BlockMaterial.pine => const Color(0xFFD9A441),
    BlockMaterial.oak => const Color(0xFF8B5A2B),
    BlockMaterial.iron => const Color(0xFF7D8590),
    BlockMaterial.cork => const Color(0xFFC9B38A),
    BlockMaterial.net => const Color(0xFFE8E2D0),
  };

  static String family(AppLocalizations l10n, Family f) => switch (f) {
    Family.lob => l10n.familyLob,
    Family.direct => l10n.familyDirect,
    Family.pierce => l10n.familyPierce,
    Family.skip => l10n.familySkip,
    Family.underwater => l10n.familyUnderwater,
    Family.air => l10n.familyAir,
    Family.assault => l10n.familyAssault,
    Family.support => l10n.familySupport,
  };

  static String aiLevel(AppLocalizations l10n, AiLevel l) => switch (l) {
    AiLevel.easy => l10n.levelEasy,
    AiLevel.normal => l10n.levelNormal,
    AiLevel.hard => l10n.levelHard,
    AiLevel.hell => l10n.levelHell,
  };

  static String rarity(AppLocalizations l10n, Rarity r) => switch (r) {
    Rarity.common => l10n.rarityCommon,
    Rarity.rare => l10n.rarityRare,
    Rarity.hero => l10n.rarityHero,
    Rarity.legend => l10n.rarityLegend,
    Rarity.myth => l10n.rarityMyth,
  };
}
