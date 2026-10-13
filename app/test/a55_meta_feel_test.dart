import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/app/app_theme.dart';
import 'package:pirate_busters/app/providers.dart';
import 'package:pirate_busters/campaign/result_celebrate.dart';
import 'package:pirate_busters/campaign/rewards.dart';
import 'package:pirate_busters/campaign/stage_result_screen.dart';
import 'package:pirate_busters/campaign/star_rules.dart';
import 'package:pirate_busters/data/fleet_store.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';
import 'package:pirate_busters/meta/progress.dart';
import 'package:pirate_busters/meta/progress_store.dart';
import 'package:pirate_busters/settings/language.dart';
import 'package:pirate_busters/settings/settings_store.dart';
import 'package:pirate_busters/story/cutscene_screen.dart';
import 'package:pirate_busters/story/story_data.dart';
import 'package:pirate_busters/ui/kit/kit_motion.dart';
import 'package:pirate_busters/ui/kit/kit_sound.dart';
import 'package:pirate_busters/ui/kit/unlock_burst.dart';

import 'test_catalog.dart';
import 'test_fonts.dart';

void main() {
  group('A55 누름 소리·눌림 반응 (설계서 §10.3, §13 공통)', () {
    testWidgets('키트 누름 감싸개는 누를 때 누름 소리를 한 번 내고, 끄면 조용하다', (tester) async {
      var clicks = 0;
      var taps = 0;
      Widget app({required bool on}) => MaterialApp(
        home: KitSound(
          click: on ? () => clicks++ : null,
          child: Center(
            child: Pressable(
              onTap: () => taps++,
              child: const SizedBox(width: 80, height: 40),
            ),
          ),
        ),
      );
      await tester.pumpWidget(app(on: true));
      await tester.tap(find.byType(Pressable));
      expect((clicks, taps), (1, 1));
      await tester.pumpWidget(app(on: false));
      await tester.tap(find.byType(Pressable));
      expect((clicks, taps), (1, 2));
    });

    testWidgets('잠긴 카드가 열리는 순간에만 튀며 금빛 고리가 퍼진다', (tester) async {
      Widget app({required bool locked}) => MaterialApp(
        home: KitMotion(
          reduced: false,
          child: Center(
            child: UnlockBurst(
              locked: locked,
              child: const SizedBox(width: 80, height: 40),
            ),
          ),
        ),
      );
      await tester.pumpWidget(app(locked: true));
      await tester.pumpWidget(app(locked: true));
      expect(find.byKey(const ValueKey('unlock-ring')), findsNothing);
      await tester.pumpWidget(app(locked: false));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byKey(const ValueKey('unlock-ring')), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('unlock-ring')), findsNothing);
    });
  });

  group('A55 결과 화면 별 도장 (설계서 §13.5)', () {
    testWidgets('별은 크게 떨어져 찍히고, 찍히는 순간을 알린다', (tester) async {
      var landed = 0;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsStoreProvider.overrideWithValue(MemorySettingsStore()),
          ],
          child: MaterialApp(
            home: KitMotion(
              reduced: false,
              child: Center(
                child: StarStamp(
                  on: true,
                  order: 0,
                  onLand: () => landed++,
                  child: const SizedBox(width: 40, height: 40),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 60));
      final early = tester.widget<Transform>(
        find.descendant(
          of: find.byType(StarStamp),
          matching: find.byType(Transform),
        ),
      );
      expect(early.transform.getMaxScaleOnAxis(), greaterThan(1.5));
      expect(landed, 0);
      await tester.pumpAndSettle();
      expect(landed, 1);
    });
  });

  group('A55 결과 화면 골든 확장 (설계서 §13.5)', () {
    setUpAll(loadAppFonts);
    final stage = testCampaign.stage('1-2');
    const progress = PlayerProgress(level: 3, gold: 850, tutorialDone: 3);
    final cases = <String, (MatchSummary, StageReward)>{
      // 턴 제한 패배: 양쪽 남은 해적 체력 막대.
      'result_defeat': (
        const MatchSummary(
          won: false,
          outcome: MatchOutcome.timeDecision,
          turns: 24,
          hullPercent: 52,
          piratesDown: 1,
          shotsFired: 13,
          crewPercent: 38,
          foeCrewPercent: 61,
        ),
        const StageReward(
          gold: 0,
          xp: 20,
          firstClear: false,
          newPirate: null,
          levelBefore: 3,
          levelAfter: 3,
          stars: StarResult(won: false, inTurns: false, mission: false),
        ),
      ),
      // 레벨업 빛 배너.
      'result_levelup': (
        const MatchSummary(
          won: true,
          outcome: MatchOutcome.annihilation,
          turns: 18,
          hullPercent: 88,
          piratesDown: 0,
          shotsFired: 11,
        ),
        const StageReward(
          gold: 120,
          xp: 50,
          firstClear: false,
          newPirate: null,
          levelBefore: 3,
          levelAfter: 4,
          stars: StarResult(won: true, inTurns: true, mission: true),
        ),
      ),
    };
    for (final locale in supportedLocales) {
      for (final MapEntry(key: name, value: (summary, reward))
          in cases.entries) {
        testWidgets(
          '$name 골든: ${locale.languageCode}',
          (tester) async {
            // 해적 자세 데이터는 실제 비동기로 미리 읽는다(MVP 그림).
            await tester.runAsync(
              () => CutsceneScreen.preload(StoryData.of(StoryData.prologue)!),
            );
            tester.view.physicalSize = const Size(640, 360) * 2;
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
                  home: StageResultScreen(
                    stage: stage,
                    summary: summary,
                    reward: reward,
                  ),
                ),
              ),
            );
            await loadImages(tester);
            await expectLater(
              find.byType(MaterialApp),
              matchesGoldenFile('goldens/${name}_${locale.languageCode}.png'),
            );
          },
          skip: !Platform.isWindows,
        );
      }
    }
  });
}
