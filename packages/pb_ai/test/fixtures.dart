import 'package:pb_sim/pb_sim.dart';

/// 테스트용 슬루프(pb_sim 테스트 fixture 와 같은 기준 배 A, BALANCE.md B1).
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
  cabins: const [
    CabinCell(3, 2),
    CabinCell(5, 2),
    CabinCell(6, 2),
    CabinCell(8, 2),
  ],
  modules: const [ModuleCell(11, 1, ModuleKind.captain)],
);

PirateSpec _p(
  String id, {
  Family family = Family.lob,
  AmmoType ammo = AmmoType.explosive,
  int value = 50,
  RangeGrade range = RangeGrade.long,
  int block = 40,
  int pirate = 80,
  int radius = 1,
  int param = 0,
  int spread = 0,
  Rarity rarity = Rarity.common,
}) => PirateSpec(
  id: id,
  rarity: rarity,
  hp: 240,
  cooldownTurns: 0,
  blockDamage: block,
  pirateDamage: pirate,
  blastRadius: radius,
  range: range,
  family: family,
  ammo: ammo,
  ammoValue: value,
  spreadMdeg: spread,
  ammoParam: param,
);

final PirateCatalog catalog = PirateCatalog([
  _p('octo'),
  _p('uni', ammo: AmmoType.split, value: 4, spread: 25000, rarity: Rarity.hero),
  _p(
    'pang',
    family: Family.direct,
    ammo: AmmoType.sniper,
    value: 150,
    range: RangeGrade.medium,
    block: 60,
    pirate: 100,
    radius: 0,
  ),
  _p(
    'suri',
    family: Family.skip,
    ammo: AmmoType.skip,
    value: 2,
    block: 30,
    pirate: 60,
    radius: 0,
  ),
  _p(
    'tok',
    family: Family.support,
    ammo: AmmoType.support,
    value: 100,
    range: RangeGrade.short,
    block: 0,
    pirate: 0,
    radius: 0,
    param: 3,
  ),
]);

Match newMatch(
  int seed, {
  List<String> left = const ['octo', 'pang'],
  List<String> right = const ['octo', 'suri'],
}) => Match.start(
  seed: seed,
  blueprints: [sampleBlueprint(), sampleBlueprint()],
  decks: [left, right],
  costLimits: const [15, 15],
  pirates: catalog,
);
