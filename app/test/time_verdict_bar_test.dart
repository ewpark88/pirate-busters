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
  group('시간 판정 안내 띠 (설계서 §13.4, ADR-090)', () {
    test('남은 턴이 10 이하일 때만 보인다', () {
      expect(TimeVerdictBar.shows(_sessionAt(11).state), isFalse);
      expect(TimeVerdictBar.shows(_sessionAt(10).state), isTrue);
      expect(TimeVerdictBar.shows(_sessionAt(1).state), isTrue);
    });

    testWidgets('남은 턴과 양쪽 침수량을 함께 보여 준다', (tester) async {
      final s = _sessionAt(4);
      s.state.sides[1].flood = 123;
      await tester.pumpWidget(_app(TimeVerdictBar(session: s)));
      expect(find.text('시간 판정까지 4턴 · 침수 적은 쪽 승리'), findsOneWidget);
      expect(find.text('나 0.0% : 상대 12.3%'), findsOneWidget);
    });

    testWidgets('판 초반에는 아무것도 그리지 않는다', (tester) async {
      await tester.pumpWidget(_app(TimeVerdictBar(session: _sessionAt(20))));
      expect(find.byKey(const ValueKey('time-verdict')), findsNothing);
    });
  });
}
