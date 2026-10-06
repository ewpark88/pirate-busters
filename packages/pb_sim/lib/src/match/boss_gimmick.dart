import 'package:pb_sim/src/match/match_state.dart';
import 'package:pb_sim/src/match/rules.dart';
import 'package:pb_sim/src/pirate/ammo.dart';
import 'package:pb_sim/src/pirate/pirate_spec.dart';
import 'package:pb_sim/src/ship/ship_grid.dart';
import 'package:pb_sim/src/world/world.dart';

/// 보스 기믹 (설계서 §5.4, 수치: BALANCE.md A5.4). 판 규칙의 정수 코드로 넘긴다.
/// 해역 2~6 기믹은 R3 에서 뒤에 붙인다(순서는 리플레이에 들어가므로 바꾸지 않는다).
enum BossGimmick {
  none,

  /// 1-5 꽃게 부대장의 순찰선: 뱃머리 철판 방패가 서 있는 동안 직사 피해 50%.
  bowIronShield,

  /// 1-12 해군 초계선: 전진 한계가 턴마다 1칸씩 다가오고(최대 6칸), 보스 쪽 해적
  /// 쿨다운은 턴 끝마다 2씩 준다.
  patrolClosingIn;

  /// 스테이지 데이터 id (`bow_iron_shield` 등).
  static BossGimmick byId(String? id) => switch (id) {
    'bow_iron_shield' => bowIronShield,
    'patrol_closing_in' => patrolClosingIn,
    _ => none,
  };
}

/// 기믹 수치 (BALANCE.md A5.4).
abstract final class GimmickNumbers {
  static const int shieldDirectPercent = 50;
  static const int patrolStep = cellUnit;
  static const int patrolMax = 6 * cellUnit;
  static const int patrolCooldownStep = 2;

  /// 두 배 뱃머리 사이 최소 간격. 다가오는 한계가 상대 배를 넘지 않게 한다.
  static const int minBowGap = 2 * cellUnit;
}

/// [side] 진영에 걸린 기믹. 기믹이 없거나 다른 진영이면 [BossGimmick.none].
BossGimmick gimmickOf(MatchRules rules, int side) =>
    side == rules.gimmickSide && rules.gimmick < BossGimmick.values.length
    ? BossGimmick.values[rules.gimmick]
    : BossGimmick.none;

/// 뱃머리 방패 칸: 판 시작 때 블록이 있는 가장 앞(x 가 큰) 세로줄의 블록들.
List<int> bowShieldCells(ShipGrid grid) {
  for (var x = grid.width - 1; x >= 0; x--) {
    final cells = [
      for (var y = 0; y < grid.height; y++)
        if (grid.hasBlock(x, y) && !grid.materialAt(x, y)!.rig)
          grid.indexOf(x, y),
    ];
    if (cells.isNotEmpty) return cells;
  }
  return const [];
}

/// [target] 이 [spec] 탄에 받는 블록 피해 배율(%). 방패가 하나라도 남아 있으면 직사는 50%.
int shieldPercent(SideState target, PirateSpec spec) {
  if (spec.family != Family.direct) return 100;
  final shield = target.shieldCells;
  if (shield.isEmpty) return 100;
  final up = shield.any(target.grid.hasBlockAt);
  return up ? GimmickNumbers.shieldDirectPercent : 100;
}

/// 턴 시작: 초계선의 전진 한계를 정한다. 상대 뱃머리와 [GimmickNumbers.minBowGap]
/// 보다 가까워지지 않게 줄인다.
void updatePatrol(MatchState state) {
  final side = state.activeSide;
  if (gimmickOf(state.rules, side) != BossGimmick.patrolClosingIn) return;
  final me = state.sides[side];
  final other = state.sides[1 - side];
  me.patrolTurns++;
  final want = me.patrolTurns * GimmickNumbers.patrolStep;
  final room = startGap - other.offset - GimmickNumbers.minBowGap - moveRange;
  var bonus = want > GimmickNumbers.patrolMax ? GimmickNumbers.patrolMax : want;
  if (bonus > room) bonus = room;
  me.forwardBonus = bonus < 0 ? 0 : bonus;
}

/// 턴 끝 쿨다운 감소량: 초계선 쪽은 2, 나머지는 1.
int cooldownStepOf(MatchRules rules, int side) =>
    gimmickOf(rules, side) == BossGimmick.patrolClosingIn
    ? GimmickNumbers.patrolCooldownStep
    : 1;
