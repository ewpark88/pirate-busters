import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pb_ai/pb_ai.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/app/app_theme.dart';
import 'package:pirate_busters/battle/battle_session.dart';
import 'package:pirate_busters/game/finale_director.dart';
import 'package:pirate_busters/game/start_gate.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';
import 'package:pirate_busters/settings/language.dart';
import 'package:pirate_busters/ui/hud/battle_banners.dart';

import 'test_catalog.dart';
import 'test_fonts.dart';

BattleSession _session() => BattleSession(
  testSetup.newMatch(3),
  humanSides: const {0},
  speciesOf: testCatalog.speciesOf,
  opponent: const AiController(level: AiLevel.easy),
);

Widget _app(Widget child) => MaterialApp(
  locale: const Locale('ko'),
  supportedLocales: const [Locale('ko'), Locale('en')],
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: Scaffold(body: child),
);

void main() {
  group('A54 턴 전환 멈춤 (설계서 §13.4 턴 전환)', () {
    test('턴이 바뀌면 0.5초 동안 판 시계가 서고 그 뒤 다시 흐른다', () {
      final gate = StartGate();
      for (var i = 0; i < StartGate.steadyFrames; i++) {
        gate.tick(.016);
      }
      expect(gate.tick(.016), isTrue, reason: '열린 문');
      gate.pause(FinaleDirector.turnPauseSec);
      var stopped = 0.0;
      while (!gate.tick(.05)) {
        stopped += .05;
      }
      expect(stopped, closeTo(FinaleDirector.turnPauseSec, .06));
    });
  });

  group('A54 판 끝 배너 (설계서 §10.4 마무리)', () {
    test('끝난 방식마다 배너가 정해지고, 항복은 배너 없이 바로 결과로 간다', () {
      final s = testSetup.newMatch(3).state;
      BattleBannerKind? kind(MatchOutcome o, int winner) {
        s
          ..outcome = o
          ..winner = winner;
        return FinaleDirector.endKindOf(s);
      }

      expect(kind(MatchOutcome.captainLost, 0), BattleBannerKind.captainLost);
      expect(kind(MatchOutcome.annihilation, 0), BattleBannerKind.annihilation);
      expect(kind(MatchOutcome.timeDecision, 0), BattleBannerKind.timeDecision);
      expect(kind(MatchOutcome.timeDecision, -1), BattleBannerKind.draw);
      expect(kind(MatchOutcome.surrender, 1), isNull);
    });

    testWidgets('턴 제한 판정 배너가 뜨고 양쪽 남은 해적 체력을 나란히 보여 준다', (tester) async {
      final session = _session();
      session.state
        ..outcome = MatchOutcome.timeDecision
        ..winner = 0;
      final banner = ValueNotifier<BattleBanner?>(
        const BattleBanner(BattleBannerKind.timeDecision, 1),
      );
      await tester.pumpWidget(
        _app(BattleBanners(session: session, banner: banner, myTurn: true)),
      );
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('턴 제한 판정'), findsOneWidget);
      expect(find.byKey(const ValueKey('end-hp-compare')), findsOneWidget);
      expect(find.text('나 100% : 상대 100%'), findsOneWidget);
    });
  });

  group('A54 턴 배너 (설계서 §13.4 턴 전환)', () {
    testWidgets('‘내 턴!’ 은 잠깐 떴다가 사라지고, 상대 턴에는 상대 턴 패널이 남는다', (
      tester,
    ) async {
      final banner = ValueNotifier<BattleBanner?>(null);
      final session = _session();
      await tester.pumpWidget(
        _app(BattleBanners(session: session, banner: banner, myTurn: true)),
      );
      banner.value = const BattleBanner(BattleBannerKind.myTurn, 1);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('내 턴!'), findsOneWidget);
      await tester.pump(BattleBanners.turnShown);
      await tester.pump();
      expect(find.text('내 턴!'), findsNothing);

      await tester.pumpWidget(
        _app(BattleBanners(session: session, banner: banner, myTurn: false)),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const ValueKey('enemy-turn')), findsOneWidget);
    });
  });

  group('A54 배너 골든 (설계서 §10.4 마무리, §13.4 턴 전환)', () {
    setUpAll(loadAppFonts);
    for (final locale in supportedLocales) {
      for (final (name, kind) in const [
        ('captain', BattleBannerKind.captainLost),
        ('time', BattleBannerKind.timeDecision),
        ('myturn', BattleBannerKind.myTurn),
      ]) {
        testWidgets(
          '배너 골든: ${locale.languageCode} $name',
          (tester) async {
            tester.view.physicalSize = const Size(640, 360) * 2;
            tester.view.devicePixelRatio = 2;
            addTearDown(tester.view.reset);
            final session = _session();
            if (kind == BattleBannerKind.captainLost) {
              session.state
                ..outcome = MatchOutcome.captainLost
                ..winner = 0;
            } else if (kind == BattleBannerKind.timeDecision) {
              session.state
                ..outcome = MatchOutcome.timeDecision
                ..winner = 0;
            }
            final banner = ValueNotifier<BattleBanner?>(null);
            await tester.pumpWidget(
              MaterialApp(
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
                  body: BattleBanners(
                    session: session,
                    banner: banner,
                    myTurn: true,
                  ),
                ),
              ),
            );
            banner.value = BattleBanner(kind, 1);
            await tester.pump(const Duration(milliseconds: 600));
            await expectLater(
              find.byType(BattleBanners),
              matchesGoldenFile(
                'goldens/banner_${name}_${locale.languageCode}.png',
              ),
            );
            await tester.pump(BattleBanners.turnShown);
          },
          skip: !Platform.isWindows,
        );
      }
    }
  });
}
