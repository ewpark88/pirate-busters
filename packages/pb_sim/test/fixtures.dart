import 'package:pb_sim/pb_sim.dart';

/// 테스트용 슬루프 설계도 (비용 57/60). 선실은 2층(y = 2)에 4개.
Blueprint sampleBlueprint() => Blueprint(
  HullSpec.sloop,
  [
    for (var x = 0; x < 12; x++) BlockCell(x, 0, BlockMaterial.oak),
    for (var x = 0; x < 12; x++) BlockCell(x, 1, BlockMaterial.pine),
    const BlockCell(1, 2, BlockMaterial.cork),
    const BlockCell(2, 2, BlockMaterial.iron),
    for (var x = 3; x < 9; x++) BlockCell(x, 2, BlockMaterial.pine),
    const BlockCell(9, 2, BlockMaterial.iron),
    for (var x = 4; x < 8; x++) BlockCell(x, 3, BlockMaterial.net),
  ],
  cabins: sampleCabins,
);

const List<CabinCell> sampleCabins = [
  CabinCell(3, 2),
  CabinCell(5, 2),
  CabinCell(6, 2),
  CabinCell(8, 2),
];

/// 테스트용 해적. 투척(반경 1칸 폭발) 계열 기본값.
PirateSpec testPirate(
  String id, {
  int hp = 300,
  int reloadTicks = 90,
  int blockDamage = 60,
  int pirateDamage = 80,
  int blastRadius = 1,
}) => PirateSpec(
  id: id,
  hp: hp,
  reloadTicks: reloadTicks,
  blockDamage: blockDamage,
  pirateDamage: pirateDamage,
  blastRadius: blastRadius,
);

/// 샘플 덱에 나오는 해적. 재장전·피해를 조금씩 다르게 둔다.
final PirateCatalog sampleCatalog = PirateCatalog([
  testPirate('p01'),
  testPirate('p02', reloadTicks: 120, blockDamage: 40),
  testPirate('p06', blastRadius: 0, pirateDamage: 150, reloadTicks: 150),
  testPirate('p11', blastRadius: 0, blockDamage: 100),
  testPirate('p16', hp: 200),
  testPirate('p21', blockDamage: 90, reloadTicks: 180),
  testPirate('p26', hp: 150, blastRadius: 0),
  testPirate('p31', hp: 400, reloadTicks: 240),
  testPirate('p36', blockDamage: 20, pirateDamage: 20),
]);

const List<List<String>> sampleDecks = [
  ['p01', 'p06', 'p11', 'p16', 'p21'],
  ['p26', 'p31', 'p36', 'p02'],
];

/// [ticks] 동안 양쪽이 섞어 내는 커맨드. 재장전 중 발사·범위 밖 값·이동도 섞는다.
List<Command> sampleScript({int ticks = 1000, int scriptSeed = 7}) {
  final rng = XorShift32(scriptSeed);
  final out = <Command>[];
  for (var tick = 0; tick < ticks; tick++) {
    for (var side = 0; side < 2; side++) {
      if (!rng.nextChance(1, 6)) continue;
      final slot = rng.nextInt(5);
      final roll = rng.nextInt(8);
      if (roll == 0) {
        out.add(TapCommand(tick: tick, side: side, slot: slot));
      } else if (roll == 1) {
        out.add(
          MoveCommand(tick: tick, side: side, dir: rng.nextRange(-1, 2)),
        );
      } else {
        out.add(
          FireCommand(
            tick: tick,
            side: side,
            slot: slot,
            angle: rng.nextRange(20000, 70000),
            power: rng.nextRange(5000, 10500),
          ),
        );
      }
    }
  }
  return out;
}

Match newSampleMatch(int seed, {int wind = 0}) => Match.start(
  seed: seed,
  blueprints: [sampleBlueprint(), sampleBlueprint()],
  decks: sampleDecks,
  pirates: sampleCatalog,
  wind: wind,
);

/// 샘플 매치를 [ticks] 틱 돌린 뒤의 상태 해시.
int runSampleHash({required int seed, int ticks = 1000}) {
  final match = newSampleMatch(seed);
  final script = ScriptedController(sampleScript(ticks: ticks));
  runMatch(match, script, script, ticks: ticks);
  return hashMatchState(match.state);
}
