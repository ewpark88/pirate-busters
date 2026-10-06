import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/app/app_theme.dart';
import 'package:pirate_busters/app/providers.dart';
import 'package:pirate_busters/campaign/battle_prep_screen.dart';
import 'package:pirate_busters/campaign/campaign_map_screen.dart';
import 'package:pirate_busters/campaign/rewards.dart';
import 'package:pirate_busters/campaign/stage_result_screen.dart';
import 'package:pirate_busters/campaign/star_rules.dart';
import 'package:pirate_busters/crew/crew_screen.dart';
import 'package:pirate_busters/data/fleet_store.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';
import 'package:pirate_busters/meta/progress.dart';
import 'package:pirate_busters/meta/progress_store.dart';
import 'package:pirate_busters/port/port_goal_card.dart';
import 'package:pirate_busters/port/port_widgets.dart';
import 'package:pirate_busters/port/settings_screen.dart';
import 'package:pirate_busters/settings/language.dart';
import 'package:pirate_busters/settings/settings_store.dart';
import 'package:pirate_busters/shipyard/blueprint_preview.dart';
import 'package:pirate_busters/shipyard/shipyard_screen.dart';
import 'package:pirate_busters/story/backdrop_picture.dart';
import 'package:pirate_busters/story/cutscene_screen.dart';
import 'package:pirate_busters/story/story_data.dart';
import 'package:pirate_busters/ui/cards/rarity_card.dart';

import 'test_catalog.dart';
import 'test_fonts.dart';

/// 골든은 글꼴 그리기가 OS 마다 달라 만든 환경(Windows)에서만 비교한다 (설계서 §14.4).
/// 다시 만들기: `flutter test test/screens_golden_test.dart --update-goldens`.
final bool _skipGolden = !Platform.isWindows;

void main() {
  setUpAll(loadAppFonts);
  final stage = testCampaign.stage('1-2');
  const progress = PlayerProgress(
    level: 3,
    xp: 120,
    gold: 850,
    tutorialDone: 3,
    seenStories: ['prologue', 'sea_1_intro'],
    stars: {'1-1': 3},
  );
  final reward = applyStageResult(
    progress,
    stage,
    const StarResult(won: true, inTurns: true, mission: false),
  ).reward;
  const summary = MatchSummary(
    won: true,
    outcome: MatchOutcome.sunk,
    turns: 9,
    floodPercent: 12,
    hullPercent: 71,
    piratesDown: 0,
    shotsFired: 14,
    hits: 9,
    damageDealt: 320,
    blocksDestroyed: 11,
  );
  final screens = <String, Widget>{
    'port': Builder(
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        // 전장 그림(Flame)은 골든에서 그리지 않아 같은 해역 바다 그림과 내 배
        // 미리보기를 깐다. 위·아래 바와 다음 목표 카드는 화면 그대로다.
        return Scaffold(
          body: Stack(
            fit: StackFit.expand,
            children: [
              const BackdropPicture(region: 'tropic'),
              Align(
                alignment: const Alignment(0.2, 0.25),
                child: SizedBox(
                  width: 300,
                  height: 200,
                  child: BlueprintPreview(
                    blueprint: testCatalog.preset('balanced').blueprint,
                  ),
                ),
              ),
              SafeArea(
                child: Column(
                  children: [
                    PortTopBar(
                      progress: progress,
                      onSettings: () {},
                      onHotseat: () {},
                    ),
                    Expanded(
                      child: Align(
                        alignment: const Alignment(-0.95, 0),
                        child: PortGoalCard(
                          progress: progress,
                          campaign: testCampaign,
                          onStage: (_) {},
                        ),
                      ),
                    ),
                    PortTabs(
                      shipyardLocked: false,
                      onShipyard: () {},
                      onCrew: () {},
                      onSail: () {},
                      // 탭 라벨은 화면과 같이 l10n 에서 (설계서 §14.4).
                      labels: (
                        shipyard: l10n.menuShipyard,
                        crew: l10n.menuCrew,
                        sail: l10n.portSail,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    ),
    'shipyard': const ShipyardScreen(),
    'crew': const CrewScreen(),
    'settings': const SettingsScreen(),
    'map': const CampaignMapScreen(),
    'prep': BattlePrepScreen(stage: stage),
    'result': StageResultScreen(
      stage: stage,
      summary: summary,
      enemyFloodPercent: 40,
      reward: reward,
    ),
    'cutscene': CutsceneScreen(cuts: StoryData.of(StoryData.prologue)!),
    // 등급 카드 프레임 5종: 일반 · 희귀 · 영웅 · 전설 · 신화 (설계서 §10.5).
    'cards': Scaffold(
      body: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final rarity in Rarity.values)
              Padding(
                padding: const EdgeInsets.all(4),
                child: SizedBox(
                  width: 110,
                  child: RarityCard(rarity: rarity, species: 'octo'),
                ),
              ),
          ],
        ),
      ),
    ),
  };

  for (final (name, size) in const [
    ('low', Size(640, 360)),
    ('high', Size(1170, 540)),
  ]) {
    for (final locale in supportedLocales) {
      for (final entry in screens.entries) {
        testWidgets(
          '${entry.key} 골든: ${locale.languageCode} $name',
          (tester) async {
            // 컷신 배경·해적 자세 데이터는 실제 비동기로 미리 읽는다.
            await tester.runAsync(
              () => CutsceneScreen.preload(StoryData.of(StoryData.prologue)!),
            );
            tester.view.physicalSize = size * 2;
            tester.view.devicePixelRatio = 2;
            addTearDown(tester.view.reset);
            await tester.pumpWidget(
              ProviderScope(
                overrides: [
                  settingsStoreProvider.overrideWithValue(
                    MemorySettingsStore(),
                  ),
                  gameCatalogProvider.overrideWithValue(testCatalog),
                  campaignProvider.overrideWithValue(testCampaign),
                  fleetStoreProvider.overrideWithValue(MemoryFleetStore()),
                  progressStoreProvider.overrideWithValue(
                    MemoryProgressStore(progress),
                  ),
                ],
                child: MaterialApp(
                  debugShowCheckedModeBanner: false,
                  theme: appTheme(),
                  locale: locale,
                  supportedLocales: supportedLocales,
                  localizationsDelegates: const [
                    AppLocalizations.delegate,
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],
                  home: entry.value,
                ),
              ),
            );
            await loadImages(tester);
            await expectLater(
              find.byType(MaterialApp),
              matchesGoldenFile(
                'goldens/${entry.key}_${locale.languageCode}_$name.png',
              ),
            );
          },
          skip: _skipGolden,
        );
      }
    }
  }
}
