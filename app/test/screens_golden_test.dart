import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pb_sim/pb_sim.dart';
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
import 'package:pirate_busters/port/port_widgets.dart';
import 'package:pirate_busters/port/settings_screen.dart';
import 'package:pirate_busters/settings/language.dart';
import 'package:pirate_busters/settings/settings_store.dart';
import 'package:pirate_busters/shipyard/shipyard_screen.dart';
import 'package:pirate_busters/story/cutscene_screen.dart';
import 'package:pirate_busters/story/story_data.dart';

import 'test_catalog.dart';

/// 골든은 글꼴 그리기가 OS 마다 달라 만든 환경(Windows)에서만 비교한다 (설계서 §14.4).
/// 다시 만들기: `flutter test test/screens_golden_test.dart --update-goldens`.
final bool _skipGolden = !Platform.isWindows;

Future<void> _loadJua() async {
  final bytes = File('assets/fonts/Jua-Regular.ttf').readAsBytesSync();
  final loader = FontLoader('Jua')
    ..addFont(Future.value(ByteData.view(bytes.buffer)));
  await loader.load();
}

void main() {
  setUpAll(_loadJua);
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
        return Scaffold(
          backgroundColor: const Color(0xFF7FC0EC),
          body: SafeArea(
            child: Column(
              children: [
                PortTopBar(
                  progress: progress,
                  onSettings: () {},
                  onHotseat: () {},
                ),
                const Spacer(),
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
                  theme: ThemeData(fontFamily: 'Jua'),
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
            await tester.pump();
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
