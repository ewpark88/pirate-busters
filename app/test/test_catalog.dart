import 'dart:io';

import 'package:pirate_busters/battle/battle_setup.dart';
import 'package:pirate_busters/campaign/campaign_catalog.dart';
import 'package:pirate_busters/data/game_catalog.dart';

/// 테스트용 게임 데이터: 에셋 파일을 직접 읽는다(테스트 작업 폴더는 `app/`).
final GameCatalog testCatalog = GameCatalog.parse(
  ammoJson: File('assets/game/ammo.json').readAsStringSync(),
  piratesJson: File('assets/game/pirates.json').readAsStringSync(),
  blueprintsJson: File('assets/game/blueprints.json').readAsStringSync(),
);

final BattleSetup testSetup = BattleSetup(testCatalog);

/// 테스트용 캠페인 데이터 (해역 1).
final CampaignCatalog testCampaign = CampaignCatalog.parse([
  File('assets/stages/sea1.json').readAsStringSync(),
], testCatalog);
