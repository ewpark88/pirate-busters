import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pirate_busters/app/providers.dart';
import 'package:pirate_busters/battle/battle_session.dart';
import 'package:pirate_busters/battle/battle_setup.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';
import 'package:pirate_busters/settings/language.dart';
import 'package:pirate_busters/settings/settings_store.dart';
import 'package:pirate_busters/ui/hud/battle_hud.dart';

Future<BattleSession> _pumpHud(
  WidgetTester tester,
  Locale locale, {
  bool paused = false,
}) async {
  // 작은 가로 폰(논리 640×360).
  tester.view.physicalSize = const Size(1280, 720);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  final session = BattleSession(
    BattleSetup.newMatch(3),
    humanSides: const {0, 1},
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        settingsStoreProvider.overrideWithValue(MemorySettingsStore()),
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
        home: Scaffold(
          body: BattleHud(
            session: session,
            overview: ValueNotifier(false),
            paused: paused,
            onPause: (_) {},
            onRestart: ({hotseat}) {},
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return session;
}

void main() {
  group('전투 HUD 두 언어 (설계서 §13.4, §14)', () {
    testWidgets('한국어로 HUD 글자가 나오고 넘치지 않는다', (tester) async {
      await _pumpHud(tester, const Locale('ko'));
      expect(find.text('턴 종료'), findsOneWidget);
      expect(find.text('남은 턴 30'), findsOneWidget);
      expect(find.text('연료'), findsWidgets);
      expect(find.textContaining('침수'), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('영어로 HUD 글자가 나오고 넘치지 않는다', (tester) async {
      await _pumpHud(tester, const Locale('en'));
      expect(find.text('End turn'), findsOneWidget);
      expect(find.text('30 turns left'), findsOneWidget);
      expect(find.text('Fuel'), findsWidgets);
      expect(find.textContaining('Flood'), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('일시정지 창이 두 언어로 나오고 넘치지 않는다', (tester) async {
      for (final locale in supportedLocales) {
        await _pumpHud(tester, locale, paused: true);
        expect(find.byType(ChoiceChip), findsNWidgets(5));
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('턴 종료 버튼을 누르면 턴이 넘어간다', (tester) async {
      final session = await _pumpHud(tester, const Locale('en'));
      final side = session.state.activeSide;
      await tester.tap(find.text('End turn'));
      await tester.pump();
      expect(session.state.activeSide, 1 - side);
    });
  });
}
