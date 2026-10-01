import 'package:pb_sim/pb_sim.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

/// [m] 재질로만 지은 용골 한 줄(12칸) 격자.
ShipGrid _keel(BlockMaterial m) => ShipGrid.fromBlueprint(
  Blueprint(
    HullSpec.sloop,
    [for (var x = 0; x < 12; x++) BlockCell(x, 0, m)],
    cabins: const [
      CabinCell(0, 0),
      CabinCell(1, 0),
      CabinCell(2, 0),
      CabinCell(3, 0),
    ],
    modules: const [ModuleCell(4, 0, ModuleKind.captain)],
  ),
);

/// 같은 칸에 [damage] 를 반복해 파괴까지 걸린 발 수와 첫 발 뒤 단계.
(int, DamageStage) _hits(BlockMaterial m, int damage) {
  final g = _keel(m)..damage(6, 0, damage);
  final first = g.stageAt(6, 0);
  var n = 1;
  while (g.hasBlock(6, 0)) {
    g.damage(6, 0, damage);
    n++;
  }
  return (n, first);
}

void main() {
  group('BALANCE.md B2: 재질 × 피해 → 발 수 (일반 등급, 설계서 §3.2, §4.3)', () {
    // 열: 투척 중심 40, 투척 바깥 20, 직사 60, 관통 50, 물수제비 30,
    // 물수제비 흘수선 45, 수중 40, 강습 20.
    const damages = [40, 20, 60, 50, 30, 45, 40, 20];
    const d = DamageStage.destroyed;
    const c = DamageStage.cracked;
    const h = DamageStage.holed;
    const i = DamageStage.intact;
    final table = <BlockMaterial, List<(int, DamageStage)>>{
      BlockMaterial.pine: [
        (1, d), (2, c), (1, d), (1, d), (2, h), (1, d), (1, d), (2, c), //
      ],
      BlockMaterial.oak: [
        (2, c), (4, i), (2, h), (2, c), (3, c), (2, c), (2, c), (4, i), //
      ],
      BlockMaterial.iron: [
        (4, i), (8, i), (3, c), (4, i), (6, i), (4, i), (4, i), (8, i), //
      ],
      BlockMaterial.cork: [
        (1, d), (2, h), (1, d), (1, d), (1, d), (1, d), (1, d), (2, h), //
      ],
      BlockMaterial.net: [
        (1, d), (1, d), (1, d), (1, d), (1, d), (1, d), (1, d), (1, d), //
      ],
    };
    for (final MapEntry(key: m, value: row) in table.entries) {
      test('${m.name}: 표의 발 수와 첫 발 뒤 손상 단계가 같다', () {
        expect([for (final dmg in damages) _hits(m, dmg)], row);
      });
    }

    test('물수제비 흘수선 45 는 물수제비 30 × 1.5 (§4.3)', () {
      expect(30 * 150 ~/ 100, 45);
    });
  });

  group('BALANCE.md B4: 격침 속도 (설계서 §2.4)', () {
    test('일반 폭발탄 한 발은 블록 피해 104(중심 40 + 균열 조각 4개 × 16, A4.8 바깥 40%)', () {
      const octo = PirateSpec(
        id: 'octo',
        rarity: Rarity.common,
        hp: 240,
        cooldownTurns: 0,
        blockDamage: 40,
        pirateDamage: 80,
        blastRadius: 1,
        ammoValue: 40,
      );
      final ship = SideState(
        side: 1,
        blueprint: Blueprint(
          HullSpec.sloop,
          [
            for (var x = 0; x < 12; x++) BlockCell(x, 0, BlockMaterial.oak),
            for (var x = 5; x <= 7; x++) BlockCell(x, 1, BlockMaterial.oak),
            const BlockCell(6, 2, BlockMaterial.oak),
          ],
          cabins: const [
            CabinCell(0, 0),
            CabinCell(1, 0),
            CabinCell(2, 0),
            CabinCell(3, 0),
          ],
          modules: const [ModuleCell(11, 0, ModuleKind.captain)],
        ),
        lineup: const [],
        rules: const MatchRules(),
      );
      final before = ship.grid.totalHp;
      resolveImpact(
        ship,
        spec: octo,
        cx: 6,
        cy: 1,
        x: 0,
        y: 0,
        events: [],
        rng: XorShift32(7),
      );
      // 두 걸음 안이 모두 참나무라 조각 16 이 넘치지 않는다. (5, 2)·(7, 2) 가 비어
      // 그쪽을 고른 조각은 바다로 흩어지므로 104 이하이고, 가득 찬 선체의 104 는
      // crack_spread_test 가 본다.
      final loss = before - ship.grid.totalHp;
      expect(loss, lessThanOrEqualTo(104));
      expect((loss - 40) % 16, 0);
    });

    test('기준 배 A(테스트 슬루프): 내구도 2,110, 격침(30%)까지 1,478 → 일반 폭발탄 15발', () {
      final grid = ShipGrid.fromBlueprint(sampleBlueprint());
      expect(sampleBlueprint().cost, 57);
      expect(grid.initialTotalHp, 2110);
      // 격침: 남은 내구도 × 100 < 시작 × 30 (A2.4) → 632 이하로 깎아야 한다.
      final percent = const MatchRules().sunkHullPercent;
      var toCut = 0;
      while ((grid.initialTotalHp - toCut) * 100 >=
          grid.initialTotalHp * percent) {
        toCut++;
      }
      expect(toCut, 1478);
      expect((toCut + 103) ~/ 104, 15);
    });
  });
}
