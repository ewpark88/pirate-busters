import 'package:pb_sim/src/match/match_state.dart';
import 'package:pb_sim/src/ship/blueprint.dart';

/// 돛 자리 (설계서 §3.3).
extension MastSeats on SideState {
  /// 돛대가 부러진 돛 자리 선실을 돛대 밑동 바로 위 칸(드러난 갑판)으로 옮긴다.
  /// 바다에 빠진 해적이 돌아오기 전, 내 턴 시작에 부른다.
  void moveFallenSeats() {
    for (final m in modules.list) {
      if (!m.kind.isMast || m.intact) continue;
      final rig = m.cell.rigCells(grid.height);
      if (rig.isEmpty) continue;
      final (sx, sy) = rig.last;
      for (var slot = 0; slot < cabins.length; slot++) {
        if (cabins[slot].x == sx && cabins[slot].y == sy) {
          cabins[slot] = CabinCell(m.x, m.y + 1);
        }
      }
    }
  }
}
