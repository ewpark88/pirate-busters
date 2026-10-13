import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/app/providers.dart';
import 'package:pirate_busters/crew/crew_filter.dart';
import 'package:pirate_busters/crew/crew_screen.dart';
import 'package:pirate_busters/crew/crew_ship.dart';
import 'package:pirate_busters/crew/crew_widgets.dart';
import 'package:pirate_busters/crew/pirate_detail.dart';
import 'package:pirate_busters/data/fleet_store.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';
import 'package:pirate_busters/l10n/data_text.dart';
import 'package:pirate_busters/meta/my_ship.dart';
import 'package:pirate_busters/meta/progress.dart';
import 'package:pirate_busters/meta/progress_store.dart';
import 'package:pirate_busters/meta/ship_upgrades.dart';
import 'package:pirate_busters/settings/language.dart';
import 'package:pirate_busters/settings/settings_store.dart';
import 'package:pirate_busters/shipyard/ship_grid_view.dart';

import 'test_catalog.dart';

/// 큰 슬루프(선실 4칸)를 지은 진행, 해적 전원 보기 (설계서 §3.1, ADR-099).
const _progress = PlayerProgress(ship: ShipUpgrades(stage: 4));

Future<MemoryFleetStore> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1280, 720);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  final store = MemoryFleetStore();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        settingsStoreProvider.overrideWithValue(MemorySettingsStore()),
        gameCatalogProvider.overrideWithValue(testCatalog),
        fleetStoreProvider.overrideWithValue(store),
        progressStoreProvider.overrideWithValue(
          MemoryProgressStore(_progress),
        ),
      ],
      child: const MaterialApp(
        locale: Locale('ko'),
        supportedLocales: supportedLocales,
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: CrewScreen(showAll: true),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return store;
}

AppLocalizations _l10n(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(CrewScreen)));

/// 목록 항목 수(스크롤로 그리므로 화면에 보이는 수가 아니라 목록 항목 수).
int _tiles(WidgetTester tester) {
  final grid = tester.widget<GridView>(find.byType(GridView));
  return (grid.childrenDelegate as SliverChildListDelegate).children.length;
}

/// 길게 눌러 [from] 에서 [to] 로 끈다.
Future<void> _holdDrag(WidgetTester tester, Offset from, Offset to) async {
  final g = await tester.startGesture(from);
  await tester.pump(const Duration(milliseconds: 400));
  await g.moveTo(Offset.lerp(from, to, .5)!);
  await tester.pump();
  await g.moveTo(to);
  await tester.pump();
  await g.up();
  await tester.pumpAndSettle();
}

void main() {
  final specs = [
    for (final d in testCatalog.data.pirates) testCatalog.pirates.byId(d.id),
  ];

  group('선원 목록 필터 (설계서 §13.7, A63)', () {
    test('비어 있으면 모두 남는다', () {
      expect(specs.where(const CrewFilter().matches), hasLength(specs.length));
    });

    test('등급 하나를 고르면 그 등급만 남는다', () {
      final f = const CrewFilter().toggleRarity(Rarity.legend);
      final left = specs.where(f.matches);
      expect(left, isNotEmpty);
      expect(left.every((s) => s.rarity == Rarity.legend), isTrue);
    });

    test('같은 묶음 둘을 고르면 합집합이다', () {
      final f = const CrewFilter()
          .toggleRarity(Rarity.common)
          .toggleRarity(Rarity.rare);
      expect(
        specs.where(f.matches).length,
        specs.where((s) => s.rarity.index <= Rarity.rare.index).length,
      );
    });

    test('등급과 탄종을 함께 고르면 둘 다 맞는 해적만 남는다', () {
      final s0 = specs.first;
      final f = const CrewFilter().toggleRarity(s0.rarity).toggleAmmo(s0.ammo);
      final left = specs.where(f.matches);
      expect(left, contains(s0));
      expect(
        left.every((s) => s.rarity == s0.rarity && s.ammo == s0.ammo),
        isTrue,
      );
    });

    test('다시 누르면 고른 값이 풀린다', () {
      final f = const CrewFilter()
          .toggleFamily(Family.lob)
          .toggleFamily(Family.lob);
      expect(f.isEmpty, isTrue);
    });

    testWidgets('필터 막대에서 등급을 고르면 목록과 개수 글자가 바뀐다', (tester) async {
      await _pump(tester);
      final total = _tiles(tester);
      final l10n = _l10n(tester);
      expect(find.text(l10n.crewFilterCount(total, total)), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('crew-filter-rarity')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('crew-chip-legend')));
      await tester.pumpAndSettle();
      final legends = specs.where((s) => s.rarity == Rarity.legend).length;
      expect(_tiles(tester), legends);
      expect(find.text(l10n.crewFilterCount(legends, total)), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('crew-filter-reset')));
      await tester.pumpAndSettle();
      expect(_tiles(tester), total);
    });
  });

  group('선원 목록 누르기·길게 눌러 끌기 (설계서 §13.7, A63)', () {
    testWidgets('목록을 세로로 밀면 카드가 끌려 나오지 않고 스크롤만 된다', (tester) async {
      final store = await _pump(tester);
      final grid = find.byType(GridView);
      final before = tester
          .state<ScrollableState>(
            find.descendant(of: grid, matching: find.byType(Scrollable)),
          )
          .position
          .pixels;
      await tester.drag(find.byType(PirateTile).first, const Offset(0, -200));
      await tester.pumpAndSettle();
      final after = tester
          .state<ScrollableState>(
            find.descendant(of: grid, matching: find.byType(Scrollable)),
          )
          .position
          .pixels;
      expect(after, greaterThan(before));
      expect(store.deck, isNull, reason: '덱은 그대로(저장 없음)');
    });

    testWidgets('목록 카드를 누르면 상세 창이 뜨고 덱은 바뀌지 않는다', (tester) async {
      final store = await _pump(tester);
      final l10n = _l10n(tester);
      final def = testCatalog.data.pirate('p06_pang');
      await tester.tap(find.byKey(const ValueKey('crew-tile-p06_pang')));
      await tester.pumpAndSettle();
      expect(find.byType(PirateDetail), findsOneWidget);
      expect(find.text(dataText(l10n, def.descKey)), findsOneWidget);
      expect(find.text(dataText(l10n, def.loreKey)), findsOneWidget);
      expect(store.deck, isNull);
    });

    testWidgets('상세 창 태우기는 빈 선실에 태우고, 내리기는 뺀다', (tester) async {
      final store = await _pump(tester);
      await tester.tap(find.byKey(const ValueKey('crew-tile-p06_pang')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('pirate-board')));
      await tester.pumpAndSettle();
      expect(store.deck, ['p01_octo', 'p36_tok', 'p06_pang']);
      await tester.tap(find.byKey(const ValueKey('crew-cabin-2')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('pirate-unboard')));
      await tester.pumpAndSettle();
      expect(store.deck, ['p01_octo', 'p36_tok']);
    });

    testWidgets('한 명만 남으면 내리기가 꺼진다', (tester) async {
      final store = await _pump(tester);
      await tester.tap(find.byKey(const ValueKey('crew-cabin-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('pirate-unboard')));
      await tester.pumpAndSettle();
      expect(store.deck, ['p01_octo']);
      await tester.tap(find.byKey(const ValueKey('crew-cabin-0')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('pirate-unboard')));
      await tester.pumpAndSettle();
      expect(store.deck, ['p01_octo']);
    });

    testWidgets('선실 배지를 다른 선실로 끌면 자리가 바뀐다', (tester) async {
      final store = await _pump(tester);
      final a = tester.getCenter(find.byKey(const ValueKey('crew-cabin-0')));
      final b = tester.getCenter(find.byKey(const ValueKey('crew-cabin-1')));
      await tester.dragFrom(a, b - a);
      await tester.pumpAndSettle();
      expect(store.deck, ['p36_tok', 'p01_octo']);
    });

    testWidgets('길게 눌러 끌어 빈 선실에 놓으면 앞쪽 빈 선실부터 타고 화면도 그 자리다', (
      tester,
    ) async {
      final store = await _pump(tester);
      final from = tester.getCenter(
        find.byKey(const ValueKey('crew-tile-p06_pang')),
      );
      final to = tester.getCenter(find.byKey(const ValueKey('crew-cabin-3')));
      await _holdDrag(tester, from, to);
      expect(store.deck, ['p01_octo', 'p36_tok', 'p06_pang']);
      // 3번 선실(인덱스 2)에 보이고 4번은 비었다: 저장·전투 자리와 같다.
      final ship = tester.widget<CrewShip>(find.byType(CrewShip));
      expect(ship.slots, ['p01_octo', 'p36_tok', 'p06_pang', null]);
    });

    testWidgets('가운데 해적을 내리면 뒤 해적이 앞 선실로 당겨져 보인다', (tester) async {
      final store = await _pump(tester);
      await tester.tap(find.byKey(const ValueKey('crew-tile-p06_pang')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('pirate-board')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('crew-cabin-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('pirate-unboard')));
      await tester.pumpAndSettle();
      expect(store.deck, ['p01_octo', 'p06_pang']);
      final ship = tester.widget<CrewShip>(find.byType(CrewShip));
      expect(ship.slots, ['p01_octo', 'p06_pang', null, null]);
    });
  });

  group('배 위 선실 배치 (설계서 §13.7, A63)', () {
    testWidgets('선실마다 배지가 하나씩, 선실 칸 위에 있다', (tester) async {
      await _pump(tester);
      final ship = tester.widget<CrewShip>(find.byType(CrewShip));
      final bp = ship.blueprint;
      expect(bp.cabins, hasLength(_progress.ship.hull.cabinSlots));
      final grid = tester.getTopLeft(find.byType(ShipGridView));
      final view = tester.widget<ShipGridView>(find.byType(ShipGridView));
      for (var i = 0; i < bp.cabins.length; i++) {
        final badge = find.byKey(ValueKey('crew-cabin-$i'));
        expect(badge, findsOneWidget);
        final c = bp.cabins[i];
        final cell = ShipGridView.cellRect(
          view.model.height,
          view.cell,
          c.x,
          c.y,
        ).shift(grid);
        expect(cell.contains(tester.getCenter(badge)), isTrue, reason: '$i');
      }
    });

    test('배지는 손가락으로 누를 만큼 크되 이웃 선실과 겹치지 않는다', () {
      expect(CrewShip.badgeSize(10), greaterThanOrEqualTo(40));
      expect(CrewShip.badgeSize(60), greaterThan(60));
      expect(CrewShip.badgeSize(30, gap: 1), lessThan(30));
      const cabins = [CabinCell(2, 3), CabinCell(3, 3), CabinCell(6, 1)];
      expect(CrewShip.cabinGap(cabins), 1);
    });

    test('선원 화면 배는 전투에 나가는 내 배와 같다', () {
      final fleet = MemoryFleetStore();
      final bp = myBlueprint(fleet, testCatalog, _progress.ship);
      expect(bp.cabins, hasLength(_progress.ship.hull.cabinSlots));
    });
  });
}
