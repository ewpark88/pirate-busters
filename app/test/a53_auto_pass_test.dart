import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pb_ai/pb_ai.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/battle/auto_end.dart';
import 'package:pirate_busters/battle/battle_session.dart';
import 'package:pirate_busters/battle/rest_turns.dart';
import 'package:pirate_busters/game/battle_texts.dart';
import 'package:pirate_busters/game/view/rest_badge.dart';
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

/// 내 진영 해적을 [except] 말고 모두 쉬게 한다.
void _restAll(BattleSession s, {int except = -1}) {
  final pirates = s.state.sides[0].crew.pirates;
  for (var i = 0; i < pirates.length; i++) {
    if (i != except) pirates[i].cooldown = 2;
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

    test('한 발 쏜 뒤 더 쏠 해적이 없으면 2발 뒤와 같은 유예로 끝나고 안내는 없다', () {
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

  group('A53 머리 위 쉬는 턴 배지 (설계서 §13.4, ADR-102)', () {
    test('머리 위 숫자는 카드와 같은 쉬는 턴 수이고, 쏜 해적은 이번 턴을 빼고 센다', () {
      final s = _humanFirst();
      final side = s.state.sides[0];
      side.crew.pirates[1].cooldown = 2;
      final badges = RestBadges(session: s, ships: const [], texts: _Texts())
        ..update(0.016);
      expect(badges.shownOf(0, 1), 2);
      expect(badges.shownOf(0, 1), restTurnsOf(side, 1));
      expect(badges.shownOf(0, 0), 0);
      side.crew.markFired(0);
      badges.update(0.016);
      expect(badges.shownOf(0, 0), restTurnsOf(side, 0));
    });

    test('쉬는 턴이 풀리면 그 진영 턴 시작에 준비 표시가 나온다', () {
      final s = _humanFirst();
      s.state.sides[0].crew.pirates[0].cooldown = 1;
      final badges = RestBadges(session: s, ships: const [], texts: _Texts())
        ..update(0.016);
      expect(badges.shownOf(0, 0), 1);
      s.endTurn();
      badges.update(0.016);
      expect(badges.shownOf(0, 0), 0);
      expect(badges.readyOf(0, 0), isFalse, reason: '상대 턴에는 아직');
      var guard = 0;
      while (!s.isHumanTurn && !s.isOver && guard++ < 4000) {
        s.update(100);
        badges.update(0.1);
      }
      while (s.playback != null && guard++ < 6000) {
        s.update(50);
        badges.update(0.05);
      }
      badges.update(0.016);
      expect(badges.readyOf(0, 0), isTrue);
      badges.update(RestBadges.readyTime);
      expect(badges.readyOf(0, 0), isFalse);
    });

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

class _Texts with BattleTexts {}
