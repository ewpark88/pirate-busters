import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pirate_busters/app/app_theme.dart';
import 'package:pirate_busters/app/providers.dart';
import 'package:pirate_busters/battle/battle_session.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';
import 'package:pirate_busters/settings/language.dart';
import 'package:pirate_busters/settings/settings_store.dart';
import 'package:pirate_busters/ui/hud/battle_hud.dart';

import 'test_catalog.dart';
import 'test_fonts.dart';

/// 골든은 글꼴 그리기가 OS 마다 달라 만든 환경(Windows)에서만 비교한다.
/// 다시 만들기: `flutter test test/hud_golden_test.dart --update-goldens`.
final bool _skipGolden = !Platform.isWindows;

void main() {
  setUpAll(loadAppFonts);

  // 설계서 §14.4: 두 언어 × 저사양(작은 폰)·고사양(큰 폰) 화면 크기.
  for (final (name, size) in const [
    ('low', Size(640, 360)),
    ('high', Size(1170, 540)),
  ]) {
    for (final locale in supportedLocales) {
      testWidgets(
        '전투 HUD 골든: ${locale.languageCode} $name',
        (tester) async {
          tester.view.physicalSize = size * 2;
          tester.view.devicePixelRatio = 2;
          addTearDown(tester.view.reset);
          final session = BattleSession(
            testSetup.newMatch(3),
            humanSides: const {0, 1},
            speciesOf: testCatalog.speciesOf,
          );
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                settingsStoreProvider.overrideWithValue(MemorySettingsStore()),
              ],
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: appTheme(),
                locale: locale,
                supportedLocales: supportedLocales,
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                home: Scaffold(
                  backgroundColor: const Color(0xFF7FC0EC),
                  body: BattleHud(
                    session: session,
                    overview: ValueNotifier(false),
                    paused: false,
                    onPause: (_) {},
                    onRestart: ({hotseat}) {},
                  ),
                ),
              ),
            ),
          );
          await loadImages(tester);
          await expectLater(
            find.byType(BattleHud),
            matchesGoldenFile('goldens/hud_${locale.languageCode}_$name.png'),
          );
        },
        skip: _skipGolden,
      );
    }
  }
}
