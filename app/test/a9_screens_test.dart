import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pb_ai/pb_ai.dart';
import 'package:pirate_busters/app/providers.dart';
import 'package:pirate_busters/campaign/battle_prep_screen.dart';
import 'package:pirate_busters/campaign/campaign_map_screen.dart';
import 'package:pirate_busters/crew/crew_screen.dart';
import 'package:pirate_busters/crew/crew_widgets.dart';
import 'package:pirate_busters/data/fleet_store.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';
import 'package:pirate_busters/meta/progress.dart';
import 'package:pirate_busters/meta/progress_store.dart';
import 'package:pirate_busters/platform/remote_overrides.dart';
import 'package:pirate_busters/platform/remote_values.dart';
import 'package:pirate_busters/settings/language.dart';
import 'package:pirate_busters/settings/settings_store.dart';
import 'package:pirate_busters/shipyard/blueprint_preview.dart';
import 'package:pirate_busters/story/cutscene_screen.dart';
import 'package:pirate_busters/story/story_data.dart';
import 'package:pirate_busters/ui/meta_icons.dart';

import 'test_catalog.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget screen, {
  PlayerProgress progress = const PlayerProgress(),
  FleetStore? fleet,
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
        fleetStoreProvider.overrideWithValue(fleet ?? MemoryFleetStore()),
        progressStoreProvider.overrideWithValue(MemoryProgressStore(progress)),
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
        home: screen,
      ),
    ),
  );
  await tester.pump();
}

AppLocalizations _l10n(WidgetTester tester, Type screen) =>
    AppLocalizations.of(tester.element(find.byType(screen)));

void main() {
  group('캠페인 지도: 본 이야기 다시 보기 (설계서 §13.3, §15.4)', () {
    testWidgets('본 이야기만 목록에 나오고 고르면 컷신이 열린다', (tester) async {
      const progress = PlayerProgress(
        tutorialDone: 3,
        prologueSeen: true,
        seenStories: [StoryData.sea1Intro],
      );
      expect(CampaignMapScreen.seenStories(progress), [
        StoryData.prologue,
        StoryData.sea1Intro,
      ]);
      await _pump(tester, const CampaignMapScreen(), progress: progress);
      final l10n = _l10n(tester, CampaignMapScreen);
      await tester.tap(find.byTooltip(l10n.storyReplay));
      await tester.pumpAndSettle();
      expect(find.text(l10n.storyTitlePrologue), findsOneWidget);
      expect(find.text(l10n.storyTitleSea1Intro), findsOneWidget);
      expect(find.text(l10n.storyTitleMidBossBefore), findsNothing);
      await tester.tap(find.text(l10n.storyTitleSea1Intro));
      await tester.pumpAndSettle();
      expect(find.byType(CutsceneScreen), findsOneWidget);
    });

    testWidgets('본 이야기가 없으면 안내 글만 보인다', (tester) async {
      // 튜토리얼 전이라 해역 인트로가 자동으로 뜨지 않는다.
      await _pump(tester, const CampaignMapScreen());
      final l10n = _l10n(tester, CampaignMapScreen);
      await tester.tap(find.byTooltip(l10n.storyReplay));
      await tester.pumpAndSettle();
      expect(find.text(l10n.storyReplayEmpty), findsOneWidget);
      // 다시 볼 이야기 단추 없이 위쪽 단추 그림 하나뿐이다.
      expect(find.image(const AssetImage(MetaIcons.replay)), findsOneWidget);
    });
  });

  group('선원 편성: 보유 해적만, 코스트 한도는 플레이어 레벨 (설계서 §4.5, §4.6)', () {
    testWidgets('보유 해적이 없으면 시작 해적 둘만, 보상으로 얻으면 늘어난다', (tester) async {
      await _pump(
        tester,
        const CrewScreen(showAll: false),
        progress: const PlayerProgress(tutorialDone: 3),
      );
      expect(find.byType(PirateTile), findsNWidgets(2));
      await _pump(
        tester,
        const CrewScreen(showAll: false),
        progress: const PlayerProgress(
          tutorialDone: 3,
          ownedPirates: ['p11_finn'],
        ),
      );
      expect(find.byType(PirateTile), findsNWidgets(3));
    });

    testWidgets('개발용 전원 보기는 플래그로만 켜지고 한도는 레벨 값이다', (tester) async {
      const progress = PlayerProgress(level: 3, tutorialDone: 3);
      await _pump(
        tester,
        // 개발 플래그 값과 같더라도 뜻을 분명히 적는다.
        // ignore: avoid_redundant_argument_values
        const CrewScreen(showAll: true),
        progress: progress,
      );
      // 목록은 스크롤로 그리므로 화면에 보이는 수가 아니라 목록 항목 수를 센다.
      final grid = tester.widget<GridView>(find.byType(GridView));
      final items = grid.childrenDelegate as SliverChildListDelegate;
      expect(items.children, hasLength(testCatalog.data.pirates.length));
      expect(find.byType(CostBar), findsOneWidget);
      expect(
        tester.widget<CostBar>(find.byType(CostBar)).limit,
        progress.costLimit,
      );
    });
  });

  group('전투 준비 화면 (설계서 §13.3)', () {
    final stage = testCampaign.stage('1-2');

    testWidgets('내 배 미리보기·선실 배치·성격 아이콘이 보인다', (tester) async {
      final fleet = MemoryFleetStore();
      await fleet.saveBlueprint(0, testCatalog.presets.first.blueprint);
      await _pump(
        tester,
        BattlePrepScreen(stage: stage),
        progress: const PlayerProgress(tutorialDone: 3),
        fleet: fleet,
      );
      final l10n = _l10n(tester, BattlePrepScreen);
      expect(find.byType(BlueprintPreview), findsOneWidget);
      expect(
        find.image(AssetImage(MetaIcons.personality(stage.personality))),
        findsOneWidget,
      );
      // 해역 1 세력 깃발과 이름 (설계서 §15.3).
      expect(find.image(AssetImage(MetaIcons.factionOfSea(1))), findsOneWidget);
      expect(find.text(l10n.sea_1_faction), findsOneWidget);
      expect(find.text(l10n.prepCabins), findsOneWidget);
      // 시작 덱 2명, 슬루프 선실 4개 → 빈 선실 2개.
      expect(find.text(l10n.prepCabinEmpty), findsNWidgets(2));
    });

    testWidgets('설계도가 없으면 타고 나갈 추천 설계도를 보여주고 비었다고 알린다', (tester) async {
      await _pump(
        tester,
        BattlePrepScreen(stage: stage),
        progress: const PlayerProgress(tutorialDone: 3),
      );
      final l10n = _l10n(tester, BattlePrepScreen);
      expect(find.byType(BlueprintPreview), findsOneWidget);
      expect(find.text(l10n.prepBlueprintEmpty), findsOneWidget);
    });
  });

  group('원격 설정 덮어쓰기 범위 (설계서 §7.4, 개발 계획서 A9)', () {
    test('스테이지 표: 난이도·파도·바람·별 턴·골드를 바꾸고 범위 밖은 무시한다', () {
      final stage = testCampaign.stage('1-2');
      final changed = applyRemoteStage(
        stage,
        MemoryRemoteValues({
          'stage_1-2_aiLevel': 'hard',
          'stage_1-2_waveLevel': 3,
          'stage_1-2_maxWind': 9,
          'stage_1-2_rewardGold': 777,
        }),
      );
      expect(changed.aiLevel, AiLevel.hard);
      expect(changed.waveLevel, 3);
      expect(changed.maxWind, stage.maxWind);
      expect(changed.rewardGold, 777);
      expect(changed.starTurns, stage.starTurns);
      expect(changed.id, stage.id);
      final whole = testCampaign.applyRemote(
        MemoryRemoteValues({'stage_1-2_waveLevel': 0}),
      );
      expect(whole.stage('1-2').waveLevel, 0);
      expect(whole.stage('1-1').waveLevel, testCampaign.stage('1-1').waveLevel);
    });

    test('해적 수치·탄종 사다리는 카탈로그에 덮어쓴다', () {
      final remote = MemoryRemoteValues({
        'pirate_p01_octo_blockDmg': 44,
        'ammo_explosive_common': 55,
      });
      final catalog = testCatalog.applyRemote(remote.intOr);
      final octo = catalog.pirates.byId('p01_octo');
      expect(octo.blockDamage, 44);
      expect(octo.ammoValue, 55);
      expect(
        catalog.pirates.byId('p36_tok').blockDamage,
        testCatalog.pirates.byId('p36_tok').blockDamage,
      );
    });

    test('AI 다이얼은 난이도별 키로 바꾸고 범위 밖은 무시한다', () {
      final dials = AiDials.withOverrides(
        AiLevel.normal,
        MemoryRemoteValues({
          'ai_normal_angleErrorMdeg': 1000,
          'ai_normal_combo': 1,
          'ai_normal_pickTopPercent': 500,
          'ai_normal_support': 0,
        }).intOr,
      );
      expect(dials.angleErrorMdeg, 1000);
      expect(dials.combo, isTrue);
      expect(dials.pickTopPercent, AiDials.of(AiLevel.normal).pickTopPercent);
      expect(dials.support, SupportUse.never);
      expect(dials.thinkMs, AiDials.of(AiLevel.normal).thinkMs);
    });
  });
}
