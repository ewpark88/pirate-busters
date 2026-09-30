import 'package:pb_sim/src/ship/blueprint.dart';
import 'package:pb_sim/src/ship/material.dart';
import 'package:pb_sim/src/ship/module.dart';

/// 모듈 효과 수치 (BALANCE.md A3.3, A2.6, A2.7). 선체 보정(§3.5)은 R4 라 ×1.00 이다.
abstract final class ModuleNumbers {
  /// 포문: 그 선실 해적 피해 +10%.
  static const int gunPortPercent = 10;

  /// 화약고: 모든 해적 피해 +10% (여러 개여도 한 번, ADR-038).
  static const int magazinePercent = 10;

  /// 화약고 유폭: 반경 2칸, 블록 80, 해적 120.
  static const int magazineRadius = 2;
  static const int magazineBlockDamage = 80;
  static const int magazinePirateDamage = 120;

  /// 펌프: 턴 끝 침수량 −4%p (0.1%p 단위).
  static const int pumpFlood = 40;

  /// 연료통: 탱크 +40, 부서지면 주변 1칸 블록 40.
  static const int fuelTankBonus = 40;
  static const int fuelTankRadius = 1;
  static const int fuelTankBlockDamage = 40;

  /// 무게 연료: 철판으로만 지은 배가 +20% (‰).
  static const int weightFuelPermille = 200;

  /// 돛대가 부러지면 1칸당 연료 ×2, 속도 −50%.
  static const int mastFuelFactor = 2;
  static const int mastSpeedPercent = 50;
}

/// 전투 중 모듈 한 개의 상태.
class ModuleState {
  ModuleState(this.cell);

  final ModuleCell cell;

  /// 모듈이 붙은 블록이 아직 있다.
  bool intact = true;

  ModuleKind get kind => cell.kind;
  int get x => cell.x;
  int get y => cell.y;
}

/// 한 배의 모듈들. 설계도 순서((y, x) 순)로 갱신한다.
class ShipModules {
  ShipModules(Blueprint blueprint)
    : list = List.unmodifiable([
        for (final m in blueprint.modules) ModuleState(m),
      ]),
      weightPermille = weightFuelPermilleOf(blueprint);

  final List<ModuleState> list;

  /// 무게에 따른 1칸당 연료 배율(‰): 1000 + 200 × 총무게 ÷ 최대 무게 (설계서 §2.7).
  final int weightPermille;

  /// 선형 최대 무게(건조 포인트를 모두 철판으로 채운 무게)에 대한 연료 배율(‰).
  static int weightFuelPermilleOf(Blueprint blueprint) {
    var weight = 0;
    for (final c in blueprint.cells) {
      weight += c.material.weight;
    }
    if (weight <= 0) return 1000;
    const iron = BlockMaterial.iron;
    final max = blueprint.hull.buildPoints ~/ iron.cost * iron.weight;
    final w = weight > max ? max : weight;
    return 1000 + ModuleNumbers.weightFuelPermille * w ~/ max;
  }

  /// 남아 있는 [kind] 모듈 수.
  int intactCount(ModuleKind kind) {
    var n = 0;
    for (final m in list) {
      if (m.kind == kind && m.intact) n++;
    }
    return n;
  }

  /// [kind] 모듈이 하나라도 부서졌다.
  bool anyLost(ModuleKind kind) {
    for (final m in list) {
      if (m.kind == kind && !m.intact) return true;
    }
    return false;
  }

  /// 칸 ([x], [y]) 에 남아 있는 [kind] 모듈이 있다(선실 옵션 확인용).
  bool hasAt(int x, int y, ModuleKind kind) {
    for (final m in list) {
      if (m.x == x && m.y == y && m.kind == kind && m.intact) return true;
    }
    return false;
  }
}
