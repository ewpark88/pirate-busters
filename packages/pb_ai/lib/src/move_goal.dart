import 'package:pb_sim/pb_sim.dart';

/// 이동 목표 (설계서 §5.5 위치 후보·파도 구간). 위치 후보는 지금 자리 둘레 몇 칸뿐이라
/// (BALANCE.md A5.5), 멀리 있는 잔잔한 구간은 목표로 정해 두고 턴마다 그쪽으로 다가가는
/// 자리에 점수를 더한다. 수치는 BALANCE.md A5.5 '잔잔한 구간 이동 목표'(ADR-115).
abstract final class MoveGoal {
  /// 목표 쪽으로 1칸 다가간 위치에 더하는 점수 (BALANCE.md A5.5).
  static const int progressPerCell = 15;

  /// 목표를 찾을 때 살펴보는 거리(칸, 앞뒤 각각) (BALANCE.md A5.5).
  static const int searchCells = 12;

  /// [side] 가 이번 턴 연료·한계 안에서 끝까지 갈 수 있는 자리 중 파도가 가장 잔잔한
  /// 곳의 오프셋. 같은 세기면 가까운 곳, 지금 자리가 가장 잔잔하면 지금 자리다.
  /// 계산 중에 배 위치를 잠시 바꿨다가 되돌린다.
  static int calmTarget(MatchState state, int side) {
    final me = state.sides[side];
    final other = state.otherOf(side);
    final now = me.offset;
    var best = now;
    var bestLevel = waveLevelOf(state, side);
    try {
      for (var k = 1; k <= searchCells && bestLevel > 0; k++) {
        for (final sign in const [-1, 1]) {
          final dx = sign * k * 10;
          final reach = moveReach(me, other, state.rules, dx, 20000);
          if (reach != dx * moveStep) continue;
          me.offset = now + reach;
          final level = waveLevelOf(state, side);
          me.offset = now;
          if (level < bestLevel) {
            bestLevel = level;
            best = now + reach;
          }
        }
      }
    } finally {
      me.offset = now;
    }
    return best;
  }

  /// [offset] 이 지금 자리 [now] 보다 목표 [goal] 에 다가간 칸 수에 비례한 점수.
  /// 멀어지면 음수다.
  static int progressScore(int now, int offset, int goal) =>
      ((now - goal).abs() - (offset - goal).abs()) *
      progressPerCell ~/
      cellUnit;
}
