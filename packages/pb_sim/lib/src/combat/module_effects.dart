import 'package:pb_sim/src/match/match_state.dart';
import 'package:pb_sim/src/match/sim_event.dart';
import 'package:pb_sim/src/ship/module_state.dart';
import 'package:pb_sim/src/ship/support.dart';

/// 블록이 없어진 모듈을 부서진 것으로 바꾸고 효과를 낸다 (설계서 §3.3).
///
/// 설계도 순서로 본다. 선장실은 붙은 블록이 없어지면 부서지고(판정은 `judgeInstant`),
/// 돛대는 붙인 칸이나 돛대 칸 하나만 없어져도 부러져 위쪽이 무너지고 망대 해적이
/// 바다로 떨어진다(KO).
void settleModules(SideState ship, List<SimEvent> events) {
  final grid = ship.grid;
  for (final m in ship.modules.list) {
    if (!m.intact) continue;
    final rigGone =
        m.kind.isMast &&
        m.cell.rigCells(grid.height).any((c) => !grid.hasBlock(c.$1, c.$2));
    if (grid.hasBlock(m.x, m.y) && !rigGone) continue;
    m.intact = false;
    events.add(
      SimEvent(
        SimEventKind.moduleDestroyed,
        side: ship.side,
        cell: grid.indexOf(m.x, m.y),
        value: m.kind.index,
      ),
    );
    if (m.kind.isMast) {
      _dropCrowsNest(ship, m, events);
      _breakMast(ship, m, events);
    }
  }
}

/// 망대(돛대 꼭대기)에 탄 해적은 바다로 떨어져 KO 다 (설계서 §3.3).
void _dropCrowsNest(SideState ship, ModuleState m, List<SimEvent> events) {
  final rig = m.cell.rigCells(ship.grid.height);
  if (rig.isEmpty) return;
  final (sx, sy) = rig.last;
  for (
    var slot = 0;
    slot < ship.cabins.length && slot < ship.crew.size;
    slot++
  ) {
    final c = ship.cabins[slot];
    if (c.x == sx && c.y == sy) ship.crew.fall(slot, ship.side, events);
  }
}

/// 돛대가 부러지면 같은 세로줄 위쪽 칸이 모두 무너진다 (설계서 §3.3).
void _breakMast(SideState ship, ModuleState m, List<SimEvent> events) {
  final grid = ship.grid;
  for (var y = m.y + 1; y < grid.height; y++) {
    if (!grid.hasBlock(m.x, y)) continue;
    final i = grid.indexOf(m.x, y);
    grid.removeAt(i);
    events.add(SimEvent(SimEventKind.blockCollapsed, side: ship.side, cell: i));
  }
  for (final i in collapseUnsupported(grid)) {
    events.add(SimEvent(SimEventKind.blockCollapsed, side: ship.side, cell: i));
  }
}
