import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pirate_busters/app/providers.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';
import 'package:pirate_busters/meta/progress.dart';
import 'package:pirate_busters/meta/progress_store.dart';
import 'package:pirate_busters/port/port_widgets.dart';
import 'package:pirate_busters/port/settings_screen.dart';
import 'package:pirate_busters/settings/language.dart';
import 'package:pirate_busters/settings/settings_store.dart';

Future<MemorySettingsStore> _pump(
  WidgetTester tester,
  Widget body,
  Locale locale, {
  MemorySettingsStore? settings,
}) async {
  tester.view.physicalSize = const Size(1280, 720);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  final store = settings ?? MemorySettingsStore();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        settingsStoreProvider.overrideWithValue(store),
        progressStoreProvider.overrideWithValue(MemoryProgressStore()),
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
        home: Scaffold(body: body),
      ),
    ),
  );
  await tester.pump();
  return store;
}

void main() {
  group('항구 (설계서 §13.2)', () {
    for (final locale in const [Locale('ko'), Locale('en')]) {
      testWidgets('위쪽 막대와 탭이 ${locale.languageCode} 로 넘치지 않고 그려진다', (
        tester,
      ) async {
        await _pump(
          tester,
          Column(
            children: [
              PortTopBar(
                progress: const PlayerProgress(level: 7, xp: 320, gold: 12400),
                onSettings: () {},
                onHotseat: () {},
              ),
              const Spacer(),
              PortTabs(
                shipyardLocked: true,
                onShipyard: () {},
                onCrew: () {},
                onSail: () {},
                labels: (shipyard: 'A', crew: 'B', sail: 'C'),
              ),
            ],
          ),
          locale,
        );
        expect(tester.takeException(), isNull);
        expect(find.textContaining('7'), findsWidgets);
        expect(find.image(const AssetImage(PortIcons.lock)), findsOneWidget);
      });
    }

    testWidgets('골드는 언어에 맞는 숫자 형식으로 보인다 (설계서 §14.2)', (tester) async {
      await _pump(
        tester,
        PortTopBar(
          progress: const PlayerProgress(gold: 12400),
          onSettings: () {},
          onHotseat: () {},
        ),
        const Locale('ko'),
      );
      // 골드는 세어 올라간다 (설계서 §13 공통). 끝나면 최종 값이다.
      await tester.pumpAndSettle();
      expect(find.text('12,400'), findsOneWidget);
    });

    testWidgets('조선소가 열리면 자물쇠가 사라진다', (tester) async {
      await _pump(
        tester,
        PortTabs(
          shipyardLocked: false,
          onShipyard: () {},
          onCrew: () {},
          onSail: () {},
          labels: (shipyard: 'A', crew: 'B', sail: 'C'),
        ),
        const Locale('ko'),
      );
      expect(find.image(const AssetImage(PortIcons.lock)), findsNothing);
      expect(find.image(const AssetImage(PortIcons.ship)), findsOneWidget);
    });
  });

  group('설정 화면 (설계서 §13.8, §14.1)', () {
    testWidgets('스위치를 바꾸면 저장소에 남는다', (tester) async {
      final store = await _pump(
        tester,
        const SettingsScreen(),
        const Locale('ko'),
      );
      final l10n = await AppLocalizations.delegate.load(const Locale('ko'));
      await tester.tap(find.text(l10n.soundOn));
      await tester.pump();
      expect(store.sound, isFalse);
      await tester.tap(find.text(l10n.lowEndMode));
      await tester.pump();
      expect(store.lowEnd, isTrue);
      await tester.tap(find.text(l10n.languageEnglish));
      await tester.pump();
      expect(store.language, LanguageChoice.en);
    });
  });
}
