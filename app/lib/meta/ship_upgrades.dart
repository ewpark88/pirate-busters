import 'package:pb_sim/pb_sim.dart';

/// 배 해금 진행 (설계서 §3.2, §13.6, 금액: BALANCE.md A3.2). 슬루프 하나라 확장
/// 단계·선형 레벨·돛대 레벨은 없다 (ADR-111). 불변 값이고 `PlayerProgress.ship` 에
/// 담긴다.
class ShipUpgrades {
  const ShipUpgrades({this.materials = const []});

  /// JSON 에서 읽는다. 모르는 값·깨진 값은 기본값으로 본다. 옛 저장의 단계·레벨
  /// 값은 버린다.
  factory ShipUpgrades.fromJson(Object? raw) {
    if (raw is! Map) return const ShipUpgrades();
    final v = raw['materials'];
    return ShipUpgrades(
      materials: v is List
          ? v.whereType<String>().toList(growable: false)
          : const [],
    );
  }

  /// 골드로 연 재질 이름(처음부터 쓰는 [freeMaterials] 는 빠진다).
  final List<String> materials;

  /// 처음부터 쓰는 재질 (BALANCE.md A3.2).
  static const Set<BlockMaterial> freeMaterials = {
    BlockMaterial.pine,
    BlockMaterial.oak,
  };

  /// 재질을 여는 골드 (BALANCE.md A3.2).
  static const Map<BlockMaterial, int> materialGold = {BlockMaterial.iron: 300};

  bool hasMaterial(BlockMaterial m) =>
      freeMaterials.contains(m) || materials.contains(m.name);

  /// 슬루프 (설계서 §3.1).
  HullSpec get hull => HullSpec.sloop;

  /// 아직 열지 않은 재질은 소나무로 바꾼 설계도 (추천 설계도를 열린 것만으로 쓸 때,
  /// 설계서 §13.6). 블록은 그대로 두므로 지지·선실은 그대로다.
  Blueprint unlockedOnly(Blueprint b) => Blueprint(
    b.hull,
    [
      for (final c in b.cells)
        hasMaterial(c.material) ? c : BlockCell(c.x, c.y, BlockMaterial.pine),
    ],
    cabins: b.cabins,
    modules: b.modules,
  );

  ShipUpgrades copyWith({List<String>? materials}) =>
      ShipUpgrades(materials: materials ?? this.materials);

  Map<String, Object?> toJson() => {'materials': materials};
}
