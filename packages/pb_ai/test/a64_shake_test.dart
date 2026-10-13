import 'package:pb_ai/pb_ai.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

/// A64 강습 체류 (설계서 §2.3, ADR-110): 내 배에 상대 강습 해적이 서 있으면 AI 는
/// 배를 흔들어 떨어뜨린다. 사람과 같은 MOVE 만 낸다(절대 규칙 4).
void main() {
  test('내 배에 상대 강습 해적이 서 있으면 보통 이상 AI 는 1칸 이상 움직여 흔든다', () {
    for (final level in [AiLevel.normal, AiLevel.hard, AiLevel.hell]) {
      final m = newMatch(7)..apply(const MoveCommand(t: 0, dx: 0));
      final me = m.state.sides[m.state.activeSide];
      final foe = m.state.sides[1 - m.state.activeSide].crew;
      foe.pirates[0]
        ..status = PirateStatus.boarding
        ..boardCell = deckCellAt(me.grid, me.grid.width ~/ 2);
      me.crew.foe = foe;
      final bundle = AiController(level: level).turnFor(m.state);
      final moves = bundle.commands.whereType<MoveCommand>();
      expect(moves, isNotEmpty, reason: '$level');
      expect(
        moves.first.dx.abs() * 100,
        greaterThanOrEqualTo(shakeOffDistance),
        reason: '$level: dx 는 1/10칸',
      );
    }
  });
}
