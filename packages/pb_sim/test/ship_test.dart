import 'dart:convert';

import 'package:pb_sim/pb_sim.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

Map<String, Object?> _parse(String s) => jsonDecode(s) as Map<String, Object?>;

void main() {
  test('재질 5종의 수치는 설계서 §3.2 표와 같다', () {
    final table = {
      for (final m in BlockMaterial.values)
        m.name: [m.durability, m.weight, m.cost],
    };
    expect(table, {
      'pine': [40, 500, 1],
      'oak': [80, 2000, 2],
      'iron': [160, 5000, 4],
      'cork': [30, -2000, 3],
      'net': [20, 500, 1],
    });
    expect(BlockMaterial.iron.fireImmune, isTrue);
    expect(BlockMaterial.pine.weakToFire, isTrue);
    expect(BlockMaterial.cork.buoyant, isTrue);
    expect(BlockMaterial.net.slowsShots && BlockMaterial.net.blocksAir, isTrue);
  });

  test('선체 틀은 용골 줄 양끝 2칸, 그 위 줄 1칸을 뺀 V 자다 (설계서 §3.4, BALANCE.md A3.1)', () {
    const s = HullSpec.sloop;
    expect([s.frameInset(0), s.frameInset(1), s.frameInset(2)], [2, 1, 0]);
    expect(
      [s.inFrame(1, 0), s.inFrame(2, 0), s.inFrame(9, 0), s.inFrame(10, 0)],
      [
        false,
        true,
        true,
        false,
      ],
    );
    expect(
      [s.inFrame(0, 1), s.inFrame(1, 1), s.inFrame(0, 2)],
      [false, true, true],
    );
    const dinghy = HullSpec(
      id: 'dinghy_test',
      width: 6,
      height: 5,
      cabinSlots: 2,
      buildPoints: 20,
      moveSpeed: 2800,
      fuelTank: 80,
      fuelPerCell: 8,
      moduleLimit: 1,
    );
    expect(dinghy.frameInset(0), 1, reason: '폭 6 이하는 용골 줄 양끝 1칸');
    expect(boxSloop.inFrame(0, 0), isTrue, reason: '테스트용 직사각형');
  });

  test('선체 틀 밖에 블록을 두면 거부한다 (설계서 §3.4)', () {
    Blueprint withKeelAt(int x) => Blueprint(
      HullSpec.sloop,
      [
        ...sampleBlueprint().cells,
        BlockCell(x, 0, BlockMaterial.pine),
      ],
      cabins: sampleCabins,
      modules: const [ModuleCell(10, 1, ModuleKind.captain)],
    );
    expect(() => withKeelAt(1), throwsArgumentError);
    expect(() => withKeelAt(10), throwsArgumentError);
    expect(
      buildProblem(
        HullSpec.sloop,
        [const BlockCell(0, 0, BlockMaterial.oak)],
        cabins: const [],
        modules: const [],
      ),
      contains('선체 틀 밖'),
    );
  });

  test('슬루프는 12×8, 선실 4, 건조 포인트 60 이다', () {
    const s = HullSpec.sloop;
    expect([s.width, s.height, s.cabinSlots, s.buildPoints], [12, 8, 4, 60]);
    expect(HullSpec.byId('sloop'), same(s));
    expect(() => HullSpec.byId('galleon'), throwsFormatException);
  });

  test('설계도는 비용을 합산하고 칸을 (y, x) 순으로 정렬한다', () {
    final b = Blueprint(
      boxSloop,
      const [
        BlockCell(3, 1, BlockMaterial.iron),
        BlockCell(0, 0, BlockMaterial.oak),
        BlockCell(3, 0, BlockMaterial.oak),
        BlockCell(5, 0, BlockMaterial.pine),
        BlockCell(6, 0, BlockMaterial.pine),
      ],
      cabins: const [
        CabinCell(3, 1),
        CabinCell(0, 0),
        CabinCell(5, 0),
        CabinCell(6, 0),
      ],
      modules: const [ModuleCell(3, 0, ModuleKind.captain)],
    );
    expect(b.cost, 10);
    expect(
      [for (final c in b.cells) '${c.x},${c.y}'],
      ['0,0', '3,0', '5,0', '6,0', '3,1'],
    );
    // 선실은 입력 순서가 슬롯 번호다.
    expect(
      [for (final c in b.cabins) '${c.x},${c.y}'],
      [
        '3,1',
        '0,0',
        '5,0',
        '6,0',
      ],
    );
    expect(sampleBlueprint().cost, 57);
  });

  test('용골과 이어지지 않은 블록이나 빈 용골 줄은 거부한다 (설계서 §3.4)', () {
    const cabins = [
      CabinCell(0, 0),
      CabinCell(1, 0),
      CabinCell(2, 0),
      CabinCell(3, 0),
    ];
    final keel = [
      for (var x = 0; x < 4; x++) BlockCell(x, 0, BlockMaterial.oak),
    ];
    expect(
      () => Blueprint(
        boxSloop,
        [
          ...keel,
          const BlockCell(8, 2, BlockMaterial.pine),
        ],
        cabins: cabins,
        modules: const [],
      ),
      throwsArgumentError,
    );
    expect(
      () => Blueprint(
        boxSloop,
        const [
          BlockCell(0, 1, BlockMaterial.oak),
          BlockCell(1, 1, BlockMaterial.oak),
          BlockCell(2, 1, BlockMaterial.oak),
          BlockCell(3, 1, BlockMaterial.oak),
        ],
        cabins: const [
          CabinCell(0, 1),
          CabinCell(1, 1),
          CabinCell(2, 1),
          CabinCell(3, 1),
        ],
        modules: const [],
      ),
      throwsArgumentError,
    );
    // 대각선은 이어진 것이 아니다.
    expect(
      () => Blueprint(
        boxSloop,
        [
          ...keel,
          const BlockCell(4, 1, BlockMaterial.pine),
        ],
        cabins: cabins,
        modules: const [],
      ),
      throwsArgumentError,
    );
    expect(
      Blueprint(
        boxSloop,
        [
          ...keel,
          const BlockCell(3, 1, BlockMaterial.pine),
          const BlockCell(4, 1, BlockMaterial.pine),
        ],
        cabins: cabins,
        modules: const [ModuleCell(4, 1, ModuleKind.captain)],
      ).cells,
      hasLength(6),
    );
  });

  test('격자 밖 블록·같은 칸 중복·건조 포인트 초과는 거부한다', () {
    expect(
      () => Blueprint(
        boxSloop,
        const [
          BlockCell(12, 0, BlockMaterial.oak),
        ],
        cabins: const [],
        modules: const [],
      ),
      throwsArgumentError,
    );
    expect(
      () => Blueprint(
        boxSloop,
        const [
          BlockCell(1, 1, BlockMaterial.oak),
          BlockCell(1, 1, BlockMaterial.pine),
        ],
        cabins: const [],
        modules: const [],
      ),
      throwsArgumentError,
    );
    expect(
      () => Blueprint(
        boxSloop,
        [
          for (var x = 0; x < 12; x++) BlockCell(x, 0, BlockMaterial.iron),
          for (var x = 0; x < 4; x++) BlockCell(x, 1, BlockMaterial.iron),
        ],
        cabins: const [],
        modules: const [],
      ),
      throwsArgumentError,
    );
  });

  test('선실은 선실 슬롯 수만큼, 블록 위에, 서로 다른 칸에 있어야 한다', () {
    Blueprint build(List<CabinCell> cabins) => Blueprint(
      boxSloop,
      [
        for (var x = 0; x < 12; x++) BlockCell(x, 0, BlockMaterial.oak),
      ],
      cabins: cabins,
      modules: const [ModuleCell(11, 0, ModuleKind.captain)],
    );
    expect(
      () => build(const [CabinCell(0, 0), CabinCell(1, 0), CabinCell(2, 0)]),
      throwsArgumentError,
    );
    expect(
      () => build(const [
        CabinCell(0, 0),
        CabinCell(1, 0),
        CabinCell(2, 0),
        CabinCell(2, 1),
      ]),
      throwsArgumentError,
    );
    expect(
      () => build(const [
        CabinCell(0, 0),
        CabinCell(1, 0),
        CabinCell(2, 0),
        CabinCell(2, 0),
      ]),
      throwsArgumentError,
    );
  });

  test('설계도는 JSON 으로 저장했다 읽어도 같다', () {
    final b = sampleBlueprint();
    final text = jsonEncode(b.toJson());
    final back = Blueprint.fromJson(_parse(text));
    expect(jsonEncode(back.toJson()), text);
    expect(back.cost, b.cost);
  });

  test('설계도 JSON 의 형식이 틀리면 FormatException 을 낸다', () {
    for (final bad in [
      '{"hull":"sloop","cells":[[1,2]],"cabins":[]}',
      '{"hull":"sloop","cells":[],"cabins":[[1]]}',
      '{"hull":"sloop","cells":[]}',
      '{"hull":"sloop","cells":[[1.5,2,"oak"]],"cabins":[]}',
      '{"hull":"sloop","cells":[[1,2,"gold"]],"cabins":[]}',
      '{"hull":"sloop"}',
    ]) {
      expect(() => Blueprint.fromJson(_parse(bad)), throwsFormatException);
    }
  });

  test('격자는 설계도 블록을 최대 내구도로 채운다', () {
    final g = ShipGrid.fromBlueprint(sampleBlueprint());
    expect(g.cellCount, 96);
    expect(g.materialAt(2, 2), BlockMaterial.iron);
    expect(g.hpAt(2, 2), 160);
    expect(g.materialAt(0, 7), isNull);
    expect(g.hpAt(0, 7), 0);
    expect(g.blockCount, 37);
    expect(g.totalHp, 12 * 80 + 12 * 40 + 30 + 2 * 160 + 6 * 40 + 4 * 20);
    expect(g.rawMaterials[g.indexOf(1, 2)], BlockMaterial.cork.index);
  });
}
