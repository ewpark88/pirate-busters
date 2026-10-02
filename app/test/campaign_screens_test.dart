import 'package:flutter/material.dart';
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
import 'package:pirate_busters/data/fleet_store.dart';
import 'package:pirate_busters/data/replay_store.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';
import 'package:pirate_busters/meta/progress.dart';
import 'package:pirate_busters/meta/progress_store.dart';
import 'package:pirate_busters/platform/ads.dart';
import 'package:pirate_busters/platform/analytics.dart';
import 'package:pirate_busters/settings/language.dart';
import 'package:pirate_busters/settings/settings_store.dart';
import 'package:pirate_busters/ui/meta_icons.dart';

import 'test_catalog.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget screen,
  Locale locale, {
  PlayerProgress progress = const PlayerProgress(),
  MemoryProgressStore? progressStore,
  RewardedAds? ads,
  MemoryAnalytics? analytics,
  ReplayStore? replays,
}) async {
  tester.view.physicalSize = const Size(1280, 720);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: [
        settingsStoreProvider.overrideWithValue(MemorySettingsStore()),
        gameCatalogProvider.overrideWithValue(testCatalog),
        campaignProvider.overrideWithValue(testCampaign),
        fleetStoreProvider.overrideWithValue(MemoryFleetStore()),
        progressStoreProvider.overrideWithValue(
          progressStore ?? MemoryProgressStore(progress),
        ),
        if (ads != null) adsProvider.overrideWithValue(ads),
        if (analytics != null) analyticsProvider.overrideWithValue(analytics),
        if (replays != null) replayStoreProvider.overrideWithValue(replays),
      ],
      child: MaterialApp(
        locale: locale,
        supportedLocales: supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: screen,
      ),
    ),
  );
  await tester.pump();
}

void main() {
  final stage = testCampaign.stage('1-2');
  const summary = MatchSummary(
    won: true,
    outcome: MatchOutcome.timeDecision,
    turns: 30,
    floodPercent: 20,
    hullPercent: 70,
    piratesDown: 0,
    shotsFired: 24,
  );
  final reward = applyStageResult(
    const PlayerProgress(xp: 90),
    stage,
    const StarResult(won: true, inTurns: false, mission: true),
  ).reward;

  for (final locale in const [Locale('ko'), Locale('en')]) {
    final lang = locale.languageCode;
    testWidgets('캠페인 지도·전투 준비·결과 화면이 $lang 로 넘치지 않고 그려진다', (
      tester,
    ) async {
      for (final screen in [
        const CampaignMapScreen(),
        BattlePrepScreen(stage: stage),
        StageResultScreen(
          stage: stage,
          summary: summary,
          enemyFloodPercent: 45,
          reward: reward,
        ),
      ]) {
        await _pump(tester, screen, locale);
        expect(tester.takeException(), isNull, reason: '$screen');
      }
    });
  }

  testWidgets('지도: 튜토리얼을 마치기 전에는 튜토리얼 노드 3개만 보인다 (설계서 §13.1)', (
    tester,
  ) async {
    await _pump(tester, const CampaignMapScreen(), const Locale('ko'));
    expect(find.text('t-1'), findsOneWidget);
    expect(find.byIcon(Icons.lock), findsNWidgets(2));
    expect(find.text('1-1'), findsNothing);
  });

  testWidgets('지도: 첫 스테이지만 열려 있고, 깬 뒤에는 다음 노드가 열린다', (tester) async {
    await _pump(
      tester,
      const CampaignMapScreen(),
      const Locale('ko'),
      progress: const PlayerProgress(
        tutorialDone: 3,
        seenStories: ['sea_1_intro'],
      ),
    );
    expect(find.byIcon(Icons.lock), findsNWidgets(5));
    await _pump(
      tester,
      const CampaignMapScreen(),
      const Locale('ko'),
      progress: const PlayerProgress(
        tutorialDone: 3,
        seenStories: ['sea_1_intro'],
      ).recordStage('1-1', 2),
    );
    expect(find.byIcon(Icons.lock), findsNWidgets(4));
    expect(find.image(const AssetImage(MetaIcons.starOn)), findsNWidgets(2));
  });

  testWidgets('결과: 시간 판정이면 침수 막대 두 개, 첫 클리어 보너스와 합류 해적이 보인다', (
    tester,
  ) async {
    await _pump(
      tester,
      StageResultScreen(
        stage: stage,
        summary: summary,
        enemyFloodPercent: 45,
        reward: reward,
      ),
      const Locale('ko'),
    );
    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));
    expect(find.byType(LinearProgressIndicator), findsNWidgets(2));
    expect(find.text(l10n.rewardFirstClear), findsOneWidget);
    expect(find.textContaining(l10n.pirate_p16_name), findsOneWidget);
    expect(find.text(l10n.levelUpTo(2)), findsOneWidget);
  });

  testWidgets('전투 준비: 대사를 탭하면 다음 줄로 넘어간다 (설계서 §15.4)', (tester) async {
    await _pump(tester, BattlePrepScreen(stage: stage), const Locale('ko'));
    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));
    expect(find.text(l10n.story_s1_2_enemy), findsOneWidget);
    await tester.tap(find.text(l10n.story_s1_2_enemy));
    await tester.pump();
    expect(find.text(l10n.story_s1_2_ally), findsOneWidget);
  });

  testWidgets('결과: 광고가 준비되면 2배 버튼이 보이고 보면 골드가 두 배가 된다 (설계서 §9)', (
    tester,
  ) async {
    final ads = FakeAds();
    final analytics = MemoryAnalytics();
    final store = MemoryProgressStore(const PlayerProgress(gold: 100));
    await _pump(
      tester,
      StageResultScreen(
        stage: stage,
        summary: summary,
        enemyFloodPercent: 45,
        reward: reward,
      ),
      const Locale('ko'),
      ads: ads,
      analytics: analytics,
      progressStore: store,
    );
    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));
    await tester.ensureVisible(find.text(l10n.resultDouble));
    await tester.tap(find.text(l10n.resultDouble));
    await tester.pumpAndSettle();
    expect(find.text(l10n.resultDoubleDone), findsOneWidget);
    expect(store.progress.gold, 100 + reward.gold);
    expect(analytics.names, contains(Events.adRewardView));
    expect(ads.shown, [AdPlacements.doubleReward]);
  });

  testWidgets('결과: 리플레이 저장 버튼은 저장소에 한 번만 넣는다', (tester) async {
    final replays = MemoryReplayStore();
    final prepared = testSetup.prepareStage(5, stage);
    await _pump(
      tester,
      StageResultScreen(
        stage: stage,
        summary: summary,
        enemyFloodPercent: 45,
        reward: reward,
        replay: prepared.replay(),
      ),
      const Locale('ko'),
      replays: replays,
    );
    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));
    await tester.ensureVisible(find.text(l10n.replaySave));
    await tester.tap(find.text(l10n.replaySave));
    await tester.pumpAndSettle();
    expect(find.text(l10n.replaySaved), findsOneWidget);
    expect(replays.names, hasLength(1));
  });
}
