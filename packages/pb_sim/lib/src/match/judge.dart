import 'package:pb_sim/src/match/match_state.dart';
import 'package:pb_sim/src/ship/module.dart';

/// 즉시 승리 판정 (설계서 §2.7): 전멸 → 선장실 파괴 순. 같은 조건을 양쪽이 같은
/// 순간 채우면 무승부(winner −1), 다른 조건이면 먼저 보는 조건의 패자가 진다.
void judgeInstant(MatchState state) {
  for (final outcome in const [
    MatchOutcome.annihilation,
    MatchOutcome.captainLost,
  ]) {
    final lost = [
      for (final s in state.sides)
        outcome == MatchOutcome.annihilation
            ? s.crew.allDown
            : !s.captainStanding,
    ];
    if (!lost[0] && !lost[1]) continue;
    state
      ..outcome = outcome
      ..winner = lost[0] && lost[1] ? -1 : (lost[0] ? 1 : 0);
    return;
  }
}

/// 턴 제한 판정의 앞선 쪽 (설계서 §2.7): 남은 해적 체력 비율이 높은 쪽, 같으면
/// 선장실 블록 남은 내구도 비율이 높은 쪽, 그마저 같으면 −1. 상태는 바꾸지 않는다
/// (HUD 안내도 이 값을 쓴다).
int timeLeader(MatchState state) {
  final a = state.sides[0];
  final b = state.sides[1];
  final ra = a.crew.hpLeft * b.crew.hpStart;
  final rb = b.crew.hpLeft * a.crew.hpStart;
  if (ra != rb) return ra > rb ? 0 : 1;
  final ca = captainHp(a) * captainMaxHp(b);
  final cb = captainHp(b) * captainMaxHp(a);
  if (ca != cb) return ca > cb ? 0 : 1;
  return -1;
}

/// 선장실 블록의 남은 내구도(부서졌으면 0).
int captainHp(SideState s) {
  for (final m in s.modules.list) {
    if (m.kind != ModuleKind.captain) continue;
    return s.grid.hasBlock(m.x, m.y) ? s.grid.hpAt(m.x, m.y) : 0;
  }
  return 0;
}

/// 선장실 블록의 최대 내구도.
int captainMaxHp(SideState s) {
  for (final m in s.modules.list) {
    if (m.kind != ModuleKind.captain) continue;
    return s.grid.maxHpAt(s.grid.indexOf(m.x, m.y));
  }
  return 1;
}

/// 턴 제한 판정 (설계서 §2.7).
void judgeTime(MatchState state) {
  state
    ..outcome = MatchOutcome.timeDecision
    ..winner = timeLeader(state);
}
