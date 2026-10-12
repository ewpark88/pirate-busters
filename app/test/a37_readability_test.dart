import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pb_ai/pb_ai.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/battle/battle_session.dart';
import 'package:pirate_busters/battle/playback.dart';
import 'package:pirate_busters/game/coords.dart';
import 'package:pirate_busters/game/view/last_impact_mark.dart';
import 'package:pirate_busters/game/view/rarity_painter.dart';
import 'package:pirate_busters/ui/cards/rarity_stars.dart';

import 'test_catalog.dart';

/// 사람이 선공인 시드의 AI 대전 세션.
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

/// [s] 를 [mark] 와 함께 [ms] 만큼 50ms 씩 돌린다.
void _run(BattleSession s, LastImpactMark mark, int ms) {
  for (var t = 0; t < ms; t += 50) {
    s.update(50);
    mark.update(.05);
  }
}

void main() {
  group('등급 별 표식 (설계서 §10.5, A37)', () {
    test('별 수는 일반 1 부터 신화 5 까지 카드 프레임과 같다', () {
      expect(
        [for (final r in Rarity.values) RarityPainter.starsOf(r.index)],
        [1, 2, 3, 4, 5],
      );
    });

    testWidgets('HUD 카드용 별 줄은 등급만큼 넓어진다', (tester) async {
      Future<double> width(Rarity r) async {
        await tester.pumpWidget(
          Center(child: RarityStars(rarity: r)),
        );
        return tester.getSize(find.byType(CustomPaint).last).width;
      }

      expect(await width(Rarity.legend), greaterThan(await width(Rarity.rare)));
    });
  });

  group('직전 착탄 표시 (설계서 §2.2, A37)', () {
    test('내가 쏜 탄의 착탄 자리를 기억해 다음 내 턴에 보이고, 상대 턴에는 숨긴다', () {
      final s = _humanFirst();
      final mark = LastImpactMark(session: s);
      _run(s, mark, 500);
      expect(mark.shown, isNull, reason: '아직 쏜 적이 없다');
      s.fire(0, 30000, 9000);
      final shot = s.playback! as ShotPlayback;
      mark.update(0);
      final t = shot.traces.first;
      expect(mark.lastOf(0), Coords.point(t.xs.last, t.ys.last));
      expect(mark.shown, isNull, reason: '내 탄이 나는 동안은 숨긴다');
      // 턴을 넘겨 상대 턴: 내 착탄은 보이지 않는다.
      _run(s, mark, 6000);
      s.endTurn();
      var guard = 0;
      while (!s.isHumanTurn && !s.isOver && guard++ < 3000) {
        _run(s, mark, 50);
        if (!s.isHumanTurn) expect(mark.shown, isNull);
      }
      if (s.isOver) return;
      expect(mark.shown, mark.lastOf(0), reason: '다음 내 턴에 다시 보인다');
      expect(mark.lastOf(1), isNull, reason: 'AI 착탄은 남기지 않는다');
    });
  });
}
