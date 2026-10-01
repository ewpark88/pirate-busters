import 'package:pb_sim/pb_sim.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

/// 12 × 3 을 소나무로 채우고 착탄 칸 (6, 1) 만 참나무인 배. 두 걸음 안이 모두 블록이라
/// 조각이 바다로 흩어지지 않는다.
Blueprint _fullOak() => Blueprint(
  HullSpec.sloop,
  [
    for (var y = 0; y < 3; y++)
      for (var x = 0; x < 12; x++)
        BlockCell(
          x,
          y,
          x == 6 && y == 1 ? BlockMaterial.oak : BlockMaterial.pine,
        ),
  ],
  cabins: const [
    CabinCell(0, 1),
    CabinCell(1, 1),
    CabinCell(2, 1),
    CabinCell(3, 1),
  ],
  modules: const [ModuleCell(11, 0, ModuleKind.captain)],
);

SideState _side(Blueprint b) => SideState(
  side: 1,
  blueprint: b,
  lineup: [testPirate('a')],
  rules: const MatchRules(waveLevel: 0),
);

int _impact(SideState s, PirateSpec spec, int seed, {int cx = 6, int cy = 1}) {
  final before = s.grid.totalHp;
  resolveImpact(
    s,
    spec: spec,
    cx: cx,
    cy: cy,
    x: 0,
    y: 0,
    events: [],
    rng: XorShift32(seed),
  );
  return before - s.grid.totalHp;
}

void main() {
  group('균열 피해 (설계서 §4.8, BALANCE.md A4.8, ADR-052)', () {
    test('조각 수는 반경 안 바깥 칸 수다: 반경 0 → 0, 1 → 4, 2 → 12', () {
      expect(
        [crackShardCount(0), crackShardCount(1), crackShardCount(2)],
        [
          0,
          4,
          12,
        ],
      );
    });

    test('조각 하나의 피해는 기본 피해 × 바깥 칸 비율을 반올림한 값이다', () {
      expect(crackShardDamage(40, 40), 16);
      expect(crackShardDamage(60, 50), 30);
      expect(crackShardDamage(25, 50), 13);
    });

    test('가득 찬 배에서는 어느 시드든 총피해 = 중심 + 조각 수 × 조각 피해 (반경 1·2)', () {
      // 조각 3 은 12개가 한 칸에 겹쳐도 소나무 40 을 넘지 않아 피해가 새지 않는다.
      for (final r in [1, 2]) {
        final spec = testPirate('b', blockDamage: 6, blastRadius: r);
        final expected =
            6 + crackShardCount(r) * crackShardDamage(6, edgePercentOf(spec));
        for (var seed = 1; seed <= 60; seed++) {
          final s = _side(_fullOak());
          expect(_impact(s, spec, seed), expected, reason: 'r $r seed $seed');
          // 착탄 칸은 피해 전부(6)만 받고 조각은 돌아오지 않는다.
          expect(s.grid.hpAt(6, 1), 80 - 6, reason: 'r $r seed $seed');
        }
      }
    });

    test('조각은 두 걸음(반경 1) 안의 블록 칸에만 떨어진다', () {
      for (var seed = 1; seed <= 100; seed++) {
        final s = _side(_fullOak());
        _impact(s, testPirate('b', blockDamage: 40), seed);
        for (var y = 0; y < 3; y++) {
          for (var x = 0; x < 12; x++) {
            final m = s.grid.materialAt(x, y);
            if (m != null && s.grid.hpAt(x, y) == m.durability) continue;
            expect((x - 6).abs() <= 2, isTrue, reason: 'seed $seed ($x, $y)');
          }
        }
      }
    });

    test('같은 시드면 같은 모양, 100개 시드 중에는 서로 다른 모양이 있다', () {
      List<int> shape(int seed) {
        final s = _side(_fullOak());
        _impact(s, testPirate('b', blockDamage: 40), seed);
        return s.grid.rawHp;
      }

      expect(shape(42), shape(42));
      final distinct = <String>{for (var i = 1; i <= 100; i++) '${shape(i)}'};
      expect(distinct.length, greaterThan(1));
    });

    test('빈 칸·바다로는 번지지 않고, 첫 걸음 후보가 없으면 조각이 사라진다', () {
      final g = ShipGrid.fromBlueprint(sampleBlueprint());
      // (0, 1) 소나무 주변을 모두 비운다: (0, 0), (1, 0), (1, 1), (1, 2).
      for (final (x, y) in [(0, 0), (1, 0), (1, 1), (1, 2)]) {
        g.removeAt(g.indexOf(x, y));
      }
      for (var seed = 1; seed <= 20; seed++) {
        expect(walkCrackShard(g, 0, 1, 1, XorShift32(seed)), -1);
      }
      // 빈 쪽을 고른 조각은 사라지고, 남은 조각은 블록이 있는 칸에만 있다.
      final g2 = ShipGrid.fromBlueprint(sampleBlueprint());
      var lost = 0;
      for (var seed = 1; seed <= 100; seed++) {
        final cell = walkCrackShard(g2, 4, 3, 1, XorShift32(seed));
        if (cell < 0) {
          lost++;
          continue;
        }
        expect(cell, isNot(g2.indexOf(4, 3)));
        expect(g2.hasBlockAt(cell), isTrue);
      }
      // (4, 3) 망사 위·좌우 위 세 칸은 비어 있어 일부는 바다로 흩어진다.
      expect(lost, greaterThan(0));
    });

    test('도중에 빈 칸·착탄 칸을 고르면 그 자리에서 멈춘다', () {
      // (0, 1) 의 이웃은 (0, 0) 하나뿐이고 (0, 0) 의 이웃 중 착탄 칸이 아닌 블록은
      // 없다 → 조각은 사라지거나 (0, 0) 에서 멈춘다. 다른 칸에는 가지 않는다.
      final g = ShipGrid.fromBlueprint(sampleBlueprint());
      for (final (x, y) in [(1, 0), (1, 1), (1, 2)]) {
        g.removeAt(g.indexOf(x, y));
      }
      final landed = <int>{};
      for (var seed = 1; seed <= 40; seed++) {
        landed.add(walkCrackShard(g, 0, 1, 1, XorShift32(seed)));
      }
      expect(landed, {-1, g.indexOf(0, 0)});
    });

    test('일반 폭발탄(중심 40)은 참나무를 두 발에 부순다 — 조각이 중심에 겹치지 않는다', () {
      final spec = testPirate('octo', blockDamage: 40);
      for (var seed = 1; seed <= 30; seed++) {
        final s = _side(_fullOak());
        _impact(s, spec, seed);
        expect(s.grid.hasBlock(6, 1), isTrue);
        _impact(s, spec, seed + 1000);
        expect(s.grid.hasBlock(6, 1), isFalse);
      }
    });

    test('반경 0 탄은 그 칸만 맞고 난수를 쓰지 않는다', () {
      final s = _side(_fullOak());
      final rng = XorShift32(5);
      final before = rng.state;
      resolveImpact(
        s,
        spec: testPirate('d', blastRadius: 0),
        cx: 6,
        cy: 1,
        x: 0,
        y: 0,
        events: [],
        rng: rng,
      );
      expect(s.grid.totalHp, 35 * 40 + 80 - 60);
      expect(rng.state, before);
    });
  });
}
