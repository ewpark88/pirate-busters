import 'package:pb_sim/pb_sim.dart';
import 'package:test/test.dart';

import 'aim.dart';
import 'fixtures.dart';

/// 판을 [ticks] 틱 돌리며 나온 이벤트를 모두 모은다. [commandsAt] 이 틱마다 커맨드를 낸다.
List<SimEvent> _run(
  Match m,
  int ticks, [
  List<Command> Function(Match m)? commandsAt,
]) {
  final all = <SimEvent>[];
  for (var i = 0; i < ticks && !m.isOver; i++) {
    m.step(commandsAt?.call(m) ?? const []);
    all.addAll(m.state.events);
  }
  return all;
}

Iterable<SimEvent> _of(List<SimEvent> events, SimEventKind kind, int side) =>
    events.where((e) => e.kind == kind && e.side == side);

/// 오른쪽 배: 용골 + 뱃머리 쪽(x = 0) 벽 + (4, 1..2) 기둥 위 (2..6, 3) 망루 판.
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

Match _versusTower({required List<String> rightDeck}) => Match.start(
  seed: 11,
  blueprints: [sampleBlueprint(), _towerBlueprint()],
  decks: [
    ['p01', 'p06', 'p11', 'p16'],
    rightDeck,
  ],
  pirates: PirateCatalog([
    testPirate('p01', blockDamage: 100),
    testPirate('p06', blockDamage: 100),
    testPirate('p11', blockDamage: 100),
    testPirate('p16', blockDamage: 100),
    testPirate('gunner', pirateDamage: 1000, blockDamage: 50),
    testPirate('r1'),
    testPirate('r2'),
    testPirate('r3'),
    testPirate('r4'),
    testPirate('r5'),
  ]),
);

void main() {
  test('시나리오: 뱃머리 벽을 쏴서 부순다', () {
    final m = _versusTower(rightDeck: ['r1', 'r2', 'r3', 'r4']);
    final events = _run(m, 900, (m) {
      final grid = m.state.sides[1].grid;
      for (var y = 4; y >= 1; y--) {
        if (grid.hasBlock(11, y) && m.state.sides[0].crew.canFire(0)) {
          return [aimAt(m, side: 0, slot: 0, tx: 11, ty: y)];
        }
      }
      return const [];
    });
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
    final m = _versusTower(rightDeck: ['r1', 'r2', 'r3', 'r4']);
    final events = _run(m, 900, (m) {
      final grid = m.state.sides[1].grid;
      if (!grid.hasBlock(4, 1) || !m.state.sides[0].crew.canFire(1)) {
        return const [];
      }
      return [aimAt(m, side: 0, slot: 1, tx: 4, ty: 1, highArc: true)];
    });
    final grid = m.state.sides[1].grid;
    expect(grid.hasBlock(4, 1), isFalse);
    for (var x = 2; x <= 6; x++) {
      expect(grid.hasBlock(x, 3), isFalse, reason: '($x, 3)');
    }
    expect(_of(events, SimEventKind.blockCollapsed, 1), isNotEmpty);
    expect(grid.blockCount, lessThan(12 + 2 + 5 + 4));
  });

  test('시나리오: 선실을 노려 쏘면 교대 해적까지 모두 쓰러져 전멸로 이긴다', () {
    final m = Match.start(
      seed: 12,
      blueprints: [sampleBlueprint(), sampleBlueprint()],
      decks: [
        ['gunner', 'gunner', 'gunner', 'gunner'],
        ['r1', 'r2', 'r3', 'r4', 'r5'],
      ],
      pirates: PirateCatalog([
        testPirate('gunner', pirateDamage: 1000),
        for (var i = 1; i <= 5; i++) testPirate('r$i'),
      ]),
    );
    final events = _run(m, matchDurationTicks, (m) {
      final me = m.state.sides[0];
      final enemy = m.state.sides[1];
      for (var slot = 0; slot < 4; slot++) {
        if (!me.crew.canFire(slot)) continue;
        for (var t = 0; t < 4; t++) {
          if (enemy.crew.pirateAt(t)?.status != PirateStatus.aboard) continue;
          final c = enemy.cabins[t];
          return [
            aimAt(m, side: 0, slot: slot, tx: c.x, ty: c.y, highArc: true),
          ];
        }
      }
      return const [];
    });
    expect(m.state.outcome, MatchOutcome.annihilation);
    expect(m.state.winner, 0);
    expect(m.state.sides[1].crew.allDown, isTrue);
    expect(_of(events, SimEventKind.pirateBoarded, 1), isNotEmpty);
    expect(_of(events, SimEventKind.pirateDown, 1), hasLength(5));
  });

  group('시나리오: 적 발사를 보고 후퇴하면 투척 탄을 피한다 (설계서 §2.6)', () {
    List<SimEvent> run({required bool dodge}) {
      final m = newSampleMatch(21);
      final shot = aimAt(m, side: 1, slot: 0, tx: 11, ty: 1, highArc: true);
      return _run(m, 150, (m) {
        final t = m.state.tick;
        return [
          if (t == 0) shot,
          if (dodge && t == 0) const MoveCommand(tick: 0, side: 0, dir: -1),
        ];
      });
    }

    test('가만히 있으면 뱃머리에 맞는다', () {
      final events = run(dodge: false);
      expect(_of(events, SimEventKind.impact, 0), hasLength(1));
    });

    test('바로 후퇴하면 탄이 바다에 떨어진다', () {
      final events = run(dodge: true);
      expect(_of(events, SimEventKind.impact, 0), isEmpty);
      expect(_of(events, SimEventKind.splash, 0), hasLength(1));
    });
  });
}
