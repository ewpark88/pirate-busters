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
    BlockMaterial.rigPine => l10n.moduleMast,
  };

  static String module(AppLocalizations l10n, ModuleKind k) => switch (k) {
    ModuleKind.mast => l10n.moduleMast,
    ModuleKind.captain => l10n.moduleCaptain,
  };

  /// 조선소 격자에서 재질 색 (에셋 타일 색에 맞춤).
  static Color materialColor(BlockMaterial m) => switch (m) {
    BlockMaterial.pine => const Color(0xFFD9A441),
    BlockMaterial.oak => const Color(0xFF8B5A2B),
    BlockMaterial.iron => const Color(0xFF7D8590),
    BlockMaterial.rigPine => const Color(0xFF6B4528),
  };

  static String family(AppLocalizations l10n, Family f) => switch (f) {
    Family.lob => l10n.familyLob,
    Family.direct => l10n.familyDirect,
    Family.pierce => l10n.familyPierce,
    Family.skip => l10n.familySkip,
    Family.underwater => l10n.familyUnderwater,
    Family.air => l10n.familyAir,
    Family.assault => l10n.familyAssault,
    // 충격 계열 키(familyShock)는 ARB 추가 전까지 옛 보급 키를 빌린다 (ADR-111).
    Family.shock => l10n.familyShock,
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

  /// 탄종 이름(수치 없이). 선원 목록 필터 칩 (설계서 §4.8, §13.7).
  static String ammoKind(AppLocalizations l10n, AmmoType a) => switch (a) {
    AmmoType.explosive => l10n.ammoKindExplosive,
    AmmoType.fire => l10n.ammoKindFire,
    AmmoType.split => l10n.ammoKindSplit,
    AmmoType.burst => l10n.ammoKindBurst,
    AmmoType.sniper => l10n.ammoKindSniper,
    AmmoType.chain => l10n.ammoKindChain,
    AmmoType.pierce => l10n.ammoKindPierce,
    AmmoType.skip => l10n.ammoKindSkip,
    AmmoType.mine => l10n.ammoKindMine,
    AmmoType.flock => l10n.ammoKindFlock,
    AmmoType.homing => l10n.ammoKindHoming,
    AmmoType.assault => l10n.ammoKindAssault,
    // 충격탄 키(ammoKindShock)는 ARB 추가 전까지 옛 보급탄 키를 빌린다 (ADR-111).
    AmmoType.shock => l10n.ammoKindShock,
  };
}
