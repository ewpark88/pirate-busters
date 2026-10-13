import 'package:pb_sim/src/ship/blueprint.dart';
import 'package:pb_sim/src/ship/module.dart';

/// 조선소 화면의 수치 (설계서 §13.6): 완성되지 않은 설계도로도 계산한다.
class ShipStats {
  ShipStats._({
    required this.cost,
    required this.captains,
    required this.masts,
  });

  factory ShipStats.of(
    Iterable<BlockCell> cells,
    Iterable<ModuleCell> modules,
  ) {
    var cost = 0;
    for (final c in cells) {
      cost += c.material.cost;
    }
    var captains = 0;
    var masts = 0;
    for (final m in modules) {
      cost += m.kind.cost;
      if (m.kind == ModuleKind.captain) captains++;
      if (m.kind.isMast) masts++;
    }
    return ShipStats._(cost: cost, captains: captains, masts: masts);
  }

  /// 건조 포인트 합계(블록 + 모듈).
  final int cost;

  /// 선장실 수.
  final int captains;

  /// 돛대 수.
  final int masts;
}
