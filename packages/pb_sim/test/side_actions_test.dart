import 'package:pb_sim/pb_sim.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  test('판 시작에는 쏠 해적이 있고 이동할 수 있다', () {
    final side = newSampleMatch(1).state.sides[0];
    expect(side.anyCanFire, isTrue);
    expect(side.canMove, isTrue);
  });

  test('모든 해적이 KO 면 쏠 해적이 없다', () {
    final m = newSampleMatch(1);
    final side = m.state.sides[0];
    for (var slot = 0; slot < side.crew.size - 1; slot++) {
      side.crew.damage(slot, 9999, 0, m.state.events);
    }
    expect(side.anyCanFire, isTrue);
    side.crew.damage(side.crew.size - 1, 9999, 0, m.state.events);
    expect(side.anyCanFire, isFalse);
  });

  test('연료가 없으면 이동할 수 없다', () {
    final side = newSampleMatch(1).state.sides[0]..fuel = 0;
    expect(side.canMove, isFalse);
    side.fuel = 100;
    expect(side.canMove, isTrue);
  });
}
