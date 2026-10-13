import 'package:pb_sim/pb_sim.dart';

/// 테스트용 슬루프(pb_sim 테스트 fixture 와 같은 배): 선장실 (1, 1), 돛대 (0, 2).
Blueprint sampleBlueprint() => Blueprint(
  HullSpec.sloop,
  [
    for (var x = 0; x < 12; x++) BlockCell(x, 0, BlockMaterial.oak),
    for (var x = 0; x < 12; x++) BlockCell(x, 1, BlockMaterial.pine),
    const BlockCell(0, 2, BlockMaterial.oak),
    const BlockCell(2, 2, BlockMaterial.iron),
    for (var x = 3; x < 9; x++) BlockCell(x, 2, BlockMaterial.pine),
    const BlockCell(9, 2, BlockMaterial.iron),
    for (var x = 4; x < 8; x++) BlockCell(x, 3, BlockMaterial.pine),
  ],
  cabins: const [
    CabinCell(3, 2),
    CabinCell(5, 2),
    CabinCell(6, 2),
    CabinCell(8, 2),
  ],
  modules: const [
    ModuleCell(1, 1, ModuleKind.captain),
    ModuleCell(0, 2, ModuleKind.mast),
  ],
);

PirateSpec _p(
  String id, {
  Family family = Family.lob,
  AmmoType ammo = AmmoType.explosive,
  int value = 50,
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
  blockDamage: block,
  pirateDamage: pirate,
  blastRadius: radius,
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
    family: Family.shock,
    ammo: AmmoType.shock,
    value: 1,
    block: 20,
    pirate: 30,
    radius: 2,
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
