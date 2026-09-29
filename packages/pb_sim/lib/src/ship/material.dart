/// 블록 재질 5종 (설계서 §3.2). 무게는 ×1000 정수(망사 0.5 → 500).
///
/// 순서(index)는 격자·해시·리플레이에 쓰이므로 바꾸지 않는다. 새 재질은 뒤에 붙인다.
enum BlockMaterial {
  /// 소나무 판자: 싸고 가벼움, 불에 약함.
  pine(durability: 40, weight: 1000, cost: 1, weakToFire: true),

  /// 참나무: 기본 구조재.
  oak(durability: 80, weight: 2000, cost: 2),

  /// 철판: 불 면역, 무거움.
  iron(durability: 150, weight: 4000, cost: 4, fireImmune: true),

  /// 코르크 부력재: 배를 들어올림(흘수선 상승).
  cork(durability: 30, weight: -2000, cost: 3, buoyant: true),

  /// 망사(돛): 포탄 감속, 공중 공격 차단.
  net(durability: 20, weight: 500, cost: 1, slowsShots: true, blocksAir: true);

  const BlockMaterial({
    required this.durability,
    required this.weight,
    required this.cost,
    this.weakToFire = false,
    this.fireImmune = false,
    this.buoyant = false,
    this.slowsShots = false,
    this.blocksAir = false,
  });

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

  /// 이름으로 찾는다. 없으면 [FormatException].
  static BlockMaterial byName(String name) {
    for (final m in values) {
      if (m.name == name) return m;
    }
    throw FormatException('알 수 없는 재질: $name');
  }
}
