import 'dart:convert';

import 'package:pb_sim/pb_sim.dart';
import 'package:test/test.dart';

/// 단계 [stage] 슬루프의 틀 안 아래 두 줄을 소나무로 채우고 선실·선장실을 둔 배.
Blueprint _small(int stage, {int level = 1}) {
  final hull = HullSpec.byId('sloop', stage: stage, level: level);
  final cells = [
    for (var y = 0; y < 2; y++)
      for (var x = 0; x < hull.width; x++)
        if (hull.inFrame(x, y)) BlockCell(x, y, BlockMaterial.pine),
  ];
  return Blueprint(
    hull,
    cells,
    cabins: [for (var i = 0; i < hull.cabinSlots; i++) CabinCell(2 + i, 1)],
    modules: [ModuleCell(hull.width - 2, 1, ModuleKind.captain)],
  );
}

void main() {
  group('슬루프 확장 단계 (설계서 §3.1, BALANCE.md A3.1)', () {
    test('단계마다 격자·선실·건조 포인트·모듈 한도가 표와 같고, 4단계가 슬루프다', () {
      final table = [
        for (final h in HullSpec.sloopStages)
          [
            h.stage,
            h.width,
            h.height,
            h.cabinSlots,
            h.buildPoints,
            h.moduleLimit,
          ],
      ];
      expect(table, [
        [1, 6, 5, 2, 20, 1],
        [2, 8, 6, 3, 32, 2],
        [3, 10, 7, 3, 45, 3],
        [4, 12, 8, 4, 60, 4],
      ]);
      expect(HullSpec.byId('sloop'), same(HullSpec.sloop));
      expect(
        HullSpec.byId('sloop', stage: 1).fuelTank,
        HullSpec.sloop.fuelTank,
      );
      expect(() => HullSpec.byId('sloop', stage: 5), throwsFormatException);
    });

    test('돛단배(1단계)는 선실 2칸이고 용골 줄 틀은 양끝 1칸만 뺀다', () {
      final b = _small(1);
      expect(b.cabins, hasLength(2));
      expect(b.hull.frameInset(0), 1);
      expect(
        () => Blueprint(
          b.hull,
          [...b.cells, const BlockCell(6, 1, BlockMaterial.pine)],
          cabins: b.cabins,
          modules: b.modules,
        ),
        throwsArgumentError,
        reason: '6×5 격자 밖',
      );
    });

    test('단계는 설계도 JSON 에 들어가고, 없으면 다 자란 슬루프다', () {
      final b = _small(2);
      final json = b.toJson();
      expect(json['stage'], 2);
      final back = Blueprint.fromJson(
        jsonDecode(jsonEncode(json)) as Map<String, Object?>,
      );
      expect(back.hull.width, 8);
      expect(_small(4).toJson().containsKey('stage'), isFalse);
    });
  });

  group('선형 레벨 (설계서 §13.6, BALANCE.md A13.6)', () {
    test('레벨마다 블록 내구도 +1%, 탱크 +1, 짝수 레벨마다 건조 포인트 +1', () {
      final lv1 = ShipGrid.fromBlueprint(_small(4));
      final lv11 = ShipGrid.fromBlueprint(_small(4, level: 11));
      expect(lv1.hpAt(4, 0), 40);
      expect(lv11.hpAt(4, 0), 44, reason: '40 × 1.10');
      final h = HullSpec.sloop.atLevel(11);
      expect([h.buildPoints, h.fuelTank, h.moduleLimit], [65, 90, 4]);
      expect(HullSpec.sloop.atLevel(15).moduleLimit, 5);
      final top = HullSpec.sloop.atLevel(50);
      expect([top.buildPoints, top.moduleLimit], [85, 6], reason: '포인트 +25 상한');
      expect(() => HullSpec.sloop.atLevel(51), throwsFormatException);
    });

    test('선형 레벨은 설계도 JSON 에 들어가고 돛대 칸 내구도에도 곱한다', () {
      final hull = HullSpec.sloop.atLevel(11);
      final b = Blueprint(
        hull,
        [
          for (var x = 2; x < 10; x++) BlockCell(x, 0, BlockMaterial.pine),
          for (var x = 1; x < 11; x++) BlockCell(x, 1, BlockMaterial.pine),
        ],
        cabins: const [
          CabinCell(2, 1),
          CabinCell(3, 1),
          CabinCell(4, 1),
          CabinCell(5, 1),
        ],
        modules: const [
          ModuleCell(9, 1, ModuleKind.captain),
          ModuleCell(7, 1, ModuleKind.mast),
        ],
      );
      expect(b.toJson()['hullLevel'], 11);
      final back = Blueprint.fromJson(
        jsonDecode(jsonEncode(b.toJson())) as Map<String, Object?>,
      );
      expect(back.hull.level, 11);
      expect(ShipGrid.fromBlueprint(back).hpAt(7, 2), 33, reason: '30 × 1.10');
    });
  });
}
