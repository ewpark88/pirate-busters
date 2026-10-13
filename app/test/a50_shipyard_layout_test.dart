import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pirate_busters/app/providers.dart';
import 'package:pirate_busters/data/fleet_store.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';
import 'package:pirate_busters/meta/progress.dart';
import 'package:pirate_busters/meta/progress_store.dart';
import 'package:pirate_busters/settings/language.dart';
import 'package:pirate_busters/settings/settings_store.dart';
import 'package:pirate_busters/shipyard/shipyard_model.dart';
import 'package:pirate_busters/shipyard/shipyard_screen.dart';
import 'package:pirate_busters/shipyard/shipyard_stats.dart';
import 'package:pirate_busters/ui/meta_icons.dart';

import 'test_catalog.dart';

Widget _app(Widget home, {PlayerProgress progress = const PlayerProgress()}) =>
    ProviderScope(
      overrides: [
        settingsStoreProvider.overrideWithValue(MemorySettingsStore()),
        gameCatalogProvider.overrideWithValue(testCatalog),
        fleetStoreProvider.overrideWithValue(MemoryFleetStore()),
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
        home: home,
      ),
    );

Future<void> _pump(WidgetTester tester, PlayerProgress progress) async {
  // 작은 가로 폰(논리 640×360).
  tester.view.physicalSize = const Size(1280, 720);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_app(const ShipyardScreen(), progress: progress));
  await tester.pump();
}

Finder _redDots() => find.byWidgetPredicate(
  (w) =>
      w is Image &&
      w.image is AssetImage &&
      (w.image as AssetImage).assetName == MetaIcons.redDot,
);

void main() {
  testWidgets('팔레트 탭을 바꾸면 그 묶음 카드만 보이고 선실·지우기는 늘 보인다 (설계서 §13.6)', (
    tester,
  ) async {
    await _pump(tester, const PlayerProgress());
    expect(find.text('소나무'), findsOneWidget);
    expect(find.text('선장실'), findsNothing);
    expect(find.text('선실'), findsOneWidget);
    expect(find.text('지우기'), findsOneWidget);
    expect(tester.takeException(), isNull, reason: '640×360 에서 넘치지 않는다');

    await tester.tap(find.text('모듈').last);
    await tester.pump();
    expect(find.text('선장실'), findsOneWidget);
    expect(find.text('소나무'), findsNothing);
    expect(find.text('선실'), findsOneWidget);
    expect(find.text('지우기'), findsOneWidget);

    await tester.tap(find.text('돛대'));
    await tester.pump();
    expect(find.text('소나무 돛대'), findsOneWidget);
    expect(find.text('선장실'), findsNothing);
  });

  testWidgets('골드가 없으면 빨간 점이 없다 (설계서 §13.6)', (tester) async {
    await _pump(tester, const PlayerProgress());
    expect(_redDots(), findsNothing);
  });

  testWidgets('지금 골드로 열 수 있는 것에는 빨간 점이 붙는다 (설계서 §13.6)', (tester) async {
    await _pump(tester, const PlayerProgress(gold: 100000));
    expect(_redDots(), findsWidgets);
  });

  testWidgets('잠긴 카드를 누르면 골드로 여는 확인창이 뜬다 (설계서 §13.6)', (tester) async {
    await _pump(tester, const PlayerProgress(gold: 100000));
    await tester.tap(find.text('철판'));
    await tester.pumpAndSettle();
    expect(find.text('사기'), findsOneWidget);
  });

  testWidgets('저장 조건이 어긋나면 이유 한 줄이 보이고 맞으면 사라진다 (설계서 §13.6)', (tester) async {
    final model = ShipyardModel();
    addTearDown(model.dispose);
    await tester.pumpWidget(
      _app(
        Scaffold(
          body: ListenableBuilder(
            listenable: model,
            builder: (_, _) => ShipyardGauges(model: model),
          ),
        ),
      ),
    );
    final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)));
    expect(model.canSave, isFalse);
    expect(find.text(l10n.cannotSave), findsOneWidget);

    model.load(testCatalog.preset('balanced').blueprint);
    await tester.pump();
    expect(model.canSave, isTrue);
    expect(find.text(l10n.cannotSave), findsNothing);
  });
}
