import 'package:pb_sim/pb_sim.dart';
import 'package:test/test.dart';

import 'fixtures.dart';
import 'scenarios.dart';

void main() {
  test('시나리오: 뱃머리 벽을 쏴서 부순다', () {
    final m = startScenario('gun', towerBlueprint());
    final events = runToEnd(
      m,
      shooter((s) {
        final grid = s.sides[1].grid;
        for (var y = 4; y >= 1; y--) {
          if (grid.hasBlock(11, y)) return (11, y);
        }
        return null;
      }),
      passController,
    );
    final grid = m.state.sides[1].grid;
    expect(
      [for (var y = 1; y <= 4; y++) grid.hasBlock(11, y)],
      [
        false,
        false,
        false,
        false,
      ],
    );
    expect(eventsOf(events, SimEventKind.impact, 1), isNotEmpty);
    expect(
      eventsOf(events, SimEventKind.blockDestroyed, 1).length,
      greaterThanOrEqualTo(4),
    );
  });

  test('시나리오: 기둥을 부수면 위의 판이 통째로 무너진다', () {
    final m = startScenario('gun', towerBlueprint());
    final events = runToEnd(
      m,
      shooter(
        (s) => s.sides[1].grid.hasBlock(4, 1) ? (4, 1) : null,
        highArc: true,
      ),
      passController,
    );
    final grid = m.state.sides[1].grid;
    expect(grid.hasBlock(4, 1), isFalse);
    for (var x = 2; x <= 6; x++) {
      expect(grid.hasBlock(x, 3), isFalse, reason: '($x, 3)');
    }
    expect(eventsOf(events, SimEventKind.blockCollapsed, 1), isNotEmpty);
  });

  test('시나리오: 선실을 노려 쏘면 해적이 모두 KO 되어 전멸로 이긴다', () {
    final m = startScenario('killer', sampleBlueprint());
    final events = runToEnd(
      m,
      shooter((s) {
        final enemy = s.sides[1];
        for (var slot = 0; slot < enemy.crew.size; slot++) {
          if (enemy.crew.pirates[slot].status != PirateStatus.aboard) continue;
          final c = enemy.cabins[slot];
          return (c.x, c.y);
        }
        return null;
      }, highArc: true),
      passController,
    );
    expect(m.state.outcome, MatchOutcome.annihilation);
    expect(m.state.winner, 0);
    expect(eventsOf(events, SimEventKind.pirateDown, 1), hasLength(4));
  });

  test('시나리오: 선장실 블록을 부수면 선장실 파괴로 이긴다', () {
    // 해적 피해 없는 탄으로 선장실만 노린다(전멸이 먼저 나지 않게).
    final m = startScenario('sapper', sampleBlueprint());
    final events = runToEnd(
      m,
      shooter((s) {
        for (final mod in s.sides[1].modules.list) {
          if (mod.kind == ModuleKind.captain) return (mod.x, mod.y);
        }
        return null;
      }, highArc: true),
      passController,
    );
    expect(m.state.outcome, MatchOutcome.captainLost);
    expect(m.state.winner, 0);
    expect(m.state.sides[1].captainStanding, isFalse);
    expect(eventsOf(events, SimEventKind.moduleDestroyed, 1), isNotEmpty);
  });
}
