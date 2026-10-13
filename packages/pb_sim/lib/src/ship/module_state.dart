import 'package:pb_sim/src/ship/blueprint.dart';
import 'package:pb_sim/src/ship/module.dart';

/// 전투 중 모듈 한 개의 상태.
class ModuleState {
  ModuleState(this.cell);

  final ModuleCell cell;

  /// 모듈이 붙은 블록이(돛대는 돛대 칸이) 아직 있다.
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
      ]);

  final List<ModuleState> list;

  /// 남아 있는 [kind] 모듈 수.
  int intactCount(ModuleKind kind) {
    var n = 0;
    for (final m in list) {
      if (m.kind == kind && m.intact) n++;
    }
    return n;
  }

  /// 꼭대기 칸이 ([x], [y]) 인 남은 돛대. 없으면 null (망대, 설계서 §3.3).
  ModuleState? mastWithSeat(int x, int y, int height) {
    for (final m in list) {
      if (!m.kind.isMast || !m.intact) continue;
      final rig = m.cell.rigCells(height);
      if (rig.isNotEmpty && rig.last == (x, y)) return m;
    }
    return null;
  }
}
