/// 블록 재질 3종 (설계서 §3.2)과 돛대 칸 재질(§3.3, 블록으로는 못 쓴다).
///
/// 순서(index)는 격자·해시·리플레이에 쓰이므로 바꾸지 않는다. 새 재질은 뒤에 붙인다.
/// 수치는 BALANCE.md A3.2·A3.3 (ADR-111).
enum BlockMaterial {
  /// 소나무: 싸고 약하다.
  pine(durability: 40, cost: 1),

  /// 참나무: 기본 구조재.
  oak(durability: 80, cost: 2),

  /// 철판: 비싸고 단단하다.
  iron(durability: 160, cost: 4),

  /// 돛대 칸. 돛대 모듈이 세운다 (설계서 §3.3).
  rigPine(durability: 30, cost: 0, rig: true);

  const BlockMaterial({
    required this.durability,
    required this.cost,
    this.rig = false,
  });

  /// 최대 내구도.
  final int durability;

  /// 건조 포인트 비용.
  final int cost;

  /// 돛대 칸 재질인가. 설계도 블록으로는 쓰지 않는다.
  final bool rig;

  /// 블록으로 쓰는 재질 3종 (조선소 팔레트·설계도).
  static List<BlockMaterial> get blocks => [
    for (final m in values)
      if (!m.rig) m,
  ];

  /// 이름으로 찾는다. 없으면 [FormatException].
  static BlockMaterial byName(String name) {
    for (final m in values) {
      if (m.name == name) return m;
    }
    throw FormatException('알 수 없는 재질: $name');
  }
}
