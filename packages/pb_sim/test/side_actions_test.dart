import 'package:pb_sim/pb_sim.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  test('판 시작에는 쏠 해적이 있고 이동할 수 있다', () {
    final side = newSampleMatch(1).state.sides[0];
    expect(side.anyCanFire, isTrue);
    expect(side.canMove, isTrue);
  });

  test('모든 해적이 쉬는 턴이면 쏠 해적이 없다', () {
    final side = newSampleMatch(1).state.sides[0];
    for (final p in side.crew.pirates) {
      p.cooldown = 2;
    }
    expect(side.anyCanFire, isFalse);
    side.crew.pirates.last.cooldown = 0;
    expect(side.anyCanFire, isTrue);
  });

  test('연료가 없거나 이번 턴에 묶이면 이동할 수 없다', () {
    final side = newSampleMatch(1).state.sides[0]..fuel = 0;
    expect(side.canMove, isFalse);
    side
      ..fuel = 100
      ..status.moveLockTurn = side.turnNow;
    expect(side.canMove, isFalse);
  });
}
