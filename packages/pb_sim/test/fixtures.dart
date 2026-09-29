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

/// 테스트용 해적. 일반 등급 투척(반경 1칸 폭발, 사거리 긺) 계열 기본값 (설계서 §2.8).
PirateSpec testPirate(
  String id, {
  Rarity rarity = Rarity.common,
  RangeGrade range = RangeGrade.long,
  int hp = 300,
  int cooldownTurns = 0,
  int blockDamage = 60,
  int pirateDamage = 80,
  int blastRadius = 1,
}) => PirateSpec(
  id: id,
  rarity: rarity,
  hp: hp,
  cooldownTurns: cooldownTurns,
  blockDamage: blockDamage,
  pirateDamage: pirateDamage,
  blastRadius: blastRadius,
  range: range,
);

/// 샘플 덱에 나오는 해적. 쿨다운·피해를 조금씩 다르게 둔다.
final List<PirateSpec> samplePirates = [
  testPirate('p01'),
  testPirate('p06', blastRadius: 0, pirateDamage: 150, cooldownTurns: 1),
  testPirate('p11', blastRadius: 0, blockDamage: 100),
  testPirate('p16', hp: 200),
  testPirate('p26', hp: 150, blastRadius: 0),
  testPirate('p31', hp: 400, cooldownTurns: 2, rarity: Rarity.rare),
  testPirate('p36', blockDamage: 20, pirateDamage: 20),
];

final PirateCatalog sampleCatalog = PirateCatalog(samplePirates);

/// 코스트: 왼쪽 일반 4명 = 12, 오른쪽 일반 2 + 희귀 1 = 10. 한도는 15.
const List<List<String>> sampleDecks = [
  ['p01', 'p06', 'p11', 'p16'],
  ['p26', 'p31', 'p36'],
];

const List<int> sampleCostLimits = [15, 15];

Match newSampleMatch(int seed, {MatchRules rules = const MatchRules()}) =>
    Match.start(
      seed: seed,
      rules: rules,
      blueprints: [sampleBlueprint(), sampleBlueprint()],
      decks: sampleDecks,
      costLimits: sampleCostLimits,
      pirates: sampleCatalog,
    );

/// 턴마다 스크립트 시드와 턴 번호로 커맨드를 섞어 내는 컨트롤러. 이동, 쿨다운 중
/// 발사, 범위 밖 값, 시간 초과, 빈 턴도 섞는다.
class RandomController implements Controller {
  RandomController(this.scriptSeed);

  final int scriptSeed;

  @override
  TurnBundle turnFor(MatchState state) {
    final rng = XorShift32(scriptSeed * 7919 + state.turn * 104729);
    final commands = <Command>[];
    var t = rng.nextRange(500, 4000);
    final actions = rng.nextInt(5);
    for (var i = 0; i < actions; i++) {
      final slot = rng.nextInt(5);
      if (rng.nextChance(1, 5)) {
        commands.add(TapCommand(t: t, slot: slot, tick: rng.nextInt(40)));
      } else if (rng.nextChance(1, 3)) {
        commands.add(MoveCommand(t: t, dx: rng.nextRange(-60, 61)));
      } else {
        commands.add(
          FireCommand(
            t: t,
            slot: slot,
            angle: rng.nextRange(20000, 70000),
            power: rng.nextRange(5000, 10500),
          ),
        );
      }
      t += rng.nextRange(500, 9000);
    }
    if (rng.nextChance(3, 4)) commands.add(EndTurnCommand(t: t));
    return TurnBundle(
      turn: state.turn,
      side: state.activeSide,
      commands: commands,
    );
  }
}

/// 턴마다 [build] 가 커맨드를 만드는 컨트롤러.
class FnController implements Controller {
  FnController(this.build);

  final List<Command> Function(MatchState state) build;

  @override
  TurnBundle turnFor(MatchState state) => TurnBundle(
    turn: state.turn,
    side: state.activeSide,
    commands: build(state),
  );
}

/// 아무것도 안 하고 바로 턴을 넘기는 컨트롤러.
final Controller passController = FnController(
  (_) => const [EndTurnCommand(t: 1000)],
);

/// 샘플 매치를 끝까지 돌린 뒤의 상태 해시.
int runSampleHash({required int seed, int scriptSeed = 7}) {
  final match = newSampleMatch(seed);
  runMatch(
    match,
    RandomController(scriptSeed),
    RandomController(scriptSeed + 1),
  );
  return hashMatchState(match.state);
}
