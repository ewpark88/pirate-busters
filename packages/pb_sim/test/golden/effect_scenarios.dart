import 'package:pb_sim/pb_sim.dart';

import '../aim.dart';
import '../fixtures.dart';

/// 턴 효과·전설 능력이 들어가는 골든 판에 쓰는 해적. 수치는 `app/assets/game` 실제
/// 데이터를 `pb_data` 로 읽은 값과 같다(BALANCE.md A4.2·A4.3·A4.8).
PirateSpec _p(
  String id,
  Rarity rarity,
  Family family,
  AmmoType ammo, {
  required int hp,
  required int block,
  required int pirate,
  int radius = 0,
  int value = 0,
  Ability ability = Ability.none,
  int abilityValue = 0,
}) => PirateSpec(
  id: id,
  rarity: rarity,
  hp: hp,
  blockDamage: block,
  pirateDamage: pirate,
  blastRadius: radius,
  family: family,
  ammo: ammo,
  ammoValue: value,
  ability: ability,
  abilityValue: abilityValue,
);

final List<PirateSpec> effectPirates = [
  _p(
    'g_puffy',
    Rarity.common,
    Family.underwater,
    AmmoType.mine,
    hp: 220,
    block: 75,
    pirate: 75,
    radius: 1,
    value: 1,
  ),
  _p(
    'g_sharky',
    Rarity.common,
    Family.assault,
    AmmoType.assault,
    hp: 280,
    block: 30,
    pirate: 135,
    radius: 1,
    value: 1,
  ),
  _p(
    'g_kraki',
    Rarity.legend,
    Family.underwater,
    AmmoType.mine,
    hp: 319,
    block: 108,
    pirate: 108,
    radius: 2,
    value: 2,
    ability: Ability.tentacle,
    abilityValue: 2,
  ),
  _p(
    'g_tok',
    Rarity.common,
    Family.shock,
    AmmoType.shock,
    hp: 260,
    block: 30,
    pirate: 45,
    radius: 2,
    value: 1,
  ),
  _p(
    'g_pang',
    Rarity.common,
    Family.direct,
    AmmoType.sniper,
    hp: 220,
    block: 90,
    pirate: 150,
    value: 120,
  ),
  _p(
    'g_octo',
    Rarity.common,
    Family.lob,
    AmmoType.explosive,
    hp: 240,
    block: 60,
    pirate: 120,
    radius: 1,
    value: 30,
  ),
  _p(
    'g_moby',
    Rarity.legend,
    Family.pierce,
    AmmoType.pierce,
    hp: 377,
    block: 108,
    pirate: 152,
    value: 5,
    ability: Ability.pull,
    abilityValue: 3,
  ),
  _p(
    'g_lamp',
    Rarity.legend,
    Family.shock,
    AmmoType.shock,
    hp: 377,
    block: 43,
    pirate: 65,
    radius: 2,
    value: 1,
    ability: Ability.shove,
    abilityValue: 2,
  ),
  _p(
    'g_davy',
    Rarity.legend,
    Family.assault,
    AmmoType.assault,
    hp: 406,
    block: 43,
    pirate: 195,
    radius: 2,
    value: 2,
    ability: Ability.summon,
    abilityValue: 3,
  ),
  _p(
    'g_bones',
    Rarity.rare,
    Family.direct,
    AmmoType.sniper,
    hp: 242,
    block: 99,
    pirate: 165,
    value: 125,
  ),
];

/// 왼쪽: 설치탄·강습·크라키·충격탄, 망대(5번째)에 저격수.
const List<String> effectDeckLeft = [
  'g_puffy',
  'g_sharky',
  'g_kraki',
  'g_tok',
  'g_pang',
];

/// 오른쪽: 돛대를 노리는 폭발탄·모비·램프·데비, 망대에 저격수.
const List<String> effectDeckRight = [
  'g_octo',
  'g_moby',
  'g_lamp',
  'g_davy',
  'g_bones',
];

/// 해적이 쏠 칸: 폭발탄은 상대 돛대가 서 있으면 돛대 칸, [captain] 이면 저격수 말고는
/// 선장실, 그 밖에는 살아 있는 해적의 선실(없으면 선장실).
(int, int)? _targetFor(MatchState s, PirateSpec spec, {required bool captain}) {
  final enemy = s.otherOf(s.activeSide);
  (int, int)? captainCell() {
    for (final m in enemy.modules.list) {
      if (m.kind == ModuleKind.captain) return (m.x, m.y);
    }
    return null;
  }

  if (spec.ammo == AmmoType.explosive) {
    for (final m in enemy.modules.list) {
      if (m.kind.isMast && m.intact) return (m.x, m.y + 2);
    }
  }
  if (captain && spec.ammo != AmmoType.sniper) return captainCell();
  for (var slot = 0; slot < enemy.crew.size; slot++) {
    if (enemy.crew.pirates[slot].status != PirateStatus.aboard) continue;
    final c = enemy.cabins[slot];
    return (c.x, c.y);
  }
  return captainCell();
}

/// 내 턴마다 쏠 해적을 차례로 돌려 가며 한 발 쏜다. [quitAfter] 턴이 지나면 쏘지
/// 않고 넘긴다(턴 제한 판). [move] 면 쏘기 전에 조금 움직인다.
Controller effectShooter({
  int quitAfter = 1 << 20,
  bool move = false,
  bool captain = false,
}) => FnController((s) {
  final side = s.sides[s.activeSide];
  final out = <Command>[
    if (move) MoveCommand(t: 300, dx: s.turn.isEven ? 10 : -10),
  ];
  if (s.turn <= quitAfter) {
    final n = side.crew.size;
    for (var k = 0; k < n; k++) {
      final slot = (s.turn ~/ 2 + k) % n;
      if (!side.canFire(slot)) continue;
      final spec = side.crew.pirates[slot].spec;
      final cell = _targetFor(s, spec, captain: captain);
      if (cell == null) break;
      final fire = tryAimAt(s, slot: slot, tx: cell.$1, ty: cell.$2, t: 2000);
      if (fire == null) continue;
      out.add(fire);
      break;
    }
  }
  return [...out, const EndTurnCommand(t: 9000)];
});

/// 턴 효과 골든 판: 두 배 모두 실제 데이터 해적 5명(망대 포함)이 차례로 쏜다.
/// [captainHunt] 면 왼쪽이 선장실을 노린다.
MatchResult runEffectMatch(
  int seed, {
  required PirateCatalog pirates,
  int quitAfter = 1 << 20,
  bool move = false,
  bool captainHunt = false,
}) => runHeadless(
  seed: seed,
  blueprints: [sampleBlueprint(), sampleBlueprint()],
  decks: const [effectDeckLeft, effectDeckRight],
  costLimits: const [40, 40],
  pirates: pirates,
  left: effectShooter(quitAfter: quitAfter, move: move, captain: captainHunt),
  right: effectShooter(quitAfter: quitAfter, move: move),
);

/// 턴 효과 골든 판: (이름, 시드, 쏘기를 멈추는 턴, 이동, 선장실 노리기). 판 끝이
/// 양쪽 전멸 승·선장실 파괴·턴 제한·이동 섞인 판으로 고르게 나오게 골랐다.
const List<(String, int, int, bool, bool)> effectGoldens = [
  ('effects_annihilation_right', 8, 1 << 20, false, false),
  ('effects_annihilation_left', 2, 1 << 20, false, false),
  ('effects_captain_lost', 1, 1 << 20, false, true),
  ('effects_time_decision', 2, 8, false, false),
  ('effects_moving', 4, 1 << 20, true, false),
];
