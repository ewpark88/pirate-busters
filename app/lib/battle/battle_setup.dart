import 'package:pb_sim/pb_sim.dart';

/// M4 첫 플레이어블의 고정 판 구성 (개발 계획서 M4, ADR-029).
///
/// 해적 데이터(`pb_data`)는 M5 에서 들어온다. 그전까지 해적 4종의 전투 수치와
/// 그림 종족을 여기에 임시로 둔다.
abstract final class BattleSetup {
  /// 추천 설계도 전의 고정 슬루프. 용골(참나무) + 선체(소나무) + 3층 선실 줄 + 돛(망사).
  static Blueprint sloop() => Blueprint(
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
    cabins: const [
      CabinCell(3, 2),
      CabinCell(5, 2),
      CabinCell(6, 2),
      CabinCell(8, 2),
    ],
  );

  /// 임시 해적 4종. 코스트 합계 12 (일반 4명, 한도 15).
  static final List<PirateSpec> pirates = [
    const PirateSpec(
      id: 'octo',
      rarity: Rarity.common,
      hp: 300,
      cooldownTurns: 0,
      blockDamage: 60,
      pirateDamage: 80,
      blastRadius: 1,
      range: RangeGrade.long,
    ),
    const PirateSpec(
      id: 'bones',
      rarity: Rarity.common,
      hp: 260,
      cooldownTurns: 1,
      blockDamage: 40,
      pirateDamage: 150,
      range: RangeGrade.veryLong,
    ),
    const PirateSpec(
      id: 'sword',
      rarity: Rarity.common,
      hp: 320,
      cooldownTurns: 0,
      blockDamage: 100,
      pirateDamage: 60,
    ),
    const PirateSpec(
      id: 'otter',
      rarity: Rarity.common,
      hp: 280,
      cooldownTurns: 0,
      blockDamage: 70,
      pirateDamage: 70,
      range: RangeGrade.long,
    ),
  ];

  static final PirateCatalog catalog = PirateCatalog(pirates);

  static const List<String> deck = ['octo', 'bones', 'sword', 'otter'];

  static const int costLimit = 15;

  /// 해적 id → 그림 캐릭터 id (`assets/images/characters/<id>`). 지금은 같다.
  static String speciesOf(String pirateId) => pirateId;

  /// 새 판. [seed] 로 선공·바람이 정해진다.
  static Match newMatch(int seed, {MatchRules rules = const MatchRules()}) =>
      Match.start(
        seed: seed,
        rules: rules,
        blueprints: [sloop(), sloop()],
        decks: const [deck, deck],
        costLimits: const [costLimit, costLimit],
        pirates: catalog,
      );
}
