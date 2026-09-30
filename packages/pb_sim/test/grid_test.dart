import 'package:pb_sim/pb_sim.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

/// 용골 줄 + (5, 1..3) 기둥 + (3..7, 4) 판 + (0, 1) 옆 블록. 선실은 용골 위.
Blueprint _pillarBlueprint() => Blueprint(
  HullSpec.sloop,
  [
    for (var x = 0; x < 12; x++) BlockCell(x, 0, BlockMaterial.oak),
    const BlockCell(0, 1, BlockMaterial.pine),
    for (var y = 1; y <= 3; y++) BlockCell(5, y, BlockMaterial.pine),
    for (var x = 3; x <= 7; x++) BlockCell(x, 4, BlockMaterial.pine),
  ],
  cabins: const [
    CabinCell(1, 0),
    CabinCell(2, 0),
    CabinCell(3, 0),
    CabinCell(4, 0),
  ],
);

void main() {
  group('DDA 격자 충돌', () {
    test('틱당 5칸을 가는 빠른 탄도 1칸 두께 벽을 건너뛰지 않는다', () {
      final hit = traceCells(500, 500, 5500, 500, (cx, cy) => cx == 3);
      expect(hit, isNotNull);
      expect([hit!.cx, hit.cy, hit.x, hit.y], [3, 0, 3000, 500]);
    });

    test('왼쪽으로 가는 선분도 처음 만나는 칸을 찾는다', () {
      final hit = traceCells(5500, 1500, 500, 1500, (cx, cy) => cx <= 2);
      expect([hit!.cx, hit.cy, hit.x], [2, 1, 3000]);
    });

    test('대각선은 지나는 칸을 모두 거친다', () {
      final visited = <String>[];
      traceCells(100, 200, 2900, 2800, (cx, cy) {
        visited.add('$cx,$cy');
        return false;
      });
      expect(visited.first, '0,0');
      expect(visited.last, '2,2');
      // 한 번에 한 축씩만 움직인다.
      for (var i = 1; i < visited.length; i++) {
        final a = visited[i - 1].split(',').map(int.parse).toList();
        final b = visited[i].split(',').map(int.parse).toList();
        expect((a[0] - b[0]).abs() + (a[1] - b[1]).abs(), 1);
      }
    });

    test('닿는 칸이 없으면 null, 시작 칸이 막혀 있으면 시작점을 돌려준다', () {
      expect(traceCells(0, 0, 900, 900, (cx, cy) => cx == 5), isNull);
      final start = traceCells(-1500, 700, 0, 700, (cx, cy) => cx == -2);
      expect([start!.cx, start.x], [-2, -1500]);
    });
  });

  group('블록 피해', () {
    test('구멍 단계 블록만 고치고, 부서진 칸·멀쩡한 칸은 못 고친다 (설계서 §2.5)', () {
      final g = ShipGrid.fromBlueprint(sampleBlueprint()); // (0,0) 참나무 80
      expect(g.repair(0, 0, 10), isFalse, reason: '멀쩡함');
      g.damage(0, 0, 60);
      expect(g.stageAt(0, 0), DamageStage.holed);
      expect(g.repair(0, 0, 500), isTrue);
      expect(g.hpAt(0, 0), 80, reason: '최대 내구도까지만');
      g.damage(0, 0, 80);
      expect(g.isBroken(0, 0), isTrue);
      expect(g.repair(0, 0, 80), isFalse);
      expect(g.hasBlock(0, 0), isFalse);
    });

    test('손상 단계는 내구도 2/3·1/3 경계로 나뉜다 (설계서 §10.2)', () {
      final g = ShipGrid.fromBlueprint(sampleBlueprint()); // (0,0) 참나무 80
      expect(g.stageAt(0, 0), DamageStage.intact);
      g.damage(0, 0, 27); // 53 → 53×3 = 159 ≤ 160
      expect(g.stageAt(0, 0), DamageStage.cracked);
      g.damage(0, 0, 26); // 27 → 81 > 80
      expect(g.stageAt(0, 0), DamageStage.cracked);
      g.damage(0, 0, 1); // 26 → 78 ≤ 80
      expect(g.stageAt(0, 0), DamageStage.holed);
      expect(g.damage(0, 0, 26), isTrue);
      expect(g.stageAt(0, 0), DamageStage.destroyed);
      expect(g.damage(0, 0, 10), isFalse);
    });

    test('폭발은 칸 단위 원형이고 착탄 칸은 100%, 나머지는 50% 피해다', () {
      final side = SideState(
        side: 1,
        blueprint: sampleBlueprint(),
        lineup: [testPirate('a')],
        rules: const MatchRules(),
      );
      final events = <SimEvent>[];
      resolveImpact(
        side,
        spec: testPirate('b', blockDamage: 30),
        cx: 4,
        cy: 1,
        x: 0,
        y: 0,
        events: events,
      );
      final g = side.grid;
      expect(g.hpAt(4, 1), 10); // 소나무 40 − 30
      expect([g.hpAt(3, 1), g.hpAt(5, 1), g.hpAt(4, 2)], [25, 25, 25]);
      expect(g.hpAt(4, 0), 80 - 15);
      expect([g.hpAt(3, 2), g.hpAt(5, 0)], [40, 80]); // 대각선은 반경 1 밖
    });
  });

  group('지지 구조', () {
    test('기둥이 끊기면 그 위 덩어리가 모두 무너지고, 용골과 이어진 블록은 남는다', () {
      final g = ShipGrid.fromBlueprint(_pillarBlueprint());
      expect(collapseUnsupported(g), isEmpty);
      g.damage(5, 1, 1000);
      final removed = collapseUnsupported(g);
      expect(removed, [
        g.indexOf(5, 2),
        g.indexOf(5, 3),
        for (var x = 3; x <= 7; x++) g.indexOf(x, 4),
      ]);
      expect(g.hasBlock(0, 1), isTrue);
      expect(g.blockCount, 13);
    });

    test('착탄으로 기둥이 부서지면 붕괴 이벤트가 칸마다 나온다', () {
      final side = SideState(
        side: 1,
        blueprint: _pillarBlueprint(),
        lineup: [testPirate('a')],
        rules: const MatchRules(),
      );
      final events = <SimEvent>[];
      resolveImpact(
        side,
        spec: testPirate('b', blockDamage: 100, blastRadius: 0),
        cx: 5,
        cy: 1,
        x: 0,
        y: 0,
        events: events,
      );
      final kinds = [for (final e in events) e.kind];
      expect(
        kinds.where((k) => k == SimEventKind.blockDestroyed),
        hasLength(1),
      );
      expect(
        kinds.where((k) => k == SimEventKind.blockCollapsed),
        hasLength(7),
      );
    });
  });
}
