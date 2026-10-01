import 'dart:convert';

import 'package:pb_sim/pb_sim.dart';
import 'package:pb_sim/src/combat/module_effects.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

const _captain = ModuleCell(11, 1, ModuleKind.captain);

/// 용골(참나무) + 1층(소나무) + (1, 2..3) 소나무 기둥. 비용 38. 선실은 1층.
Blueprint _ship(List<ModuleCell> modules, {bool captain = true}) => Blueprint(
  HullSpec.sloop,
  [
    for (var x = 0; x < 12; x++) BlockCell(x, 0, BlockMaterial.oak),
    for (var x = 0; x < 12; x++) BlockCell(x, 1, BlockMaterial.pine),
    const BlockCell(1, 2, BlockMaterial.pine),
    const BlockCell(1, 3, BlockMaterial.pine),
  ],
  cabins: const [
    CabinCell(3, 1),
    CabinCell(5, 1),
    CabinCell(6, 1),
    CabinCell(8, 1),
  ],
  modules: [...modules, if (captain) _captain],
);

SideState _side(Blueprint b) => SideState(
  side: 0,
  blueprint: b,
  lineup: [testPirate('a'), testPirate('b')],
  rules: const MatchRules(waveLevel: 0),
);

/// 칸 하나만 부수는 탄.
final PirateSpec _breaker = testPirate(
  'breaker',
  blockDamage: 1000,
  pirateDamage: 0,
  blastRadius: 0,
);

List<SimEvent> _smash(SideState s, int cx, int cy) {
  final events = <SimEvent>[];
  resolveImpact(
    s,
    spec: _breaker,
    cx: cx,
    cy: cy,
    x: 0,
    y: 0,
    events: events,
    rng: XorShift32(1),
  );
  return events;
}

int _destroyedCount(List<SimEvent> events) =>
    events.where((e) => e.kind == SimEventKind.blockDestroyed).length;

void main() {
  group('모듈 배치 검사 (설계서 §3.3)', () {
    void bad(List<ModuleCell> m, {bool captain = true}) => expect(
      () => _ship(m, captain: captain),
      throwsArgumentError,
      reason: '$m',
    );

    test('블록 위·한 칸에 하나·선장실 1개·포문과 망루는 선실 칸에만', () {
      bad(const [ModuleCell(4, 5, ModuleKind.pump)]);
      bad(const [
        ModuleCell(0, 1, ModuleKind.pump),
        ModuleCell(0, 1, ModuleKind.workshop),
      ]);
      bad(const [ModuleCell(0, 1, ModuleKind.gunPort)]);
      bad(const [ModuleCell(3, 1, ModuleKind.pump)]);
      bad(const [], captain: false);
      bad(const [ModuleCell(0, 1, ModuleKind.captain)]);
      expect(
        _ship(const [ModuleCell(3, 1, ModuleKind.gunPort)]).modules,
        hasLength(2),
      );
    });

    test('선장실을 뺀 모듈은 한도(슬루프 4) 안이고 비용은 블록과 합친다', () {
      bad([
        for (var x = 0; x < 3; x++) ModuleCell(x, 1, ModuleKind.pump),
        const ModuleCell(9, 1, ModuleKind.pump),
        const ModuleCell(10, 1, ModuleKind.pump),
      ]);
      final b = _ship([
        for (var x = 0; x < 3; x++) ModuleCell(x, 1, ModuleKind.pump),
        const ModuleCell(3, 1, ModuleKind.lookout),
      ]);
      expect(b.cost, 38 + 3 * 3 + 2);
      expect(
        () => Blueprint(
          HullSpec.sloop,
          sampleBlueprint().cells,
          cabins: sampleCabins,
          modules: const [
            _captain,
            ModuleCell(0, 1, ModuleKind.pump),
            ModuleCell(10, 1, ModuleKind.magazine),
          ],
        ),
        throwsArgumentError,
        reason: '블록 57 + 모듈 6 = 63 > 60',
      );
    });

    test('건조 검증은 예외 없이 첫 문제를 알려 주고, 끊긴 블록 목록을 준다 (§3.4)', () {
      const cells = [
        BlockCell(0, 0, BlockMaterial.oak),
        BlockCell(1, 0, BlockMaterial.oak),
        BlockCell(2, 0, BlockMaterial.oak),
        BlockCell(3, 0, BlockMaterial.oak),
        BlockCell(4, 0, BlockMaterial.oak),
        BlockCell(8, 3, BlockMaterial.pine),
      ];
      const cabins = [
        CabinCell(0, 0),
        CabinCell(1, 0),
        CabinCell(2, 0),
        CabinCell(3, 0),
      ];
      final loose = disconnectedBlocks(HullSpec.sloop, cells);
      expect([for (final c in loose) '${c.x},${c.y}'], ['8,3']);
      expect(
        buildProblem(
          HullSpec.sloop,
          cells,
          cabins: cabins,
          modules: const [ModuleCell(4, 0, ModuleKind.captain)],
        ),
        contains('용골'),
      );
      expect(
        buildProblem(
          HullSpec.sloop,
          cells.sublist(0, 5),
          cabins: cabins,
          modules: const [],
        ),
        contains('선장실'),
      );
      expect(
        buildProblem(
          HullSpec.sloop,
          cells.sublist(0, 5),
          cabins: cabins,
          modules: const [ModuleCell(4, 0, ModuleKind.captain)],
        ),
        isNull,
      );
    });

    test('조선소 수치는 완성 전 블록 목록으로도 전투와 같은 식으로 나온다 (§13.6)', () {
      final b = _ship(const [ModuleCell(9, 1, ModuleKind.fuelTank)]);
      final stats = ShipStats.of(b.hull, b.cells, b.modules);
      final side = _side(b);
      expect(stats.cost, b.cost);
      expect(stats.waterline, side.waterline);
      expect(stats.fuelPermille, side.modules.weightPermille);
      expect(stats.tank * SideState.fuelUnit, side.tank);
      expect([stats.modulesCounted, stats.captains], [1, 1]);
    });

    test('모듈이 든 설계도는 JSON 으로 저장했다 읽어도 같다', () {
      final b = _ship(const [
        ModuleCell(0, 1, ModuleKind.pump),
        ModuleCell(5, 1, ModuleKind.gunPort),
      ]);
      final text = jsonEncode(b.toJson());
      final back = Blueprint.fromJson(
        jsonDecode(text) as Map<String, Object?>,
      );
      expect(jsonEncode(back.toJson()), text);
      expect(back.cost, b.cost);
    });
  });

  group('모듈 효과 (설계서 §3.3, BALANCE.md A3.3)', () {
    test('무게 연료: 철판으로만 지은 배가 +20%, 가벼운 배는 덜 늘어난다 (§2.7)', () {
      final light = _side(_ship(const []));
      expect(light.modules.weightPermille, greaterThan(1000));
      expect(light.modules.weightPermille, lessThan(1200));
      final iron = Blueprint(
        HullSpec.sloop,
        [for (var x = 0; x < 12; x++) BlockCell(x, 0, BlockMaterial.iron)],
        cabins: const [
          CabinCell(0, 0),
          CabinCell(1, 0),
          CabinCell(2, 0),
          CabinCell(3, 0),
        ],
        modules: const [ModuleCell(4, 0, ModuleKind.captain)],
      );
      // 철판 12칸 = 무게 60, 최대 75 → +16%.
      expect(ShipModules.weightFuelPermilleOf(iron), 1160);
      expect(_side(iron).fuelPerCell, 4 * SideState.fuelUnit * 1160 ~/ 1000);
    });

    test('연료통: 탱크 +40, 부서지면 탱크가 줄고 주변 1칸 블록에 40 피해', () {
      final s = _side(_ship(const [ModuleCell(9, 1, ModuleKind.fuelTank)]));
      expect(s.tank, 120 * SideState.fuelUnit);
      expect(s.fuel, 120 * SideState.fuelUnit);
      final before = s.grid.totalHp;
      final events = _smash(s, 9, 1);
      expect(s.tank, 80 * SideState.fuelUnit);
      expect(s.fuel, 80 * SideState.fuelUnit);
      expect(
        events.where((e) => e.kind == SimEventKind.moduleDestroyed),
        hasLength(1),
      );
      // 연료통 칸 소나무 40 + 균열 조각 최대 4개 × 40 (§4.8 균열 피해). 위쪽이 비어
      // 그쪽을 고른 조각은 바다로 흩어지고, 조각이 받침을 부수면 위 칸이 무너져
      // 40 씩 더 깎일 수 있다(§3.4).
      final loss = before - s.grid.totalHp;
      expect(loss, inInclusiveRange(40, 40 + 4 * 40 + 2 * 40));
      expect(loss % 40, 0);
    });

    test('화약고: 남아 있으면 모든 해적 피해 +10%, 부서지면 반경 2칸이 터진다', () {
      final s = _side(_ship(const [ModuleCell(10, 1, ModuleKind.magazine)]));
      expect(s.damageBonusPercent(0), 10);
      final events = _smash(s, 10, 1);
      expect(s.damageBonusPercent(0), 0);
      // 균열 조각 12개 × 80 이라 조각이 닿는 칸은 참나무(80)도 한 번에 부서진다.
      // 위쪽이 비어 일부 조각은 흩어지고, 두 걸음으로 닿는 (8, 0)·(8, 1) 까지
      // 최대 7칸 (+ 화약고 칸) 이다.
      expect(_destroyedCount(events), inInclusiveRange(1 + 1, 1 + 7));
      expect(s.grid.hasBlock(10, 1), isFalse);
    });

    test('포문은 그 선실 해적만 +10%, 망루는 그 선실만 궤적 50%', () {
      final s = _side(
        _ship(const [
          ModuleCell(3, 1, ModuleKind.gunPort),
          ModuleCell(5, 1, ModuleKind.lookout),
        ]),
      );
      expect([s.damageBonusPercent(0), s.damageBonusPercent(1)], [10, 0]);
      expect([s.hasLookout(0), s.hasLookout(1)], [false, true]);
    });

    test('펌프는 턴 끝 침수량을 −4%p, 목수 공방은 구멍 블록을 아래 줄부터 고친다', () {
      final s = _side(
        _ship(const [
          ModuleCell(0, 1, ModuleKind.pump),
          ModuleCell(2, 1, ModuleKind.workshop),
        ]),
      )..flood = 100;
      s.grid
        ..damage(7, 1, 30) // 소나무 40 → 10 (구멍)
        ..damage(7, 0, 60); // 참나무 80 → 20 (구멍)
      final events = <SimEvent>[];
      runRepairAndPumps(s, events);
      expect(s.flood, 60);
      expect(s.grid.hpAt(7, 0), 80, reason: '아래 줄 먼저');
      expect(s.grid.hpAt(7, 1), 10, reason: '공방 1개는 1칸만');
    });

    test('돛대가 부러지면 위 블록이 무너지고 1칸당 연료 2배·속도 절반', () {
      final s = _side(_ship(const [ModuleCell(1, 1, ModuleKind.mast)]));
      final fuel = s.fuelPerCell;
      final speed = moveSpeedOf(s);
      final events = _smash(s, 1, 1);
      expect(s.grid.hasBlock(1, 2), isFalse);
      expect(s.grid.hasBlock(1, 3), isFalse);
      expect(
        events.where((e) => e.kind == SimEventKind.blockCollapsed),
        hasLength(2),
      );
      expect(s.fuelPerCell, fuel * 2);
      expect(moveSpeedOf(s), speed ~/ 2);
    });

    test('돛대가 부러져 무너진 블록 위의 모듈도 그 자리에서 부서진다', () {
      final s = _side(
        _ship(const [
          ModuleCell(1, 1, ModuleKind.mast),
          ModuleCell(1, 3, ModuleKind.pump),
        ]),
      );
      final events = _smash(s, 1, 1);
      expect(s.modules.intactCount(ModuleKind.pump), 0);
      expect(
        events.where((e) => e.kind == SimEventKind.moduleDestroyed),
        hasLength(2),
      );
    });

    test('선장실을 잃으면 쏜 해적의 쿨다운이 1턴 더 길다', () {
      final s = _side(_ship(const []));
      markFiredWithModules(s, 0);
      expect(s.crew.pirates[0].cooldown, 1);
      _smash(s, 11, 1);
      markFiredWithModules(s, 1);
      expect(s.crew.pirates[1].cooldown, 2);
    });
  });

  test('모듈을 단 배로 끝까지 둔 판은 재생 해시가 같다', () {
    final b = _ship(const [
      ModuleCell(0, 1, ModuleKind.pump),
      ModuleCell(2, 1, ModuleKind.workshop),
      ModuleCell(10, 1, ModuleKind.magazine),
      ModuleCell(9, 1, ModuleKind.fuelTank),
    ]);
    Match start() => Match.start(
      seed: 9,
      blueprints: [b, b],
      decks: sampleDecks,
      costLimits: sampleCostLimits,
      pirates: sampleCatalog,
    );
    final m = start();
    runMatch(m, RandomController(21), RandomController(22));
    final again = start();
    m.turnLog.forEach(again.playTurn);
    expect(hashMatchState(again.state), hashMatchState(m.state));
  });

  test('선실 옵션(포문·망루)은 기능 모듈 수에서 뺀다 (설계서 §3.3)', () {
    final b = _ship(const [
      ModuleCell(0, 1, ModuleKind.pump),
      ModuleCell(2, 1, ModuleKind.workshop),
      ModuleCell(9, 1, ModuleKind.fuelTank),
      ModuleCell(10, 1, ModuleKind.mast),
      ModuleCell(3, 1, ModuleKind.gunPort),
      ModuleCell(5, 1, ModuleKind.lookout),
    ]);
    expect(ShipStats.of(b.hull, b.cells, b.modules).modulesCounted, 4);
  });

  test('화약고는 블록이 남아도 맞으면 터진다 (설계서 §3.3, ADR-050)', () {
    final s = _side(_ship(const [ModuleCell(10, 1, ModuleKind.magazine)]));
    final events = <SimEvent>[];
    // 소나무 화약고 칸에 5 피해: 블록은 남지만 화약고는 터진다.
    resolveImpact(
      s,
      spec: testPirate('tap', blockDamage: 5, pirateDamage: 0, blastRadius: 0),
      cx: 10,
      cy: 1,
      x: 0,
      y: 0,
      events: events,
      rng: XorShift32(1),
    );
    expect(
      events.where(
        (e) =>
            e.kind == SimEventKind.moduleDestroyed &&
            e.value == ModuleKind.magazine.index,
      ),
      hasLength(1),
    );
    expect(s.damageBonusPercent(0), 0);
    expect(s.grid.hasBlock(10, 1), isFalse, reason: '유폭 중심 80');
    expect(
      _destroyedCount(events),
      greaterThanOrEqualTo(1 + 1),
      reason: '균열 조각 12개 × 80 (§4.8)',
    );
  });
}
