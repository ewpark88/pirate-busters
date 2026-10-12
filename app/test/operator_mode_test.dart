import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/app/providers.dart';
import 'package:pirate_busters/campaign/battle_prep_screen.dart';
import 'package:pirate_busters/campaign/campaign_map_screen.dart';
import 'package:pirate_busters/data/fleet_store.dart';
import 'package:pirate_busters/dev/dev_flags.dart';
import 'package:pirate_busters/dev/motion_preview_game.dart';
import 'package:pirate_busters/dev/motion_viewer_screen.dart';
import 'package:pirate_busters/dev/operator_actions.dart';
import 'package:pirate_busters/dev/operator_limits.dart';
import 'package:pirate_busters/dev/operator_screen.dart';
import 'package:pirate_busters/dev/test_battle.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';
import 'package:pirate_busters/meta/progress.dart';
import 'package:pirate_busters/meta/progress_store.dart';
import 'package:pirate_busters/meta/ship_upgrades.dart';
import 'package:pirate_busters/port/port_widgets.dart';
import 'package:pirate_busters/port/settings_screen.dart';
import 'package:pirate_busters/settings/language.dart';
import 'package:pirate_busters/settings/settings_store.dart';

import 'test_catalog.dart';

/// 테스트용 비밀번호. 실제 비밀번호 원문은 저장소에 두지 않는다 (ADR-099).
const _pass = 'test-pass';
final _passHash = sha256.convert(utf8.encode(_pass)).toString();

Future<ProviderContainer> _pump(
  WidgetTester tester,
  Widget screen, {
  required SettingsStore settings,
  MemoryProgressStore? progress,
}) async {
  tester.view.physicalSize = const Size(1280, 720);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  final container = ProviderContainer(
    overrides: [
      settingsStoreProvider.overrideWithValue(settings),
      gameCatalogProvider.overrideWithValue(testCatalog),
      campaignProvider.overrideWithValue(testCampaign),
      fleetStoreProvider.overrideWithValue(MemoryFleetStore()),
      progressStoreProvider.overrideWithValue(
        progress ?? MemoryProgressStore(),
      ),
      operatorPassHashProvider.overrideWithValue(_passHash),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
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
  return container;
}

Future<MemorySettingsStore> _operatorOn() async {
  final settings = MemorySettingsStore();
  await settings.setDevTools(on: true);
  return settings;
}

void main() {
  group('운영자 모드 (ADR-099)', () {
    testWidgets('7번 탭으로 나타난 버튼에 틀린 비밀번호는 거절하고 맞으면 켜며, 나가기로 끈다', (
      tester,
    ) async {
      final settings = MemorySettingsStore();
      final c = await _pump(tester, const SettingsScreen(), settings: settings);
      for (var i = 0; i < devToolsTaps; i++) {
        await tester.tap(find.text('언어'));
        await tester.pump(const Duration(milliseconds: 100));
      }
      Future<void> enter(String text) async {
        await tester.ensureVisible(
          find.byKey(const ValueKey('operator_enter')),
        );
        await tester.tap(find.byKey(const ValueKey('operator_enter')));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const ValueKey('operator_password')),
          text,
        );
        await tester.tap(find.byKey(const ValueKey('operator_ok')));
        await tester.pumpAndSettle();
      }

      await enter('wrong');
      expect(settings.devTools, isFalse);
      expect(c.read(devToolsProvider), isFalse);
      await tester.pump(const Duration(seconds: 5));

      await enter(_pass);
      expect(settings.devTools, isTrue);
      expect(c.read(devToolsProvider), isTrue);
      expect(find.byKey(const ValueKey('operator_exit')), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));

      await tester.ensureVisible(find.byKey(const ValueKey('operator_exit')));
      await tester.tap(find.byKey(const ValueKey('operator_exit')));
      await tester.pumpAndSettle();
      expect(settings.devTools, isFalse);
      expect(find.byKey(const ValueKey('operator_enter')), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
    });

    test('실제 비밀번호는 해시로만 비교한다', () {
      expect(matchesPassHash('wrong', operatorPassHash), isFalse);
      expect(matchesPassHash(_pass, _passHash), isTrue);
      expect(operatorPassHash, hasLength(64));
    });

    testWidgets('켜져 있으면 지도에서 튜토리얼과 캠페인 스테이지가 모두 열린다', (tester) async {
      await _pump(
        tester,
        const CampaignMapScreen(),
        settings: await _operatorOn(),
        progress: MemoryProgressStore(
          const PlayerProgress(seenStories: ['sea_1_intro']),
        ),
      );
      expect(find.text('튜토리얼 1'), findsOneWidget);
      expect(find.text('1-12'), findsOneWidget);
      expect(find.image(const AssetImage(PortIcons.lock)), findsNothing);
    });

    testWidgets('운영자 화면의 스테이지 버튼은 전투 준비 화면을 바로 연다', (tester) async {
      await _pump(
        tester,
        const OperatorScreen(),
        settings: await _operatorOn(),
      );
      await tester.tap(find.byKey(const ValueKey('operator_stage_1-12')));
      await tester.pumpAndSettle();
      expect(find.byType(BattlePrepScreen), findsOneWidget);
    });

    testWidgets('진행 버튼은 골드·레벨·해적·배를 저장에 바로 넣는다', (tester) async {
      final store = MemoryProgressStore();
      await _pump(
        tester,
        const OperatorScreen(),
        settings: await _operatorOn(),
        progress: store,
      );
      for (final key in [
        'operator_gold',
        'operator_level',
        'operator_pirates',
        'operator_ship_max',
      ]) {
        await tester.ensureVisible(find.byKey(ValueKey(key)));
        await tester.tap(find.byKey(ValueKey(key)));
        await tester.pump();
      }
      final p = store.progress;
      expect(p.gold, OperatorActions.gold);
      expect(p.level, PlayerProgress.maxLevel);
      expect(p.ownedPirates, hasLength(testCatalog.data.pirates.length));
      expect(p.ship.stage, HullSpec.maxStage);
      await tester.pump(const Duration(seconds: 5));
    });

    test('배 전부 최대로는 모든 재질·모듈·돛대 최고 레벨을 연다', () {
      final ship = OperatorActions.maxShip(const PlayerProgress()).ship;
      expect(ship.hullLevel, HullSpec.maxLevel);
      for (final m in ShipUpgrades.materialGold.keys) {
        expect(ship.hasMaterial(m), isTrue, reason: m.name);
      }
      for (final k in ModuleKind.values.where((k) => k.isMast)) {
        if (ship.hasModule(k)) {
          expect(ship.mastLevel(k), BlockMaterial.maxRigLevel);
        }
      }
      expect(
        OperatorActions.reset(const PlayerProgress(gold: 5)).gold,
        isZero,
      );
    });

    test('켜져 있으면 출전 코스트 한도가 테스트 대전 한도로 풀린다', () async {
      final settings = MemorySettingsStore();
      final c = ProviderContainer(
        overrides: [
          settingsStoreProvider.overrideWithValue(settings),
          progressStoreProvider.overrideWithValue(MemoryProgressStore()),
          operatorPassHashProvider.overrideWithValue(_passHash),
        ],
      );
      addTearDown(c.dispose);
      expect(c.read(costLimitProvider), const PlayerProgress().costLimit);
      expect(await c.read(devToolsProvider.notifier).enter(_pass), isTrue);
      expect(c.read(costLimitProvider), TestBattle.costLimit);
    });

    test('모션 보기 게임은 해적을 세우기 전에도 동작을 바꿔도 오류가 없다', () {
      final game = MotionPreviewGame();
      for (final m in Motion.values) {
        game.play(m);
        expect(game.motion, m);
      }
    });

    testWidgets('모션 보기 화면은 해적 전원 줄과 동작·팀 탭을 보이고 눌러도 오류가 없다', (
      tester,
    ) async {
      await _pump(
        tester,
        const MotionViewerScreen(),
        settings: await _operatorOn(),
      );
      final pirates = testCatalog.data.pirates;
      for (final def in pirates) {
        expect(find.byKey(ValueKey('practice_${def.id}')), findsOneWidget);
      }
      await tester.tap(find.text('공격'));
      await tester.tap(find.text('빨강'));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}
