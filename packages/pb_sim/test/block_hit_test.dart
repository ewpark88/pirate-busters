import 'package:pb_sim/pb_sim.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

/// [hp] 에 이벤트를 차례로 더한다: 화면이 착탄 순간마다 하는 일 (A33).
void _apply(List<List<int>> hp, List<SimEvent> events) {
  for (final e in events) {
    switch (e.kind) {
      case SimEventKind.blockHit:
        hp[e.side][e.cell] = e.y;
      case SimEventKind.blockDestroyed || SimEventKind.blockCollapsed:
        hp[e.side][e.cell] = 0;
      case SimEventKind.repaired:
        hp[e.side][e.cell] = e.y;
      case _:
        break;
    }
  }
}

void main() {
  test('턴마다 이벤트로 되짚은 칸 내구도가 실제 격자와 같다', () {
    for (final seed in [20260929, 7, 42]) {
      final m = newSampleMatch(seed);
      var hits = 0;
      for (var i = 0; i < 30 && !m.isOver; i++) {
        final s = m.state;
        final hp = [for (final side in s.sides) List.of(side.grid.rawHp)];
        final c = RandomController(s.activeSide == 0 ? 7 : 8);
        m.playTurn(c.turnFor(s));
        _apply(hp, s.events);
        hits += s.events.where((e) => e.kind == SimEventKind.blockHit).length;
        for (var side = 0; side < 2; side++) {
          final grid = s.sides[side].grid;
          for (var cell = 0; cell < grid.cellCount; cell++) {
            final want = grid.hasBlockAt(cell) ? grid.rawHp[cell] : 0;
            expect(hp[side][cell], want, reason: 'seed $seed 턴 $i 칸 $cell');
          }
        }
      }
      expect(hits, greaterThan(0));
    }
  });

  test('blockHit 의 깎인 양은 맞기 전 내구도를 넘지 않는다', () {
    final m = newSampleMatch(20260929);
    for (var i = 0; i < 30 && !m.isOver; i++) {
      final s = m.state;
      final before = [for (final side in s.sides) List.of(side.grid.rawHp)];
      final c = RandomController(s.activeSide == 0 ? 7 : 8);
      m.playTurn(c.turnFor(s));
      for (final e in s.events.where((e) => e.kind == SimEventKind.blockHit)) {
        expect(e.value, greaterThan(0));
        expect(e.y, greaterThanOrEqualTo(0));
        expect(e.value + e.y, lessThanOrEqualTo(before[e.side][e.cell]));
        before[e.side][e.cell] = e.y;
      }
    }
  });
}
