import 'package:pb_sim/pb_sim.dart';

/// 선원 목록 필터 (설계서 §13.7, A63): 등급·계열·탄종. 묶음이 비어 있으면 전부이고,
/// 같은 묶음 안은 하나라도 맞으면(합집합), 묶음끼리는 모두 맞아야(교집합) 남는다.
/// 레벨 필터·정렬은 해적 레벨(R4)이 생길 때 넣는다.
class CrewFilter {
  const CrewFilter({
    this.rarities = const {},
    this.families = const {},
    this.ammos = const {},
  });

  final Set<Rarity> rarities;
  final Set<Family> families;
  final Set<AmmoType> ammos;

  bool get isEmpty => rarities.isEmpty && families.isEmpty && ammos.isEmpty;

  /// 해적 [spec] 이 남는가.
  bool matches(PirateSpec spec) =>
      (rarities.isEmpty || rarities.contains(spec.rarity)) &&
      (families.isEmpty || families.contains(spec.family)) &&
      (ammos.isEmpty || ammos.contains(spec.ammo));

  CrewFilter toggleRarity(Rarity r) => CrewFilter(
    rarities: _flip(rarities, r),
    families: families,
    ammos: ammos,
  );

  CrewFilter toggleFamily(Family f) => CrewFilter(
    rarities: rarities,
    families: _flip(families, f),
    ammos: ammos,
  );

  CrewFilter toggleAmmo(AmmoType a) => CrewFilter(
    rarities: rarities,
    families: families,
    ammos: _flip(ammos, a),
  );

  static Set<T> _flip<T>(Set<T> set, T v) =>
      set.contains(v) ? ({...set}..remove(v)) : {...set, v};
}
