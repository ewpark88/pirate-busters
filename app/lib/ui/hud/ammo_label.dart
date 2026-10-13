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
    // 충격탄 전용 키(ammoShock)가 생기기 전까지 임시로 같은 꼴의 키를 쓴다 (S1).
    AmmoType.shock => l10n.ammoShock(v),
  };
}

/// 탄종 아이콘 (에셋 v0.22 `ammo/icons`, 설계서 §13.4 카드 칩). 파일 이름은 탄종 키다.
String ammoIconPath(AmmoType ammo) =>
    'assets/images/ammo/icons/${ammo.jsonName}.png';
