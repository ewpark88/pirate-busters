import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/battle/battle_setup.dart';
import 'package:pirate_busters/campaign/campaign_catalog.dart';
import 'package:pirate_busters/data/fleet_store.dart';
import 'package:pirate_busters/data/game_catalog.dart';
import 'package:pirate_busters/meta/progress.dart';
import 'package:pirate_busters/meta/ship_shop.dart';
import 'package:pirate_busters/meta/ship_upgrades.dart';

/// 전투·항구에 나가는 내 배 (설계서 §3.1·§3.3·§13.6): 출전 칸 설계도를 지금 확장
/// 단계로 키우고, 없거나 맞지 않으면 그 단계의 추천 설계도(열린 것만)로 대신한다.
/// 선형 레벨·돛대 레벨을 찍어서 돌려준다.
Blueprint myBlueprint(
  FleetStore fleet,
  GameCatalog catalog,
  ShipUpgrades ship, {
  int? slot,
}) {
  final saved = fleet.blueprint(slot ?? fleet.activeSlot, stage: ship.stage);
  final base =
      saved ??
      ship.unlockedOnly(
        catalog.preset(BattleSetup.defaultPreset, stage: ship.stage).blueprint,
      );
  return ship.stamp(base);
}

/// 스테이지로 열린 가장 큰 확장 단계 (설계서 §3.1, BALANCE.md A3.1).
int openedStageOf(PlayerProgress p, CampaignCatalog campaign) =>
    ShipUpgrades.openedStage(p.hasCleared, campaign.hasStage);

/// 확장 단계 [stage] 를 여는 스테이지 id (캠페인에 있는 것).
String stageClearFor(int stage, CampaignCatalog campaign) =>
    ShipUpgrades.stageClears[stage]!.firstWhere(
      campaign.hasStage,
      orElse: () => ShipUpgrades.stageClears[stage]!.last,
    );

/// 지금 골드로 할 수 있는 배 확장·해금이 있는가 (항구 빨간 점, 설계서 §13.2).
bool hasShipUpgradeReady(PlayerProgress p, CampaignCatalog campaign) {
  final opened = openedStageOf(p, campaign);
  if (ShipShop.buildStage(p, opened: opened) != null) return true;
  return [
    for (final m in ShipUpgrades.materialGold.keys)
      ShipShop.unlockMaterial(p, m),
    for (final k in ShipUpgrades.moduleGold.keys) ShipShop.unlockModule(p, k),
  ].any((next) => next != null);
}

/// [stageId] 를 깨서 아직 짓지 않은 확장 단계가 열렸는가 (결과 화면 안내, 설계서 §3.1).
bool growOpenedBy(String stageId, PlayerProgress p, CampaignCatalog campaign) =>
    ShipUpgrades.stageClears.values.any((ids) => ids.contains(stageId)) &&
    openedStageOf(p, campaign) > p.ship.stage;
