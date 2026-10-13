import 'package:pb_sim/src/match/match_state.dart';
import 'package:pb_sim/src/ship/module.dart';

/// 즉시 승리 판정 (설계서 §2.7): 전멸 또는 선장실 파괴를 채운 쪽이 진다. 양쪽이 같은
/// 순간 채우면 조건 종류가 달라도 무승부(winner −1, ADR-113). 결과 종류는 전멸이
/// 하나라도 있으면 전멸, 아니면 선장실 파괴다.
void judgeInstant(MatchState state) {
  final wiped = [for (final s in state.sides) s.crew.allDown];
  final lost = [
    for (var i = 0; i < 2; i++) wiped[i] || !state.sides[i].captainStanding,
  ];
  if (!lost[0] && !lost[1]) return;
  final losers = [
    for (var i = 0; i < 2; i++)
      if (lost[i]) i,
  ];
  state
    ..outcome = losers.any((i) => wiped[i])
        ? MatchOutcome.annihilation
        : MatchOutcome.captainLost
    ..winner = losers.length == 2 ? -1 : 1 - losers.single;
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
