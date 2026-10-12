import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pb_ai/pb_ai.dart';
import 'package:pirate_busters/battle/battle_session.dart';
import 'package:pirate_busters/battle/playback.dart';
import 'package:pirate_busters/game/countdown_cue.dart';
import 'package:pirate_busters/game/view/foe_aim_mark.dart';
import 'package:pirate_busters/ui/hud/foe_alert.dart';
import 'package:pirate_busters/ui/hud/hud_style.dart';
import 'package:pirate_busters/ui/hud/turn_timer.dart';

import 'test_catalog.dart';

/// AI 가 선공인 시드로 세션을 만든다.
BattleSession _aiFirst({bool hotseat = false}) {
  for (var seed = 1; ; seed++) {
    final m = testSetup.newMatch(seed);
    if (m.state.activeSide == 1) {
      return BattleSession(
        m,
        humanSides: hotseat ? const {0, 1} : const {0},
        speciesOf: testCatalog.speciesOf,
        opponent: hotseat ? null : const AiController(level: AiLevel.easy),
      );
    }
  }
}

void main() {
  group('남은 5초 째깍 (설계서 §2.3, A34)', () {
    test('내 턴 5·4·3·2·1 초에 한 번씩만 낸다', () {
      int? last;
      final ticks = <int>[];
      for (var ms = 7000; ms > 0; ms -= 100) {
        final s = CountdownCue.due(ms, last, myTurn: true, running: true);
        if (s != null) {
          ticks.add(s);
          last = s;
        }
      }
      expect(ticks, [5, 4, 3, 2, 1]);
    });

    test('상대 턴이나 탄 연출로 시간이 멈춘 동안은 내지 않는다', () {
      expect(CountdownCue.due(3000, null, myTurn: false, running: true), null);
      expect(CountdownCue.due(3000, null, myTurn: true, running: false), null);
      expect(CountdownCue.due(9000, null, myTurn: true, running: true), null);
    });
  });

  group('턴 타이머 맥박 (설계서 §2.3·§13.4, A34)', () {
    Future<void> pump(WidgetTester tester, Widget w) => tester.pumpWidget(
      MaterialApp(home: Center(child: w)),
    );

    testWidgets('5초부터 빨갛게 튀고, 그 전에는 튀지 않는다', (tester) async {
      await pump(tester, const TurnTimer(seconds: 8, pulse: true));
      expect(find.byType(Transform), findsNothing);
      expect(
        tester.widget<Text>(find.text('8')).style!.color,
        HudColors.warn,
      );

      await pump(tester, const TurnTimer(seconds: 4, pulse: true));
      final scale = tester.widget<Transform>(find.byType(Transform).first);
      expect(scale.transform.getMaxScaleOnAxis(), greaterThan(1.3));
      await tester.pump(TurnTimer.popTime);
      final settled = tester.widget<Transform>(find.byType(Transform).first);
      expect(settled.transform.getMaxScaleOnAxis(), closeTo(1, 1e-6));
      expect(
        tester.widget<Text>(find.text('4')).style!.color,
        HudColors.danger,
      );
    });

    testWidgets('흔들림 줄이기면 튀지 않는다 (설계서 §13.8)', (tester) async {
      await pump(tester, const TurnTimer(seconds: 3, pulse: true, calm: true));
      final t = tester.widget<Transform>(find.byType(Transform).first);
      expect(t.transform.getMaxScaleOnAxis(), closeTo(1, 1e-6));
    });
  });

  group('상대 턴 읽기 (설계서 §2.3, A34)', () {
    test('상대가 조준하면 그 해적을 강조하고, 쏘면 잠깐 날아옴 경고를 띄운다', () {
      final s = _aiFirst();
      final mark = FoeAimMark(session: s, ships: const []);
      final seen = <FoeAlertKind>{};
      var aimedSlot = -1;
      var guard = 0;
      while (!s.isHumanTurn && !s.isOver && guard++ < 3000) {
        s.update(50);
        final kind = FoeAlert.kindOf(s);
        if (kind != null) seen.add(kind);
        if (kind == FoeAlertKind.aiming) {
          expect(mark.target, (1, s.opponentAim!.slot));
          aimedSlot = s.opponentAim!.slot;
        }
        final p = s.playback;
        if (kind == FoeAlertKind.incoming) {
          expect(p, isA<ShotPlayback>());
          expect((p! as ShotPlayback).elapsedMs, lessThan(FoeAlert.incomingMs));
        }
        if (p is ShotPlayback && p.elapsedMs >= FoeAlert.incomingMs) {
          expect(kind, isNot(FoeAlertKind.incoming));
        }
      }
      expect(aimedSlot, greaterThanOrEqualTo(0));
      expect(seen, containsAll(FoeAlertKind.values));
      expect(FoeAlert.kindOf(s), isNull, reason: '내 턴에는 띄우지 않는다');
      expect(mark.target, isNull);
    });

    test('둘이서 하면 상대 턴 알림이 없다', () {
      final s = _aiFirst(hotseat: true)..update(3000);
      expect(FoeAlert.kindOf(s), isNull);
    });

    test('조준 고리는 조준이 진행될수록 좁혀 든다', () {
      expect(
        FoeAimMark.ringRadius(1),
        lessThan(FoeAimMark.ringRadius(0)),
      );
    });
  });
}
