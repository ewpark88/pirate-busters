import 'package:pb_sim/pb_sim.dart';

/// 배 업그레이드 진행 (설계서 §3.1 확장 단계, §3.3 돛대, §13.6 배 업그레이드는 모두
/// 골드, 금액: BALANCE.md A13.6·A3.2). 불변 값이고 `PlayerProgress.ship` 에 담긴다.
class ShipUpgrades {
  const ShipUpgrades({
    this.stage = 1,
    this.hullLevel = 1,
    this.materials = const [],
    this.modules = const [],
    this.mastLevels = const {},
  });

  /// JSON 에서 읽는다. 모르는 값·깨진 값은 기본값으로 본다.
  factory ShipUpgrades.fromJson(Object? raw) {
    if (raw is! Map) return const ShipUpgrades();
    int readInt(String key, int fallback, int max) {
      final v = raw[key];
      return v is int ? v.clamp(1, max) : fallback;
    }

    List<String> names(String key) {
      final v = raw[key];
      return v is List
          ? v.whereType<String>().toList(growable: false)
          : const [];
    }

    final levels = raw['mastLevels'];
    return ShipUpgrades(
      stage: readInt('stage', 1, HullSpec.maxStage),
      hullLevel: readInt('hullLevel', 1, HullSpec.maxLevel),
      materials: names('materials'),
      modules: names('modules'),
      mastLevels: levels is Map
          ? {
              for (final e in levels.entries)
                if (e.key is String && e.value is int)
                  e.key as String: (e.value! as int).clamp(
                    1,
                    BlockMaterial.maxRigLevel,
                  ),
            }
          : const {},
    );
  }

  /// 지은 확장 단계 1~4.
  final int stage;

  /// 선형 레벨 1~50.
  final int hullLevel;

  /// 골드로 연 재질 이름(처음부터 쓰는 [freeMaterials] 는 빠진다).
  final List<String> materials;

  /// 골드로 연 모듈·돛대 종류 이름([ModuleKind.jsonName]).
  final List<String> modules;

  /// 돛대 종류 이름 → 레벨 2~5. 없으면 1.
  final Map<String, int> mastLevels;

  /// 처음부터 쓰는 재질·모듈 (설계서 §13.6).
  static const Set<BlockMaterial> freeMaterials = {
    BlockMaterial.pine,
    BlockMaterial.oak,
  };
  static const Set<ModuleKind> freeModules = {
    ModuleKind.captain,
    ModuleKind.pump,
    ModuleKind.mast,
    ModuleKind.mastBamboo,
  };

  /// 확장 단계를 여는 스테이지 (BALANCE.md A3.1). 3단계는 1-8 이 없으면 1-5.
  static const Map<int, List<String>> stageClears = {
    2: ['1-4'],
    3: ['1-8', '1-5'],
    4: ['1-12'],
  };

  /// 금액 (BALANCE.md A13.6·A3.2·B11 무과금 경제, 임시값).
  static const Map<int, int> stageGold = {2: 150, 3: 300, 4: 500};
  // 해금 층: 1층(해역 1)·2층(해역 2)·3층(해역 3) 금액 (BALANCE.md A13.6, ADR-086).
  static const Map<BlockMaterial, int> materialGold = {
    BlockMaterial.net: 100,
    BlockMaterial.cork: 300,
    BlockMaterial.iron: 600,
  };
  static const Map<ModuleKind, int> moduleGold = {
    ModuleKind.workshop: 150,
    ModuleKind.gunPort: 150,
    ModuleKind.mastOak: 150,
    ModuleKind.lookout: 300,
    ModuleKind.fuelTank: 300,
    ModuleKind.mastCrow: 400,
    ModuleKind.magazine: 600,
    ModuleKind.mastIron: 700,
  };
  static const Map<int, int> mastLevelGold = {2: 100, 3: 200, 4: 400, 5: 800};

  /// 선형 레벨 [to] 로 올리는 골드 (A13.7 레벨업 골드 표와 같은 구간 값).
  static int hullLevelGold(int to) {
    const first = [100, 250, 500, 800, 1200, 1800, 2600, 3700, 5000];
    if (to <= 10) return first[to - 2];
    final (base, step, from) = switch (to) {
      <= 20 => (6000, 2000, 11),
      <= 30 => (28000, 4000, 21),
      <= 40 => (70000, 6000, 31),
      _ => (132000, 8000, 41),
    };
    return base + step * (to - from);
  }

  /// [hasCleared] 로 본 지금 열린 가장 큰 단계. [hasStage] 는 캠페인에 있는 스테이지인가.
  static int openedStage(
    bool Function(String id) hasCleared,
    bool Function(String id) hasStage,
  ) {
    var open = 1;
    for (var s = 2; s <= HullSpec.maxStage; s++) {
      final need = stageClears[s]!.firstWhere(hasStage, orElse: () => '');
      if (need.isEmpty || !hasCleared(need)) break;
      open = s;
    }
    return open;
  }

  bool hasMaterial(BlockMaterial m) =>
      freeMaterials.contains(m) || materials.contains(m.name);

  bool hasModule(ModuleKind k) =>
      freeModules.contains(k) || modules.contains(k.jsonName);

  int mastLevel(ModuleKind k) => mastLevels[k.jsonName] ?? 1;

  /// 지금 단계·선형 레벨의 슬루프.
  HullSpec get hull => HullSpec.byId('sloop', stage: stage, level: hullLevel);

  /// 전투에 넘길 설계도: 선형 레벨과 돛대 레벨을 찍는다(설계서 §3.3·§3.5·§13.6).
  Blueprint stamp(Blueprint b) => Blueprint(
    HullSpec.byId(b.hull.id, stage: b.hull.stage, level: hullLevel),
    b.cells,
    cabins: b.cabins,
    modules: [
      for (final m in b.modules)
        ModuleCell(
          m.x,
          m.y,
          m.kind,
          level: m.kind.isMast ? mastLevel(m.kind) : 1,
        ),
    ],
  );

  /// 아직 열지 않은 재질은 소나무로, 열지 않은 모듈은 뺀 설계도 (추천 설계도를 열린
  /// 것만으로 쓸 때, 설계서 §13.6). 블록은 그대로 두므로 지지·선실은 그대로다.
  Blueprint unlockedOnly(Blueprint b) => Blueprint(
    b.hull,
    [
      for (final c in b.cells)
        hasMaterial(c.material) ? c : BlockCell(c.x, c.y, BlockMaterial.pine),
    ],
    cabins: b.cabins,
    modules: [
      for (final m in b.modules)
        if (hasModule(m.kind)) m,
    ],
  );

  ShipUpgrades copyWith({
    int? stage,
    int? hullLevel,
    List<String>? materials,
    List<String>? modules,
    Map<String, int>? mastLevels,
  }) => ShipUpgrades(
    stage: stage ?? this.stage,
    hullLevel: hullLevel ?? this.hullLevel,
    materials: materials ?? this.materials,
    modules: modules ?? this.modules,
    mastLevels: mastLevels ?? this.mastLevels,
  );

  Map<String, Object?> toJson() => {
    'stage': stage,
    'hullLevel': hullLevel,
    'materials': materials,
    'modules': modules,
    'mastLevels': mastLevels,
  };
}
