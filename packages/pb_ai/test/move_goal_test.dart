import 'package:pb_ai/pb_ai.dart';
import 'package:pb_ai/src/move_goal.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

/// 첫 턴 배가 가장 거친 구간(세기 3)에 서 있는 판.
Match _roughStart() {
  for (var seed = 1; seed < 200; seed++) {
    final m = newMatch(seed);
    if (waveLevelOf(m.state, m.state.activeSide) == 3) return m;
  }
  throw StateError('거친 구간에서 시작하는 판이 없다');
}

void main() {
  group('이동 목표 (설계서 §5.5, S5 준비)', () {
    test('갈 수 있는 자리 중 더 잔잔한 곳을 목표로 고르고, 배 위치는 그대로 둔다', () {
      final m = _roughStart();
      final s = m.state;
      final side = s.activeSide;
      final before = hashMatchState(s);
      final goal = MoveGoal.calmTarget(s, side);
      expect(hashMatchState(s), before);
      expect(goal, isNot(s.sides[side].offset));
      final now = s.sides[side].offset;
      s.sides[side].offset = goal;
      expect(waveLevelOf(s, side), lessThan(3));
      s.sides[side].offset = now;
    });

    test('목표 쪽으로 다가가면 점수가 오르고 멀어지면 내려간다', () {
      const now = 0;
      const goal = 5 * cellUnit;
      expect(MoveGoal.progressScore(now, cellUnit, goal), greaterThan(0));
      expect(MoveGoal.progressScore(now, -cellUnit, goal), lessThan(0));
      expect(MoveGoal.progressScore(now, now, goal), 0);
    });

    test('어려움 AI 는 거친 구간에서 잔잔한 목표 쪽으로 움직인다', () {
      final m = _roughStart();
      final s = m.state;
      final side = s.activeSide;
      final now = s.sides[side].offset;
      final goal = MoveGoal.calmTarget(s, side);
      final bundle = const AiController(level: AiLevel.hard).turnFor(s);
      final move = bundle.commands.whereType<MoveCommand>().toList();
      expect(move, isNotEmpty);
      expect(move.first.dx.sign, (goal - now).sign);
    });

    test('목표 후보 실험을 켜면 목표 자리가 위치 후보에 들어간다', () {
      final m = _roughStart();
      final s = m.state;
      final dials = AiDials.of(AiLevel.hard).copyWith(goalMoves: true);
      final bundle = AiController(level: AiLevel.hard, dials: dials).turnFor(s);
      final dx = bundle.commands.whereType<MoveCommand>().fold(
        0,
        (a, c) => a + c.dx,
      );
      expect(dx, isNot(0));
    });
  });
}
