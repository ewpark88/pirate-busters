import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/battle/battle_session.dart';
import 'package:pirate_busters/game/shooter_tracker.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';
import 'package:pirate_busters/ui/hud/pirate_cards.dart';
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

/// 사람(0번)이 선공인 세션. [left] 를 주면 남은 턴이 그만큼 될 때까지 넘긴다.
BattleSession _session({int? left}) {
  for (var seed = 1; ; seed++) {
    final m = testSetup.newMatch(seed);
    if (m.state.activeSide != 0) continue;
    if (left != null) {
      while (TimeVerdictBar.turnsLeft(m.state) > left) {
        m.apply(const EndTurnCommand(t: 10));
      }
      if (m.state.activeSide != 0) continue;
    }
    return BattleSession(
      m,
      humanSides: const {0},
      speciesOf: testCatalog.speciesOf,
    );
  }
}

void main() {
  group('A39 점검 후속 (A41, ADR-092)', () {
    testWidgets('체력 비율이 같으면 띠가 선장실 비교라고 알리고, 판정 기준으로 색을 정한다', (
      tester,
    ) async {
      final s = _session(left: 4);
      final foe = s.state.sides[1];
      final captain = foe.modules.list.firstWhere(
        (m) => m.kind == ModuleKind.captain,
      );
      foe.grid.damage(captain.x, captain.y, 1);
      await tester.pumpWidget(_app(TimeVerdictBar(session: s)));
      final text = find.textContaining('선장실 비교');
      expect(text, findsOneWidget);
      expect(
        tester.widget<Text>(text).style!.color,
        isNot(const Color(0xFFE06A5A)),
        reason: '상대 선장실이 더 깎였으니 내가 앞서 빨강이 아니다',
      );
    });

    testWidgets('쏜 직후 카드는 ‘쉬는 턴’ 대신 ‘발사 완료’를 보여 준다', (tester) async {
      final s = _session()..update(100);
      s.state.sides[0].crew.markFired(0);
      await tester.pumpWidget(_app(PirateCards(session: s, side: 0)));
      expect(find.text('발사 완료'), findsOneWidget);
      expect(find.textContaining('쉬는 턴'), findsNothing);
    });

    test('쓰러진 해적을 골라도 카메라가 줌인하지 않는다', () {
      final s = _session()
        ..update(100)
        ..select(0);
      expect(s.focusSlot, 0);
      s.state.sides[0].crew.pirates[0].status = PirateStatus.down;
      expect(s.focusSlot, isNull);
    });

    test('착탄 프레임에 연출이 끝나도 그 묶음을 낸 해적을 안다 (A41 점검)', () {
      // 블록을 안 부순 탄은 마지막 착탄과 같은 프레임에 playback 이 빈다.
      var caught = 0;
      for (var angle = 10000; angle <= 80000; angle += 5000) {
        for (var power = 4000; power <= 10000; power += 1000) {
          final s = _session()..update(100);
          final tracker = ShooterTracker();
          final slot = [
            for (var i = 0; i < s.state.sides[0].crew.size; i++)
              if (s.canFire(i)) i,
          ].first;
          s.fire(slot, angle, power);
          var guard = 0;
          while (s.playback != null && guard++ < 3000) {
            s.update(16);
            final hit = s.takeCues().any(
              (e) => e.kind == SimEventKind.impact,
            );
            final shooter = tracker.take(s);
            if (!hit) continue;
            expect(shooter, isNotNull, reason: '$angle $power');
            if (s.playback == null) caught++;
          }
        }
      }
      expect(caught, greaterThan(0), reason: '같은 프레임에 끝나는 착탄이 있어야 한다');
    });
  });
}
