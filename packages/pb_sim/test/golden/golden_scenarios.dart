import 'package:pb_sim/pb_sim.dart';

import '../fixtures.dart';
import '../scenarios.dart';

/// 골든 리플레이를 재생할 때 쓰는 해적 정의(샘플 + 시나리오).
final PirateCatalog goldenCatalog = PirateCatalog([
  ...samplePirates,
  ...scenarioPirates,
]);

/// 골든 리플레이 한 판 (개발 계획서 M3). [run] 으로 헤드리스 판을 돌린다.
class GoldenScenario {
  const GoldenScenario(this.name, this.run);

  final String name;
  final MatchResult Function() run;
}

const MatchRules _calm = MatchRules(waveLevel: 0);

MatchResult _sample(
  int seed,
  Controller left,
  Controller right, {
  MatchRules rules = const MatchRules(),
}) => runHeadless(
  seed: seed,
  rules: rules,
  blueprints: [sampleBlueprint(), sampleBlueprint()],
  decks: sampleDecks,
  costLimits: sampleCostLimits,
  pirates: goldenCatalog,
  left: left,
  right: right,
);

MatchResult _versus(
  String kind,
  Controller left, {
  MatchRules rules = _calm,
}) => runHeadless(
  seed: 11,
  rules: rules,
  blueprints: [sampleBlueprint(), sampleBlueprint()],
  decks: [
    [for (var i = 0; i < 4; i++) '$kind$i'],
    [for (var i = 0; i < 4; i++) 'r$i'],
  ],
  costLimits: const [15, 15],
  pirates: goldenCatalog,
  left: left,
  right: passController,
);

/// 물 위로 드러난 가장 낮은 블록, 뱃머리(쏘는 쪽)부터 (흘수선 공격).
(int, int)? _waterlineBlock(MatchState s) {
  final enemy = s.sides[1];
  final grid = enemy.grid;
  for (var y = 0; y < grid.height; y++) {
    // 수면 위로 반 칸 이상 드러난 줄만 노린다(겨우 드러난 칸은 탄이 닿기 어렵다).
    if ((y + 1) * cellUnit <= enemy.draft + cellUnit ~/ 2) continue;
    for (var x = grid.width - 1; x >= 0; x--) {
      if (grid.hasBlock(x, y)) return (x, y);
    }
  }
  return null;
}

(int, int)? _anyBlock(MatchState s) {
  final grid = s.sides[1].grid;
  for (var y = 0; y < grid.height; y++) {
    for (var x = 0; x < grid.width; x++) {
      if (grid.hasBlock(x, y)) return (x, y);
    }
  }
  return null;
}

(int, int)? _cabin(MatchState s) {
  final enemy = s.sides[1];
  for (var slot = 0; slot < enemy.crew.size; slot++) {
    if (enemy.crew.pirates[slot].status != PirateStatus.aboard) continue;
    final c = enemy.cabins[slot];
    return (c.x, c.y);
  }
  return null;
}

/// 무작위 골든 시드: 처음 4판 + CI 용 90판 (개발 계획서 M7 검증 “골든 리플레이 100개”).
final List<int> randomGoldenSeeds = [
  101,
  202,
  303,
  404,
  for (var i = 1; i <= 90; i++) 1000 + i,
];

/// 판 끝 방식마다 하나씩(6판) + 무작위 94판 = 100판.
final List<GoldenScenario> goldenScenarios = [
  GoldenScenario(
    'sunk_hull',
    () => _versus(
      'wrecker',
      shooter(_anyBlock),
      rules: const MatchRules(
        waveLevel: 0,
        waterlineDivisor: 1000,
        floodFullCell: 0,
        floodHalfCell: 0,
      ),
    ),
  ),
  GoldenScenario(
    'sunk_flood',
    () => _versus('sapper', shooter(_waterlineBlock)),
  ),
  GoldenScenario(
    'annihilation',
    () => _versus('killer', shooter(_cabin, highArc: true)),
  ),
  GoldenScenario(
    'time_decision_win',
    () => _versus(
      'gun',
      shooter((s) => s.turn <= 2 ? _waterlineBlock(s) : null),
    ),
  ),
  GoldenScenario(
    'time_decision_draw',
    () => _sample(5, passController, passController),
  ),
  GoldenScenario(
    'surrender',
    () => _sample(
      6,
      FnController(
        (s) => s.turn >= 3
            ? const [SurrenderCommand(t: 500)]
            : const [MoveCommand(t: 100, dx: 30), EndTurnCommand(t: 3000)],
      ),
      passController,
    ),
  ),
  for (final seed in randomGoldenSeeds)
    GoldenScenario(
      'random_$seed',
      () => _sample(seed, RandomController(seed), RandomController(seed + 1)),
    ),
];
