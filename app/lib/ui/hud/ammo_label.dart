import 'package:intl/intl.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';

/// 해적 카드의 탄종과 등급 수치 (설계서 §4.8, §13.4). 예: 분열 ×4, 치명 ×1.5.
String ammoLabel(AppLocalizations l10n, PirateSpec spec, String locale) {
  final v = spec.ammoValue;
  return switch (spec.ammo) {
    AmmoType.explosive => l10n.ammoExplosive(v),
    AmmoType.fire => l10n.ammoFire(v),
    AmmoType.split => l10n.ammoSplit(v),
    AmmoType.burst => l10n.ammoBurst(v),
    AmmoType.sniper => l10n.ammoSniper(
      NumberFormat('0.0#', locale).format(v / 100),
    ),
    AmmoType.chain => l10n.ammoChain(v),
    AmmoType.pierce => l10n.ammoPierce(v),
    AmmoType.skip => l10n.ammoSkip(v),
    AmmoType.mine => l10n.ammoMine(v),
    AmmoType.flock => l10n.ammoFlock(v),
    AmmoType.homing => l10n.ammoHoming(v),
    AmmoType.assault => l10n.ammoAssault(v),
    AmmoType.support => l10n.ammoSupport(v),
  };
}

/// 사거리 등급 이름 (설계서 §2.8).
String rangeLabel(AppLocalizations l10n, RangeGrade range) => switch (range) {
  RangeGrade.short => l10n.rangeShort,
  RangeGrade.medium => l10n.rangeMedium,
  RangeGrade.long => l10n.rangeLong,
  RangeGrade.veryLong => l10n.rangeVeryLong,
};
