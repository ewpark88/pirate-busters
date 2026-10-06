/// 블록 재질 5종 (설계서 §3.2)과 돛대 칸 재질 5종(§3.3, 블록으로는 못 쓴다). 무게는 ×1000 정수(망사 0.5 → 500).
///
/// 순서(index)는 격자·해시·리플레이에 쓰이므로 바꾸지 않는다. 새 재질은 뒤에 붙인다.
enum BlockMaterial {
  /// 소나무 판자: 싸고 가벼움, 불에 약함.
  pine(durability: 40, weight: 500, cost: 1, weakToFire: true),

  /// 참나무: 기본 구조재.
  oak(durability: 80, weight: 2000, cost: 2),

  /// 철판: 불 면역, 무거움.
  iron(durability: 160, weight: 5000, cost: 4, fireImmune: true),

  /// 코르크 부력재: 배를 들어올림(흘수선 상승).
  cork(durability: 30, weight: -2000, cost: 3, buoyant: true),

  /// 망사(돛): 포탄 감속, 공중 공격 차단.
  net(durability: 20, weight: 500, cost: 1, slowsShots: true, blocksAir: true),

  /// 돛대 칸 (설계서 §3.3, BALANCE.md A3.2 돛대 종류 표). 돛대 모듈이 세우고, 무게·
  /// 비용은 돛대 모듈 쪽에 있다. 내구도는 돛대 레벨마다 더한다([rigLevelBonus]).
  rigBamboo(durability: 20, weight: 0, cost: 0, rig: true),
  rigPine(durability: 30, weight: 0, cost: 0, rig: true, weakToFire: true),
  rigOak(durability: 45, weight: 0, cost: 0, rig: true),
  rigIron(durability: 60, weight: 0, cost: 0, rig: true, fireImmune: true),
  rigCrow(durability: 35, weight: 0, cost: 0, rig: true);

  const BlockMaterial({
    required this.durability,
    required this.weight,
    required this.cost,
    this.weakToFire = false,
    this.fireImmune = false,
    this.buoyant = false,
    this.slowsShots = false,
    this.blocksAir = false,
    this.rig = false,
  });

  /// 돛대 레벨 1 위로 한 레벨마다 돛대 칸 내구도 + (BALANCE.md A3.2 돛대 업그레이드).
  static const int rigLevelBonus = 10;

  /// 돛대 레벨 상한.
  static const int maxRigLevel = 5;

  /// 최대 내구도.
  final int durability;

  /// 무게 ×1000. 음수면 부력.
  final int weight;

  /// 건조 포인트 비용.
  final int cost;

  final bool weakToFire;
  final bool fireImmune;
  final bool buoyant;
  final bool slowsShots;
  final bool blocksAir;

  /// 돛대 칸 재질인가. 설계도 블록으로는 쓰지 않는다.
  final bool rig;

  /// 블록으로 쓰는 재질 5종 (조선소 팔레트·설계도).
  static List<BlockMaterial> get blocks => [
    for (final m in values)
      if (!m.rig) m,
  ];

  /// 돛대 레벨 [level] 의 칸 최대 내구도. 블록 재질은 레벨과 무관하다.
  int durabilityAt(int level) =>
      rig ? durability + rigLevelBonus * (level - 1) : durability;

  /// 이름으로 찾는다. 없으면 [FormatException].
  static BlockMaterial byName(String name) {
    for (final m in values) {
      if (m.name == name) return m;
    }
    throw FormatException('알 수 없는 재질: $name');
  }
}
