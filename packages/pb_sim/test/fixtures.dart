import 'package:pb_sim/pb_sim.dart';

/// 테스트용 슬루프 설계도 (비용 57/60).
Blueprint sampleBlueprint() => Blueprint(HullSpec.sloop, [
  for (var x = 0; x < 12; x++) BlockCell(x, 0, BlockMaterial.oak),
  for (var x = 0; x < 12; x++) BlockCell(x, 1, BlockMaterial.pine),
  const BlockCell(1, 2, BlockMaterial.cork),
  const BlockCell(2, 2, BlockMaterial.iron),
  for (var x = 3; x < 9; x++) BlockCell(x, 2, BlockMaterial.pine),
  const BlockCell(9, 2, BlockMaterial.iron),
  for (var x = 4; x < 8; x++) BlockCell(x, 3, BlockMaterial.net),
]);

const List<List<String>> sampleDecks = [
  ['p01', 'p06', 'p11', 'p16', 'p21'],
  ['p26', 'p31', 'p36', 'p02'],
];

/// [ticks] 동안 양쪽이 섞어 내는 커맨드. 재장전 중 발사·범위 밖 값도 섞는다.
List<Command> sampleScript({int ticks = 1000, int scriptSeed = 7}) {
  final rng = XorShift32(scriptSeed);
  final out = <Command>[];
  for (var tick = 0; tick < ticks; tick++) {
    for (var side = 0; side < 2; side++) {
      if (!rng.nextChance(1, 6)) continue;
      final slot = rng.nextInt(5);
      if (rng.nextChance(1, 4)) {
        out.add(TapCommand(tick: tick, side: side, slot: slot));
      } else {
        out.add(
          FireCommand(
            tick: tick,
            side: side,
            slot: slot,
            angle: rng.nextRange(-1000, 361000),
            power: rng.nextRange(0, 10500),
          ),
        );
      }
    }
  }
  return out;
}

Match newSampleMatch(int seed) => Match.start(
  seed: seed,
  blueprints: [sampleBlueprint(), sampleBlueprint()],
  decks: sampleDecks,
);

/// 샘플 매치를 [ticks] 틱 돌린 뒤의 상태 해시.
int runSampleHash({required int seed, int ticks = 1000}) {
  final match = newSampleMatch(seed);
  final script = ScriptedController(sampleScript(ticks: ticks));
  runMatch(match, script, script, ticks: ticks);
  return hashMatchState(match.state);
}
