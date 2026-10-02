import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/app/providers.dart';
import 'package:pirate_busters/battle/battle_stats.dart';
import 'package:pirate_busters/campaign/result_hero.dart';
import 'package:pirate_busters/campaign/rewards.dart';
import 'package:pirate_busters/campaign/stage_result_screen.dart';
import 'package:pirate_busters/campaign/star_rules.dart';
import 'package:pirate_busters/data/fleet_store.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';
import 'package:pirate_busters/meta/progress.dart';
import 'package:pirate_busters/meta/progress_store.dart';
import 'package:pirate_busters/settings/language.dart';
import 'package:pirate_busters/settings/settings_store.dart';
import 'package:pirate_busters/story/rig_portrait.dart';
import 'package:pirate_busters/ui/kit/kit_motion.dart';

import 'test_catalog.dart';

Future<void> _pump(WidgetTester tester, Widget screen, {bool? motion}) async {
  tester.view.physicalSize = const Size(1280, 720);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        settingsStoreProvider.overrideWithValue(MemorySettingsStore()),
        gameCatalogProvider.overrideWithValue(testCatalog),
        campaignProvider.overrideWithValue(testCampaign),
        fleetStoreProvider.overrideWithValue(MemoryFleetStore()),
        progressStoreProvider.overrideWithValue(
          MemoryProgressStore(),
        ),
      ],
      child: MaterialApp(
        locale: const Locale('ko'),
        supportedLocales: supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: motion == null
            ? screen
            : KitMotion(reduced: !motion, child: screen),
      ),
    ),
  );
  await tester.pump();
}

MatchSummary _summary({required bool won, String? mvp}) => MatchSummary(
  won: won,
  outcome: won ? MatchOutcome.sunk : MatchOutcome.floodSunk,
  turns: 9,
  floodPercent: 12,
  hullPercent: 71,
  piratesDown: 0,
  shotsFired: 4,
  mvpPirate: mvp,
);

void main() {
  group('MVP 해적 (설계서 §13.5, 판정과 무관한 표시 통계)', () {
    test('맞힌 결과는 마지막에 쏜 해적의 기여로 센다', () {
      final stats = BattleStats()
        ..record(const SimEvent(SimEventKind.fire, side: 0, slot: 0))
        ..record(const SimEvent(SimEventKind.blockDestroyed, side: 1))
        ..record(const SimEvent(SimEventKind.fire, side: 0, slot: 1))
        ..record(const SimEvent(SimEventKind.blockDestroyed, side: 1))
        ..record(const SimEvent(SimEventKind.blockDestroyed, side: 1))
        ..record(const SimEvent(SimEventKind.pirateHit, side: 1, value: 3));
      expect(stats.mvpSlot(0), 1);
      expect(stats.mvpSlot(1), -1, reason: '상대는 쏘지 않았다');
    });

    test('기여가 같으면 앞 슬롯이 MVP 다', () {
      final stats = BattleStats()
        ..record(const SimEvent(SimEventKind.fire, side: 0, slot: 2))
        ..record(const SimEvent(SimEventKind.blockDestroyed, side: 1))
        ..record(const SimEvent(SimEventKind.fire, side: 0, slot: 0))
        ..record(const SimEvent(SimEventKind.blockDestroyed, side: 1));
      expect(stats.mvpSlot(0), 0);
    });
  });

  group('결과 화면 연출 (설계서 §13.5)', () {
    final stage = testCampaign.stage('1-2');
    StageReward reward(MatchSummary s) => applyStageResult(
      const PlayerProgress(tutorialDone: 3),
      stage,
      const StarRules().evaluate(stage, s),
    ).reward;

    testWidgets('이기면 MVP 해적이 승리 표정으로 나온다', (tester) async {
      final s = _summary(won: true, mvp: 'p06_pang');
      await _pump(
        tester,
        StageResultScreen(
          stage: stage,
          summary: s,
          enemyFloodPercent: 40,
          reward: reward(s),
        ),
      );
      final l10n = await AppLocalizations.delegate.load(const Locale('ko'));
      expect(find.text(l10n.resultMvp), findsOneWidget);
      final rig = tester.widget<RigPortrait>(find.byType(RigPortrait));
      expect(rig.expr, 'win');
      expect(rig.species, testCatalog.speciesOf('p06_pang'));
      expect(find.byType(Drip), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('지면 젖은 해적과 기운 배가 나오고 MVP 표시는 없다', (tester) async {
      final s = _summary(won: false);
      await _pump(
        tester,
        StageResultScreen(
          stage: stage,
          summary: s,
          enemyFloodPercent: 40,
          reward: reward(s),
        ),
      );
      final l10n = await AppLocalizations.delegate.load(const Locale('ko'));
      expect(find.text(l10n.resultMvp), findsNothing);
      expect(find.byType(Drip), findsOneWidget);
      expect(tester.widget<RigPortrait>(find.byType(RigPortrait)).expr, 'lose');
      expect(tester.takeException(), isNull);
    });

    testWidgets('탭하면 별이 차례를 기다리지 않고 바로 다 보인다', (tester) async {
      final s = _summary(won: true, mvp: 'p01_octo');
      await _pump(
        tester,
        StageResultScreen(
          stage: stage,
          summary: s,
          enemyFloodPercent: 40,
          reward: reward(s),
        ),
        motion: true,
      );
      double lastStar() => tester
          .widgetList<Opacity>(
            find.descendant(
              of: find.byType(PopIn),
              matching: find.byType(Opacity),
            ),
          )
          .map((o) => o.opacity)
          .reduce((a, b) => a < b ? a : b);
      expect(lastStar(), 0, reason: '아직 차례가 오지 않은 별이 있다');
      await tester.tapAt(const Offset(320, 40));
      await tester.pump();
      expect(lastStar(), 1);
      // 반복 움직임(뛰기)이 멈췄으니 정리된다.
      await tester.pumpAndSettle();
    });
  });
}
