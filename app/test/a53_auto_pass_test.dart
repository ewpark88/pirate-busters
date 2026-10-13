import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pb_ai/pb_ai.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/battle/auto_end.dart';
import 'package:pirate_busters/battle/battle_session.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';
import 'package:pirate_busters/ui/hud/no_shooter_banner.dart';

import 'test_catalog.dart';

/// 사람이 선공인 허수아비전 세션.
BattleSession _humanFirst() {
  for (var seed = 1; ; seed++) {
    final m = testSetup.newMatch(seed);
    if (m.state.activeSide == 0) {
      return BattleSession(
        m,
        humanSides: const {0},
        speciesOf: testCatalog.speciesOf,
        opponent: const AiController(level: AiLevel.easy),
      );
    }
  }
}

/// 내 진영 해적을 [except] 말고 모두 이번 턴에 쏜 것으로 둔다(쏠 해적 없음).
void _restAll(BattleSession s, {int except = -1}) {
  final crew = s.state.sides[0].crew;
  for (var i = 0; i < crew.size; i++) {
    if (i != except) crew.markFired(i);
  }
}

void main() {
  group('A53 쏠 해적 없음 자동 넘김 (설계서 §2.2, ADR-102)', () {
    test('쏠 해적이 없고 움직일 수 없으면 안내 뒤 1초 만에 상대 턴이 된다', () {
      final s = _humanFirst();
      _restAll(s);
      s.state.sides[0].fuel = 0;
      s.update(AutoEndClock.graceMs - 100);
      expect(s.isHumanTurn, isTrue);
      expect(s.autoEnd.noShooter, isTrue);
      s.update(100);
      expect(s.isHumanTurn, isFalse);
      expect(s.autoEnd.noShooter, isFalse, reason: '다음 턴에는 안내를 내린다');
    });

    test('움직일 수 있으면 이동 유예 뒤에 상대 턴이 된다', () {
      final s = _humanFirst();
      _restAll(s);
      s.update(AutoEndClock.graceMs);
      expect(s.isHumanTurn, isTrue, reason: '이동 유예 동안은 내 턴');
      s.update(AutoEndClock.moveGraceMs - AutoEndClock.graceMs);
      expect(s.isHumanTurn, isFalse);
    });

    test('자동 턴 종료 설정을 꺼도 쏠 해적이 없으면 넘어간다', () {
      final s = _humanFirst()..autoEnd.enabled = false;
      _restAll(s);
      s.update(AutoEndClock.moveGraceMs);
      expect(s.isHumanTurn, isFalse);
    });

    test('한 발 쏜 뒤에는 발사 뒤 유예로 끝나고 안내는 없다', () {
      final s = _humanFirst();
      _restAll(s, except: 0);
      s
        ..update(500)
        ..fire(0, 30000, 9000);
      var guard = 0;
      while (s.playback != null && guard++ < 1000) {
        s.update(50);
      }
      expect(s.isHumanTurn, isTrue);
      expect(s.autoEnd.noShooter, isFalse);
      s.update(AutoEndClock.graceMs);
      expect(s.isHumanTurn, isFalse);
    });

    test('쏠 해적이 있으면 안내도 자동 넘김도 없다', () {
      final s = _humanFirst()..update(5000);
      expect(s.isHumanTurn, isTrue);
      expect(s.autoEnd.noShooter, isFalse);
      expect(s.state.sides[0].anyCanFire, isTrue);
    });
  });

  group('A53 안내 배너', () {
    testWidgets('안내 배너는 켜지는 순간부터 정해진 시간 동안 보인다', (tester) async {
      Widget app({required bool active}) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        home: Scaffold(body: NoShooterBanner(active: active)),
      );
      await tester.pumpWidget(app(active: false));
      expect(find.byKey(const ValueKey('noShooterBanner')), findsNothing);
      await tester.pumpWidget(app(active: true));
      await tester.pump();
      expect(find.text('공격할 수 있는 해적이 없습니다. 턴을 상대방에게 넘깁니다'), findsOneWidget);
      await tester.pumpWidget(app(active: false));
      expect(
        find.byKey(const ValueKey('noShooterBanner')),
        findsOneWidget,
        reason: '턴이 넘어가도 읽을 시간을 준다',
      );
      await tester.pump(NoShooterBanner.shown);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('noShooterBanner')), findsNothing);
    });
  });
}
