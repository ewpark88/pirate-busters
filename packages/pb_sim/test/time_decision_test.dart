import 'package:pb_sim/pb_sim.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

/// 용골 한 줄(참나무 12칸, 내구도 960)에 선실 4개인 작은 배.
Blueprint _keelOnly() => Blueprint(
  boxSloop,
  [for (var x = 0; x < 12; x++) BlockCell(x, 0, BlockMaterial.oak)],
  cabins: const [
    CabinCell(3, 0),
    CabinCell(5, 0),
    CabinCell(6, 0),
    CabinCell(8, 0),
  ],
  modules: const [ModuleCell(0, 0, ModuleKind.captain)],
);

/// [setup] 으로 판 시작 상태를 바꾼 뒤 양쪽이 턴만 넘기며 끝까지 돌린다.
MatchState _play(
  void Function(SideState left, SideState right) setup, {
  Blueprint? right,
}) {
  final m = Match.start(
    seed: 17,
    blueprints: [sampleBlueprint(), right ?? sampleBlueprint()],
    decks: [
      ['p01', 'p06', 'p11', 'p16'],
      if (right == null)
        ['p26', 'p31', 'p36']
      else
        ['p01', 'p06', 'p11', 'p16'],
    ],
    costLimits: sampleCostLimits,
    pirates: sampleCatalog,
  );
  setup(m.state.sides[0], m.state.sides[1]);
  runMatch(m, passController, passController);
  expect(m.turnLog, hasLength(30));
  return m.state;
}

void _expectResult(MatchState s, int winner) {
  expect(s.outcome, MatchOutcome.timeDecision);
  expect(s.winner, winner);
}

void main() {
  group('시간 판정 시나리오 (설계서 §2.4)', () {
    test('1. 아무도 다치지 않고 30턴이 끝나면 무승부다', () {
      _expectResult(_play((l, r) {}), -1);
    });

    test('2. 침수량이 적은 오른쪽이 이긴다', () {
      _expectResult(
        _play((l, r) {
          l.flood = 200;
          r.flood = 100;
        }),
        1,
      );
    });

    test('3. 침수량이 적은 왼쪽이 이긴다', () {
      _expectResult(_play((l, r) => r.flood = 300), 0);
    });

    test('4. 침수량 차이가 1%p 이내면 선체 내구도가 높은 쪽이 이긴다', () {
      _expectResult(
        _play((l, r) {
          l.flood = 110;
          r.flood = 100;
          r.grid.damage(4, 3, 100); // 물 위 돛(망사)을 부순다
        }),
        0,
      );
    });

    test('5. 침수량 차이가 1%p 를 넘으면 내구도가 낮아도 침수량이 적은 쪽이 이긴다', () {
      _expectResult(
        _play((l, r) {
          l.flood = 111;
          r.flood = 100;
          r.grid.damage(4, 3, 100);
        }),
        1,
      );
    });

    test('6. 침수량도 내구도도 같으면 무승부다', () {
      _expectResult(
        _play((l, r) {
          for (final s in [l, r]) {
            s
              ..flood = 50
              ..grid.damage(4, 3, 100);
          }
        }),
        -1,
      );
    });

    test('7. 내구도는 남은 양이 아니라 시작 대비 비율로 비교한다', () {
      final s = _play(
        (l, r) => l.grid.damage(4, 3, 100),
        right: _keelOnly(),
      );
      expect(
        s.sides[0].grid.totalHp,
        greaterThan(s.sides[1].grid.totalHp),
      );
      _expectResult(s, 1);
    });

    test('8. 흘수선 아래 구멍이 있으면 턴마다 물이 쌓여 시간 판정에서 진다', () {
      final s = _play((l, r) => l.grid.damage(3, 0, 100));
      expect(s.sides[0].flood, greaterThan(0));
      _expectResult(s, 1);
    });

    test('9. 폭풍 타임(27~30턴)에는 턴 끝 침수가 1.5배로 찬다', () {
      // 처음 침수 6%p 로 맨 아래 줄이 완전히 잠긴 채 시작한다.
      final s = _play(
        (l, r) => r
          ..flood = 60
          ..grid.damage(3, 0, 100),
      );
      // 오른쪽 15턴 중 폭풍 전 13턴 × 4%p + 폭풍 2턴 × 6%p.
      expect(s.sides[1].flood, 60 + 13 * 40 + 2 * 60);
      _expectResult(s, 0);
    });

    test('10. 30턴 전에 침수량이 100% 가 되면 시간 판정 없이 격침(침수)이다', () {
      final m = newSampleMatch(17);
      final first = m.state.activeSide;
      for (var x = 0; x < 12; x++) {
        m.state.sides[first].grid.damage(x, 0, 100); // 12칸 × 4%p = 48%p/턴
      }
      runMatch(m, passController, passController);
      expect(m.state.outcome, MatchOutcome.floodSunk);
      expect(m.state.winner, 1 - first);
      expect(m.turnLog.length, lessThan(30));
      expect(m.state.sides[first].flood, fullFlood);
    });
  });
}
