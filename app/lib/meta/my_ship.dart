import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/battle/battle_setup.dart';
import 'package:pirate_busters/campaign/campaign_catalog.dart';
import 'package:pirate_busters/data/fleet_store.dart';
import 'package:pirate_busters/data/game_catalog.dart';
import 'package:pirate_busters/meta/progress.dart';
import 'package:pirate_busters/meta/ship_shop.dart';
import 'package:pirate_busters/meta/ship_upgrades.dart';

/// 전투·항구에 나가는 내 배 (설계서 §3.4·§13.6): 출전 칸 설계도. 없거나 맞지 않으면
/// 추천 설계도(열린 재질만)로 대신한다.
Blueprint myBlueprint(
  FleetStore fleet,
  GameCatalog catalog,
  ShipUpgrades ship, {
  int? slot,
}) {
  final saved = fleet.blueprint(slot ?? fleet.activeSlot);
  return saved ??
      ship.unlockedOnly(catalog.preset(BattleSetup.defaultPreset).blueprint);
}

/// 지금 골드로 열 수 있는 재질이 있는가 (항구 빨간 점, 설계서 §13.2).
bool hasShipUpgradeReady(PlayerProgress p, CampaignCatalog campaign) => [
  for (final m in ShipUpgrades.materialGold.keys) ShipShop.unlockMaterial(p, m),
].any((next) => next != null);
