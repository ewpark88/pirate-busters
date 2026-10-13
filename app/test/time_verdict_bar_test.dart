import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/battle/battle_session.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';
import 'package:pirate_busters/ui/hud/time_verdict_bar.dart';

import 'test_catalog.dart';

Widget _app(Widget child) => MaterialApp(
  locale: const Locale('ko'),
  supportedLocales: const [Locale('ko'), Locale('en')],
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: Scaffold(body: Center(child: child)),
);

/// 턴만 넘겨 남은 턴이 [left] 가 되게 한 세션 (사람 = 0번).
BattleSession _sessionAt(int left) {
  final m = testSetup.newMatch(3);
  while (TimeVerdictBar.turnsLeft(m.state) > left && !m.state.isOver) {
    m.apply(const EndTurnCommand(t: 10));
  }
  return BattleSession(
    m,
    humanSides: const {0},
    speciesOf: testCatalog.speciesOf,
  );
}

void main() {
  group('턴 제한 안내 띠 (설계서 §2.7·§13.4)', () {
    test('남은 턴이 10 이하일 때만 보인다', () {
      expect(TimeVerdictBar.shows(_sessionAt(11).state), isFalse);
      expect(TimeVerdictBar.shows(_sessionAt(10).state), isTrue);
      expect(TimeVerdictBar.shows(_sessionAt(1).state), isTrue);
    });

    testWidgets('남은 턴과 양쪽 남은 해적 체력 비율을 함께 보여 준다', (tester) async {
      final s = _sessionAt(4);
      final foe = s.state.sides[1].crew;
      final dmg = foe.pirates[0].hp ~/ 2;
      foe.damage(0, dmg, 1, s.state.events);
      final theirs = (foe.hpStart - dmg) * 100 ~/ foe.hpStart;
      await tester.pumpWidget(_app(TimeVerdictBar(session: s)));
      expect(find.text('턴 제한까지 4턴 · 해적 체력 많은 쪽 승리'), findsOneWidget);
      expect(find.text('나 100% : 상대 $theirs%'), findsOneWidget);
    });

    testWidgets('판 초반에는 아무것도 그리지 않는다', (tester) async {
      await tester.pumpWidget(_app(TimeVerdictBar(session: _sessionAt(20))));
      expect(find.byKey(const ValueKey('time-verdict')), findsNothing);
    });
  });
}
