import 'package:pb_sim/src/match/rules.dart';
import 'package:pb_sim/src/ship/blueprint.dart';
import 'package:pb_sim/src/ship/hull.dart';
import 'package:pb_sim/src/ship/material.dart';
import 'package:pb_sim/src/ship/module.dart';

/// 무게 연료 최대 증가(‰): 철판으로만 지은 배가 +20% (설계서 §2.7, BALANCE.md A2.7).
const int weightFuelMaxPermille = 200;

/// 연료통 한 개의 탱크 증가 (BALANCE.md A3.3).
const int fuelTankBonus = 40;

/// 블록 무게 합(×1000). 코르크는 음수라 배를 띄운다 (설계서 §3.2).
int totalWeight(Iterable<BlockCell> cells) {
  var w = 0;
  for (final c in cells) {
    w += c.material.weight;
  }
  return w;
}

/// 배 무게(×1000): 블록 + 돛대(설계서 §3.3, BALANCE.md A3.2).
int shipWeight(Iterable<BlockCell> cells, Iterable<ModuleCell> modules) {
  var w = totalWeight(cells);
  for (final m in modules) {
    w += m.kind.weight;
  }
  return w;
}

/// 흘수선 높이(1/1000칸): (총무게 − 부력재) ÷ (선형 폭 × 나눗수) (설계서 §3.4).
int waterlineOfWeight(HullSpec hull, int weight, MatchRules rules) {
  final h = weight ~/ (hull.width * rules.waterlineDivisor);
  return h < 0 ? 0 : h;
}

/// 무게에 따른 1칸당 연료 배율(‰): 1000 + 200 × 총무게 ÷ 선형 최대 무게. 최대 무게는
/// 건조 포인트를 모두 철판으로 채운 무게다 (설계서 §2.7).
int weightFuelPermille(HullSpec hull, int weight) {
  if (weight <= 0) return 1000;
  const iron = BlockMaterial.iron;
  final max = hull.buildPoints ~/ iron.cost * iron.weight;
  final w = weight > max ? max : weight;
  return 1000 + weightFuelMaxPermille * w ~/ max;
}

/// 조선소 화면의 수치 (설계서 §13.6): 완성되지 않은 설계도로도 계산한다.
class ShipStats {
  ShipStats._({
    required this.cost,
    required this.weight,
    required this.waterline,
    required this.fuelPermille,
    required this.tank,
    required this.modulesCounted,
    required this.captains,
  });

  factory ShipStats.of(
    HullSpec hull,
    Iterable<BlockCell> cells,
    Iterable<ModuleCell> modules, {
    MatchRules rules = const MatchRules(),
  }) {
    var cost = 0;
    for (final c in cells) {
      cost += c.material.cost;
    }
    var counted = 0;
    var captains = 0;
    var tanks = 0;
    for (final m in modules) {
      cost += m.kind.cost;
      if (m.kind.countsToLimit) counted++;
      if (m.kind == ModuleKind.captain) captains++;
      if (m.kind == ModuleKind.fuelTank) tanks++;
    }
    final weight = shipWeight(cells, modules);
    return ShipStats._(
      cost: cost,
      weight: weight,
      waterline: waterlineOfWeight(hull, weight, rules),
      fuelPermille: weightFuelPermille(hull, weight),
      tank: hull.fuelTank + tanks * fuelTankBonus,
      modulesCounted: counted,
      captains: captains,
    );
  }

  /// 건조 포인트 합계(블록 + 모듈).
  final int cost;

  /// 총무게(×1000).
  final int weight;

  /// 흘수선 높이(1/1000칸).
  final int waterline;

  /// 1칸당 연료 배율(‰).
  final int fuelPermille;

  /// 연료 탱크.
  final int tank;

  /// 기능 모듈 한도에 세는 모듈 수.
  final int modulesCounted;

  /// 선장실 수.
  final int captains;
}
