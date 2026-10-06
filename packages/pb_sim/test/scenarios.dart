import 'package:pb_sim/pb_sim.dart';

import 'aim.dart';
import 'fixtures.dart';

/// 판이 끝날 때까지 턴을 두며 모든 턴의 이벤트를 모은다.
List<SimEvent> runToEnd(Match m, Controller left, Controller right) {
  final all = <SimEvent>[];
  while (!m.isOver) {
    final s = m.state;
    m.playTurn((s.activeSide == 0 ? left : right).turnFor(s));
    all.addAll(s.events);
  }
  return all;
}

Iterable<SimEvent> eventsOf(
  List<SimEvent> events,
  SimEventKind kind,
  int side,
) => events.where((e) => e.kind == kind && e.side == side);

/// 쏠 수 있는 해적 2명까지 [target] 이 고른 칸을 노린다. 노릴 칸이 없으면 턴을 넘긴다.
Controller shooter(
  (int, int)? Function(MatchState s) target, {
  bool highArc = false,
}) => FnController((s) {
  final crew = s.sides[s.activeSide].crew;
  final cell = target(s);
  final out = <Command>[];
  for (var slot = 0; slot < crew.size && cell != null; slot++) {
    if (!s.sides[s.activeSide].canFire(slot) || out.length == 2) continue;
    out.add(
      aimAt(
        s,
        slot: slot,
        tx: cell.$1,
        ty: cell.$2,
        t: 1000 + out.length * 1000,
        highArc: highArc,
      ),
    );
  }
  return [...out, const EndTurnCommand(t: 9000)];
});

/// 오른쪽 배: 용골 + 뱃머리 쪽(x = 11) 벽 + (4, 1..2) 기둥 위 (2..6, 3) 판.
Blueprint towerBlueprint() => Blueprint(
  boxSloop,
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
  modules: const [ModuleCell(0, 0, ModuleKind.captain)],
);

/// 시나리오용 해적: 역할(gun·killer·wrecker·sapper)마다 4명, 오른쪽 기본 r0~r3.
final List<PirateSpec> scenarioPirates = [
  for (var i = 0; i < 4; i++) testPirate('gun$i', blockDamage: 100),
  for (var i = 0; i < 4; i++) testPirate('killer$i', pirateDamage: 1000),
  for (var i = 0; i < 4; i++)
    testPirate('wrecker$i', blockDamage: 1000, blastRadius: 3),
  for (var i = 0; i < 4; i++) testPirate('r$i'),
  for (var i = 0; i < 4; i++)
    testPirate('sapper$i', blockDamage: 100, pirateDamage: 0),
];

final PirateCatalog scenarioCatalog = PirateCatalog(scenarioPirates);

/// 타격 시나리오는 파도 없이 돌린다(파도는 wave_test). 한 턴 두 발을 미리 조준하므로
/// 첫 발의 비행 정지 시간을 몰라 파도 위상이 어긋난다.
Match startScenario(
  String kind,
  Blueprint right, {
  MatchRules rules = const MatchRules(waveLevel: 0),
}) => Match.start(
  seed: 11,
  rules: rules,
  blueprints: [sampleBlueprint(), right],
  decks: [
    [for (var i = 0; i < 4; i++) '$kind$i'],
    [for (var i = 0; i < 4; i++) 'r$i'],
  ],
  costLimits: const [15, 15],
  pirates: scenarioCatalog,
);
