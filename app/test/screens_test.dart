import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pirate_busters/app/providers.dart';
import 'package:pirate_busters/crew/crew_screen.dart';
import 'package:pirate_busters/data/fleet_store.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';
import 'package:pirate_busters/l10n/data_text.dart';
import 'package:pirate_busters/meta/progress.dart';
import 'package:pirate_busters/meta/progress_store.dart';
import 'package:pirate_busters/port/settings_screen.dart';
import 'package:pirate_busters/settings/language.dart';
import 'package:pirate_busters/settings/settings_store.dart';
import 'package:pirate_busters/shipyard/shipyard_screen.dart';

import 'test_catalog.dart';

Future<MemoryFleetStore> _pump(
  WidgetTester tester,
  Widget screen,
  Locale locale, {
  MemoryFleetStore? fleet,
  PlayerProgress progress = const PlayerProgress(),
}) async {
  // 작은 가로 폰(논리 640×360).
  tester.view.physicalSize = const Size(1280, 720);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  final store = fleet ?? MemoryFleetStore();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        settingsStoreProvider.overrideWithValue(MemorySettingsStore()),
        gameCatalogProvider.overrideWithValue(testCatalog),
        fleetStoreProvider.overrideWithValue(store),
        progressStoreProvider.overrideWithValue(
          MemoryProgressStore(progress),
        ),
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
  return store;
}

void main() {
  for (final locale in const [Locale('ko'), Locale('en')]) {
    final lang = locale.languageCode;

    testWidgets('설정·조선소·선원 화면이 $lang 로 넘치지 않고 그려진다 (설계서 §14)', (
      tester,
    ) async {
      for (final screen in const [
        SettingsScreen(),
        ShipyardScreen(),
        CrewScreen(),
      ]) {
        await _pump(tester, screen, locale);
        expect(tester.takeException(), isNull, reason: '$screen');
      }
    });
  }

  testWidgets('조선소: 추천 설계도로 시작해 저장하고 출전 배로 정한다', (tester) async {
    final store = await _pump(
      tester,
      const ShipyardScreen(),
      const Locale('ko'),
    );
    await tester.tap(find.text('저장'));
    await tester.pump();
    expect(store.blueprint(0), isNotNull);
    await tester.tap(find.text('설계도 2'));
    await tester.pump();
    await tester.tap(find.text('저장'));
    await tester.pump();
    await tester.tap(find.text('이 배로 출전'));
    await tester.pumpAndSettle();
    expect(store.activeSlot, 1);
    expect(find.text('출전 중'), findsOneWidget);
    // 저장 알림이 사라질 때까지 기다린다.
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('선원: 해적을 길게 눌러 빈 선실로 끌어다 놓으면 덱에 들고 저장된다', (tester) async {
    // 큰 슬루프(선실 4칸)를 지은 진행 (설계서 §3.1). 보유하지 않은 해적도 보이게
    // 해적 전원 보기로 연다(운영자 모드와 같은 목록, ADR-099).
    final store = await _pump(
      tester,
      const CrewScreen(showAll: true),
      const Locale('ko'),
    );
    final name = dataText(
      AppLocalizations.of(tester.element(find.byType(CrewScreen))),
      'pirate_p06_name',
    );
    final from = tester.getCenter(find.text(name));
    final to = tester.getCenter(find.byKey(const ValueKey('crew-cabin-2')));
    // 길게 눌러야 끌려 나온다 (A63).
    final g = await tester.startGesture(from);
    await tester.pump(const Duration(milliseconds: 400));
    await g.moveTo(Offset.lerp(from, to, .5)!);
    await tester.pump();
    await g.moveTo(to);
    await tester.pump();
    await g.up();
    await tester.pumpAndSettle();
    expect(store.deck, ['p01_octo', 'p36_tok', 'p06_pang']);
  });

  test('데이터 글자 키는 모두 조회 표에 있다 (tool/gen_data_text.dart)', () async {
    for (final locale in supportedLocales) {
      final l10n = await AppLocalizations.delegate.load(locale);
      for (final p in testCatalog.data.pirates) {
        for (final key in p.textKeys) {
          expect(dataText(l10n, key), isNot(key), reason: '$locale $key');
        }
      }
      for (final p in testCatalog.presets) {
        for (final key in p.textKeys) {
          expect(dataText(l10n, key), isNot(key), reason: '$locale $key');
        }
      }
    }
  });
}
