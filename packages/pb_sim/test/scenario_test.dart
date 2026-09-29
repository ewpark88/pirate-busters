import 'package:pb_sim/pb_sim.dart';
import 'package:test/test.dart';

import 'aim.dart';
import 'fixtures.dart';

/// 판이 끝날 때까지 턴을 두며 모든 턴의 이벤트를 모은다.
List<SimEvent> _run(Match m, Controller left, Controller right) {
  final all = <SimEvent>[];
  while (!m.isOver) {
    final s = m.state;
    m.playTurn((s.activeSide == 0 ? left : right).turnFor(s));
    all.addAll(s.events);
  }
  return all;
}

Iterable<SimEvent> _of(List<SimEvent> events, SimEventKind kind, int side) =>
    events.where((e) => e.kind == kind && e.side == side);

/// 쏠 수 있는 해적 2명까지 [target] 이 고른 칸을 노린다. 노릴 칸이 없으면 턴을 넘긴다.
Controller _shooter(
  (int, int)? Function(MatchState s) target, {
  bool highArc = false,
}) => FnController((s) {
  final crew = s.sides[s.activeSide].crew;
  final cell = target(s);
  final out = <Command>[];
  for (var slot = 0; slot < crew.size && cell != null; slot++) {
    if (!crew.canFire(slot) || out.length == 2) continue;
    out.add(
      aimAt(
        s,
        slot: slot,
        tx: cell.$1,
        ty: cell.$2,
        t: 1000 + out.length * 1000,
        highArc: highArc,
      ),
    );
  }
  return [...out, const EndTurnCommand(t: 9000)];
});

/// 오른쪽 배: 용골 + 뱃머리 쪽(x = 11) 벽 + (4, 1..2) 기둥 위 (2..6, 3) 판.
Blueprint _towerBlueprint() => Blueprint(
  HullSpec.sloop,
  [
    for (var x = 0; x < 12; x++) BlockCell(x, 0, BlockMaterial.oak),
    for (var y = 1; y <= 2; y++) BlockCell(4, y, BlockMaterial.pine),
    for (var x = 2; x <= 6; x++) BlockCell(x, 3, BlockMaterial.pine),
    for (var y = 1; y <= 4; y++) BlockCell(11, y, BlockMaterial.oak),
  ],
  cabins: const [
    CabinCell(7, 0),
    CabinCell(8, 0),
    CabinCell(9, 0),
    CabinCell(10, 0),
  ],
);

final PirateCatalog _catalog = PirateCatalog([
  for (var i = 0; i < 4; i++) testPirate('gun$i', blockDamage: 100),
  for (var i = 0; i < 4; i++) testPirate('killer$i', pirateDamage: 1000),
  for (var i = 0; i < 4; i++)
    testPirate('wrecker$i', blockDamage: 1000, blastRadius: 3),
  for (var i = 0; i < 4; i++) testPirate('r$i'),
]);

Match _start(String kind, Blueprint right) => Match.start(
  seed: 11,
  blueprints: [sampleBlueprint(), right],
  decks: [
    [for (var i = 0; i < 4; i++) '$kind$i'],
    [for (var i = 0; i < 4; i++) 'r$i'],
  ],
  costLimits: const [15, 15],
  pirates: _catalog,
);

void main() {
  test('시나리오: 뱃머리 벽을 쏴서 부순다', () {
    final m = _start('gun', _towerBlueprint());
    final events = _run(
      m,
      _shooter((s) {
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
    expect(_of(events, SimEventKind.impact, 1), isNotEmpty);
    expect(
      _of(events, SimEventKind.blockDestroyed, 1).length,
      greaterThanOrEqualTo(4),
    );
  });

  test('시나리오: 기둥을 부수면 위의 판이 통째로 무너진다', () {
    final m = _start('gun', _towerBlueprint());
    final events = _run(
      m,
      _shooter(
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
    expect(_of(events, SimEventKind.blockCollapsed, 1), isNotEmpty);
  });

  test('시나리오: 선실을 노려 쏘면 해적이 모두 KO 되어 전멸로 이긴다', () {
    final m = _start('killer', sampleBlueprint());
    final events = _run(
      m,
      _shooter((s) {
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
    expect(_of(events, SimEventKind.pirateDown, 1), hasLength(4));
  });

  test('시나리오: 선체 내구도를 20% 미만으로 만들면 격침으로 이긴다', () {
    final m = _start('wrecker', sampleBlueprint());
    _run(
      m,
      _shooter((s) {
        final grid = s.sides[1].grid;
        for (var y = 0; y < grid.height; y++) {
          for (var x = 0; x < grid.width; x++) {
            if (grid.hasBlock(x, y)) return (x, y);
          }
        }
        return null;
      }),
      passController,
    );
    final grid = m.state.sides[1].grid;
    expect(m.state.outcome, MatchOutcome.sunk);
    expect(m.state.winner, 0);
    expect(grid.totalHp * 100, lessThan(grid.initialTotalHp * 20));
  });
}
