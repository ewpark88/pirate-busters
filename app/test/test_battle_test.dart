import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pb_ai/pb_ai.dart';
import 'package:pirate_busters/app/providers.dart';
import 'package:pirate_busters/data/fleet_store.dart';
import 'package:pirate_busters/dev/test_battle.dart';
import 'package:pirate_busters/dev/test_battle_screen.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';
import 'package:pirate_busters/meta/progress.dart';
import 'package:pirate_busters/port/port_widgets.dart';
import 'package:pirate_busters/settings/language.dart';
import 'package:pirate_busters/settings/settings_store.dart';

import 'test_catalog.dart';

Future<void> _pump(WidgetTester tester, Widget child, FleetStore fleet) async {
  tester.view.physicalSize = const Size(1280, 720);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        settingsStoreProvider.overrideWithValue(MemorySettingsStore()),
        gameCatalogProvider.overrideWithValue(testCatalog),
        fleetStoreProvider.overrideWithValue(fleet),
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
        home: child,
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('개발용 테스트 대전 (ADR-053)', () {
    testWidgets('해적 전원이 등급별 구역에 나오고, 눌러 넣고 4명까지만 들어간다', (tester) async {
      final fleet = MemoryFleetStore();
      await _pump(tester, const TestBattleScreen(), fleet);
      for (final def in testCatalog.data.pirates) {
        expect(find.byKey(ValueKey('pick_${def.id}')), findsOneWidget);
      }
      expect(find.text('일반'), findsOneWidget);
      expect(find.text('희귀'), findsOneWidget);
      expect(find.text('영웅'), findsOneWidget);
      const ids = ['p04_uni', 'p28_pelly', 'p01_octo', 'p11_finn', 'p36_tok'];
      for (final id in ids) {
        await tester.ensureVisible(find.byKey(ValueKey('pick_$id')));
        await tester.tap(find.byKey(ValueKey('pick_$id')));
        await tester.pump();
      }
      expect(fleet.testDeck(0), ids.take(4));
      // 상대 덱으로 바꿔 고르면 따로 남는다.
      await tester.tap(find.byKey(const ValueKey('side_1')));
      await tester.pump();
      await tester.ensureVisible(find.byKey(const ValueKey('pick_p31_sharky')));
      await tester.tap(find.byKey(const ValueKey('pick_p31_sharky')));
      await tester.pump();
      expect(fleet.testDeck(1), ['p31_sharky']);
      expect(fleet.testDeck(0), hasLength(4));
    });

    test('코스트 15 를 넘는 덱(영웅·희귀 포함)도 그대로 판이 열린다', () {
      const deck = ['p04_uni', 'p28_pelly', 'p01_octo', 'p11_finn'];
      const test = TestBattle(
        deck: deck,
        enemyDeck: [],
        level: AiLevel.hell,
      );
      final match = test.start(testSetup, 7);
      final mine = [
        for (final p in match.state.sides[0].crew.pirates) p.spec.id,
      ];
      expect(mine, deck);
      final enemy = [
        for (final p in match.state.sides[1].crew.pirates) p.spec.id,
      ];
      expect(
        enemy,
        TestBattle.randomDeck(
          testCatalog.data.pirates.map((p) => p.id),
          7,
        ),
      );
      expect(enemy.toSet(), hasLength(4));
    });

    testWidgets('개발 도구가 꺼져 있으면 항구에 테스트 대전 버튼이 없다', (tester) async {
      Widget bar({VoidCallback? onTest}) => Scaffold(
        body: PortTopBar(
          progress: const PlayerProgress(),
          onSettings: () {},
          onHotseat: () {},
          onTestBattle: onTest,
        ),
      );
      await _pump(tester, bar(), MemoryFleetStore());
      expect(find.image(const AssetImage(PortIcons.quest)), findsNothing);
      await _pump(tester, bar(onTest: () {}), MemoryFleetStore());
      expect(find.image(const AssetImage(PortIcons.quest)), findsOneWidget);
    });
  });
}
