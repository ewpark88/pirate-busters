import 'dart:convert';

import 'package:pb_sim/pb_sim.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

List<BlockCell> _deck(List<BlockCell> extra) => [
  for (var x = 0; x < 12; x++) BlockCell(x, 0, BlockMaterial.pine),
  for (var x = 0; x < 12; x++) BlockCell(x, 1, BlockMaterial.pine),
  ...extra,
];

List<CabinCell> _cabins(CabinCell seat) => [
  const CabinCell(3, 1),
  const CabinCell(5, 1),
  const CabinCell(6, 1),
  seat,
];

/// 용골·1층 소나무 + 선장실. 선실 셋은 1층, 넷째 선실은 [seat](돛 자리일 수 있다).
Blueprint _ship(
  List<ModuleCell> masts, {
  CabinCell seat = const CabinCell(8, 1),
  List<BlockCell> extra = const [],
}) => Blueprint(
  boxSloop,
  _deck(extra),
  cabins: _cabins(seat),
  modules: [...masts, const ModuleCell(11, 1, ModuleKind.captain)],
);

SideState _side(Blueprint b) => SideState(
  side: 0,
  blueprint: b,
  lineup: [testPirate('a'), testPirate('b'), testPirate('c'), testPirate('d')],
  rules: const MatchRules(waveLevel: 0),
);

List<SimEvent> _smash(SideState s, int cx, int cy, {int damage = 1000}) {
  final events = <SimEvent>[];
  resolveImpact(
    s,
    spec: testPirate(
      'hit',
      blockDamage: damage,
      pirateDamage: 0,
      blastRadius: 0,
    ),
    cx: cx,
    cy: cy,
    x: 0,
    y: 0,
    events: events,
    rng: XorShift32(1),
  );
  return events;
}

String? _problem(
  List<ModuleCell> masts, {
  CabinCell seat = const CabinCell(8, 1),
  List<BlockCell> extra = const [],
}) => buildProblem(
  boxSloop,
  _deck(extra)..sort((a, b) => a.y != b.y ? a.y - b.y : a.x - b.x),
  cabins: _cabins(seat),
  modules: [...masts, const ModuleCell(11, 1, ModuleKind.captain)],
);

void main() {
  group('돛대 종류 (설계서 §3.3, BALANCE.md A3.2 돛대 종류 표)', () {
    test('종류마다 칸 수·칸 내구도·무게·비용·돛 자리 피해·연료 벌칙이 표와 같다', () {
      final table = {
        for (final k in ModuleKind.values)
          if (k.isMast)
            k.jsonName: [
              k.rigHeight,
              k.rig!.durability,
              k.weight,
              k.cost,
              k.seatPercent,
              k.brokenFuelPermille,
            ],
      };
      expect(table, {
        'mast': [3, 30, 0, 2, 20, 2000],
        'mastBamboo': [2, 20, 0, 1, 15, 1500],
        'mastOak': [3, 45, 500, 3, 20, 2000],
        'mastIron': [3, 60, 1000, 4, 20, 2000],
        'mastCrow': [4, 35, 500, 3, 30, 2000],
      });
      expect(BlockMaterial.rigPine.weakToFire, isTrue);
      expect(BlockMaterial.rigIron.fireImmune, isTrue);
      expect(BlockMaterial.blocks, hasLength(5), reason: '돛대 칸 재질은 블록이 아니다');
    });

    test('돛대 레벨마다 칸 내구도 +10, 최고 레벨도 같은 재질 블록보다 약하다', () {
      final s = _side(
        _ship(const [ModuleCell(7, 1, ModuleKind.mastOak, level: 3)]),
      );
      expect(s.grid.hpAt(7, 2), 65);
      expect(s.grid.maxHpAt(s.grid.indexOf(7, 2)), 65);
      expect(s.grid.stageAt(7, 2), DamageStage.intact);
      expect(BlockMaterial.rigIron.durabilityAt(5), 100);
      expect(
        BlockMaterial.rigIron.durabilityAt(5),
        lessThan(BlockMaterial.iron.durability),
      );
      expect(
        BlockMaterial.rigPine.durabilityAt(1),
        lessThan(BlockMaterial.pine.durability),
      );
    });

    test('소나무 돛대 Lv1 은 기준 피해 40 한 발에, 참나무 돛대는 두 발에 부러진다', () {
      final pine = _side(_ship(const [ModuleCell(7, 1, ModuleKind.mast)]));
      _smash(pine, 7, 2, damage: 40);
      expect(pine.mastBroken, isTrue);
      final oak = _side(_ship(const [ModuleCell(7, 1, ModuleKind.mastOak)]));
      _smash(oak, 7, 2, damage: 40);
      expect(oak.mastBroken, isFalse);
      _smash(oak, 7, 2, damage: 40);
      expect(oak.mastBroken, isTrue);
    });

    test('대나무 돛대는 두 칸이고 부러져도 1칸당 연료 1.5배다', () {
      final s = _side(_ship(const [ModuleCell(7, 1, ModuleKind.mastBamboo)]));
      expect(s.grid.hasBlock(7, 3), isTrue);
      expect(s.grid.hasBlock(7, 4), isFalse);
      final fuel = s.fuelPerCell;
      _smash(s, 7, 2);
      expect(s.fuelPerCell, fuel * 3 ~/ 2);
    });

    test('망대 돛대는 격자 위끝에서 잘린다', () {
      const crow = ModuleCell(7, 5, ModuleKind.mastCrow);
      expect(crow.rigCells(8), [(7, 6), (7, 7)]);
      final s = _side(
        _ship(
          const [crow],
          extra: [
            for (var y = 2; y <= 5; y++) BlockCell(7, y, BlockMaterial.pine),
          ],
        ),
      );
      expect(s.grid.materialAt(7, 7), BlockMaterial.rigCrow);
    });

    test('철 돛대는 무거워 흘수선이 내려간다', () {
      final light = _side(_ship(const [ModuleCell(7, 1, ModuleKind.mast)]));
      final heavy = _side(_ship(const [ModuleCell(7, 1, ModuleKind.mastIron)]));
      expect(heavy.draft, greaterThan(light.draft));
    });
  });

  group('돛 자리 (설계서 §3.3)', () {
    test('돛대 꼭대기 선실의 해적은 종류별 피해 보너스를 받는다', () {
      final s = _side(
        _ship(
          const [ModuleCell(7, 1, ModuleKind.mastCrow)],
          seat: const CabinCell(7, 5),
        ),
      );
      expect(s.damageBonusPercent(3), 30);
      expect(s.damageBonusPercent(0), 0);
    });

    test('돛대가 부러지면 돛 자리 해적이 떨어지고, 내 턴에 밑동 위로 드러난 채 돌아온다', () {
      final s = _side(
        _ship(
          const [ModuleCell(7, 1, ModuleKind.mast)],
          seat: const CabinCell(7, 4),
        ),
      );
      final events = _smash(s, 7, 2);
      expect(s.crew.pirates[3].status, PirateStatus.swimming);
      expect(events.any((e) => e.kind == SimEventKind.pirateFell), isTrue);
      expect(s.damageBonusPercent(3), 0, reason: '부러진 돛대에는 보너스가 없다');
      s
        ..moveFallenSeats()
        ..crew.startOwnTurn(0, events);
      expect((s.cabins[3].x, s.cabins[3].y), (7, 2));
      expect(s.crew.pirates[3].status, PirateStatus.aboard);
      expect(s.isExposedPirateAt(7, 2), isTrue);
    });
  });

  group('돛대 건조 규칙 (설계서 §3.3)', () {
    test('돛대 칸 자리에 블록이 있으면 지을 수 없다', () {
      expect(_problem(const [ModuleCell(7, 1, ModuleKind.mast)]), isNull);
      expect(
        _problem(
          const [ModuleCell(7, 1, ModuleKind.mast)],
          extra: const [BlockCell(7, 2, BlockMaterial.pine)],
        ),
        contains('돛대 칸 자리'),
      );
    });

    test('선실은 돛대 꼭대기에만 둘 수 있고 중간 돛대 칸에는 못 둔다', () {
      expect(
        _problem(
          const [ModuleCell(7, 1, ModuleKind.mast)],
          seat: const CabinCell(7, 4),
        ),
        isNull,
      );
      expect(
        _problem(
          const [ModuleCell(7, 1, ModuleKind.mast)],
          seat: const CabinCell(7, 3),
        ),
        contains('돛 자리'),
      );
    });

    test('돛대 레벨은 1~5, 돛대가 아닌 모듈은 레벨이 없다', () {
      expect(
        _problem(const [ModuleCell(7, 1, ModuleKind.mast, level: 5)]),
        isNull,
      );
      expect(
        _problem(const [ModuleCell(7, 1, ModuleKind.mast, level: 6)]),
        contains('레벨'),
      );
      expect(
        _problem(const [ModuleCell(7, 1, ModuleKind.pump, level: 2)]),
        contains('레벨'),
      );
    });

    test('돛대 칸 재질은 블록으로 쓰지 않는다', () {
      expect(
        _problem(
          const [],
          extra: const [BlockCell(7, 2, BlockMaterial.rigPine)],
        ),
        contains('돛대 칸 재질'),
      );
    });

    test('레벨이 있는 돛대 모듈은 JSON 으로 저장했다 읽어도 같다', () {
      const m = ModuleCell(7, 1, ModuleKind.mastOak, level: 4);
      final back = ModuleCell.fromJson(jsonDecode(jsonEncode(m.toJson())));
      expect(m.toJson(), [7, 1, 'mastOak', 4]);
      expect([back.kind, back.level], [ModuleKind.mastOak, 4]);
      expect(const ModuleCell(1, 1, ModuleKind.pump).toJson(), [1, 1, 'pump']);
    });
  });

  test('돛대 종류가 섞이고 돛 자리에 해적이 탄 판은 고정 해시로 끝나고, 재생해도 같다', () {
    final b = _ship(
      const [
        ModuleCell(1, 1, ModuleKind.mastBamboo),
        ModuleCell(7, 1, ModuleKind.mastCrow),
        ModuleCell(9, 1, ModuleKind.mastIron, level: 3),
      ],
      seat: const CabinCell(7, 5),
    );
    Match start() => Match.start(
      seed: 11,
      blueprints: [b, b],
      decks: sampleDecks,
      costLimits: sampleCostLimits,
      pirates: sampleCatalog,
    );
    final m = start();
    runMatch(m, RandomController(31), RandomController(32));
    final again = start();
    m.turnLog.forEach(again.playTurn);
    expect(hashMatchState(again.state), hashMatchState(m.state));
    expect(hashMatchState(m.state), _mastHash);
    expect(
      m.state.sides.any((s) => s.mastBroken),
      isTrue,
      reason: '판 중에 돛대가 부러진다',
    );
  });
}

/// 돛대가 섞인 판의 고정 해시. 규칙을 일부러 바꿨을 때만 고친다.
const int _mastHash = 596680140;
