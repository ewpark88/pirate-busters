import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/app/providers.dart';
import 'package:pirate_busters/battle/battle_session.dart';
import 'package:pirate_busters/crew/crew_screen.dart';
import 'package:pirate_busters/data/fleet_store.dart';
import 'package:pirate_busters/dev/dev_flags.dart';
import 'package:pirate_busters/dev/practice_bar.dart';
import 'package:pirate_busters/dev/test_battle.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';
import 'package:pirate_busters/meta/progress_store.dart';
import 'package:pirate_busters/port/settings_screen.dart';
import 'package:pirate_busters/settings/language.dart';
import 'package:pirate_busters/settings/settings_store.dart';
import 'package:pirate_busters/ui/battle_screen.dart';

import 'test_catalog.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget child,
  SettingsStore settings, {
  bool? devTools,
}) async {
  tester.view.physicalSize = const Size(1280, 720);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: [
        settingsStoreProvider.overrideWithValue(settings),
        gameCatalogProvider.overrideWithValue(testCatalog),
        fleetStoreProvider.overrideWithValue(MemoryFleetStore()),
        progressStoreProvider.overrideWithValue(MemoryProgressStore()),
        if (devTools != null)
          devToolsProvider.overrideWith(() => _FixedDevTools(on: devTools)),
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

/// 빌드 종류와 상관없이 스위치 값을 정한다(테스트는 디버그 빌드라 늘 켜져 있다).
class _FixedDevTools extends DevToolsNotifier {
  _FixedDevTools({required this.on});

  final bool on;

  @override
  bool build() => on;
}

const _deck = ['p04_uni', 'p28_pelly', 'p01_octo', 'p11_finn'];

void main() {
  group('개발 도구 숨은 스위치·더미배 연습 (ADR-073)', () {
    testWidgets('설정의 언어 글자를 7번 연달아 누르면 스위치가 켜지고 다시 7번이면 꺼진다', (
      tester,
    ) async {
      final settings = MemorySettingsStore();
      await _pump(tester, const SettingsScreen(), settings);
      Future<void> taps(int n) async {
        for (var i = 0; i < n; i++) {
          await tester.tap(find.text('언어'));
          await tester.pump(const Duration(milliseconds: 100));
        }
      }

      await taps(devToolsTaps - 1);
      expect(settings.devTools, isFalse);
      await taps(1);
      expect(settings.devTools, isTrue);
      expect(find.text('개발 도구를 켰습니다'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      await taps(devToolsTaps);
      expect(settings.devTools, isFalse);
      // 알림 토스트가 사라질 때까지 기다린다.
      await tester.pump(const Duration(seconds: 5));
    });

    test('맨 앞 해적 교체는 고른 해적을 0번 선실에 넣고 선실 수를 넘지 않는다', () {
      const test = TestBattle(deck: _deck, enemyDeck: [], dummy: true);
      expect(test.withLead('p36_tok').deck, [
        'p36_tok',
        'p04_uni',
        'p28_pelly',
        'p01_octo',
      ]);
      // 이미 탄 해적은 앞으로만 옮긴다.
      expect(test.withLead('p01_octo').deck, [
        'p01_octo',
        'p04_uni',
        'p28_pelly',
        'p11_finn',
      ]);
      expect(test.withLead('p36_tok').dummy, isTrue);
      expect(
        const TestBattle(deck: [], enemyDeck: []).withLead('p36_tok').deck,
        ['p36_tok'],
      );
    });

    test('더미배는 쏘지도 움직이지도 않고 턴을 바로 넘긴다', () {
      const test = TestBattle(deck: _deck, enemyDeck: [], dummy: true);
      expect(
        const TestBattle(deck: _deck, enemyDeck: []).dummyController,
        isNull,
      );
      for (var seed = 1; seed <= 4; seed++) {
        final match = test.start(testSetup, seed);
        final bowX = match.state.sides[1].bowX;
        final s = BattleSession(
          match,
          humanSides: const {0},
          speciesOf: testCatalog.speciesOf,
          opponent: test.dummyController,
        );
        final kinds = <SimEventKind>[];
        for (var i = 0; i < 400 && s.state.turn < 5; i++) {
          if (s.canAct) s.endTurn();
          s.update(50);
          kinds.addAll(s.takeCues().map((e) => e.kind));
        }
        expect(s.state.turn, greaterThanOrEqualTo(5), reason: 'seed $seed');
        expect(kinds, isNot(contains(SimEventKind.fire)));
        expect(s.state.sides[1].bowX, bowX);
        s.dispose();
      }
    });

    testWidgets('연습 줄은 해적 전원을 띄우고 누른 해적을 알린다', (tester) async {
      String? picked;
      await _pump(
        tester,
        Scaffold(
          body: Stack(
            children: [
              PracticeBar(deck: _deck, onPick: (id) => picked = id),
            ],
          ),
        ),
        MemorySettingsStore(),
      );
      for (final def in testCatalog.data.pirates) {
        expect(find.byKey(ValueKey('practice_${def.id}')), findsOneWidget);
      }
      final last = testCatalog.data.pirates.last.id;
      await tester.ensureVisible(find.byKey(ValueKey('practice_$last')));
      await tester.tap(find.byKey(ValueKey('practice_$last')));
      expect(picked, last);
    });

    testWidgets('더미배 연습 전투에서 해적을 누르면 그 해적이 맨 앞인 새 판이 열린다', (
      tester,
    ) async {
      await _pump(
        tester,
        const BattleScreen(
          seed: 5,
          test: TestBattle(deck: _deck, enemyDeck: [], dummy: true),
        ),
        MemorySettingsStore(),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(seconds: 1)),
      );
      await tester.pump(const Duration(milliseconds: 50));
      PracticeBar bar() => tester.widget<PracticeBar>(find.byType(PracticeBar));
      expect(bar().deck, _deck);
      final pick = find.byKey(const ValueKey('practice_p36_tok'));
      await tester.ensureVisible(pick);
      await tester.tap(pick);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));
      expect(bar().deck.first, 'p36_tok');
      expect(bar().deck, hasLength(4));
      expect(tester.takeException(), isNull);
    });

    testWidgets('편성 화면은 스위치가 꺼지면 보유 해적만, 켜지면 해적 전원을 보인다', (
      tester,
    ) async {
      int tiles() {
        // 목록은 스크롤로 그리므로 화면에 보이는 수가 아니라 목록 항목 수를 센다.
        final grid = tester.widget<GridView>(find.byType(GridView));
        return (grid.childrenDelegate as SliverChildListDelegate)
            .children
            .length;
      }

      await _pump(
        tester,
        const CrewScreen(),
        MemorySettingsStore(),
        devTools: false,
      );
      expect(tiles(), lessThan(testCatalog.data.pirates.length));
      await _pump(
        tester,
        const CrewScreen(),
        MemorySettingsStore(),
        devTools: true,
      );
      expect(tiles(), testCatalog.data.pirates.length);
    });
  });
}
