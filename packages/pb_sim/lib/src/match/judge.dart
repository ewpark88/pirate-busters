import 'package:pb_sim/src/match/match_state.dart';

/// 즉시 승리 판정 (설계서 §2.4): 전멸 → 격침(내구도) → 격침(침수 100%) 순.
/// 두 배가 함께 끝나면 무승부(winner −1).
void judgeInstant(MatchState state) {
  final percent = state.rules.sunkHullPercent;
  for (final outcome in const [
    MatchOutcome.annihilation,
    MatchOutcome.sunk,
    MatchOutcome.floodSunk,
  ]) {
    final lost = [
      for (final s in state.sides)
        switch (outcome) {
          MatchOutcome.annihilation => s.crew.allDown,
          MatchOutcome.sunk =>
            s.grid.totalHp * 100 < s.grid.initialTotalHp * percent,
          _ => s.flood >= fullFlood,
        },
    ];
    if (!lost[0] && !lost[1]) continue;
    state
      ..outcome = outcome
      ..winner = lost[0] && lost[1] ? -1 : (lost[0] ? 1 : 0);
    return;
  }
}

/// 보조 판정의 침수량 차 기준: 1%p (0.1%p 단위).
const int floodTieMargin = 10;

/// 시간 판정 (설계서 §2.4): 침수량이 적은 쪽이 이긴다. 차이가 1%p 이내면 선체
/// 내구도 비율이 높은 쪽, 그마저 같으면 무승부.
void judgeTime(MatchState state) {
  final a = state.sides[0];
  final b = state.sides[1];
  final diff = a.flood - b.flood;
  int winner;
  if (diff > floodTieMargin) {
    winner = 1;
  } else if (diff < -floodTieMargin) {
    winner = 0;
  } else {
    // 비율 비교: a.hp / a.init vs b.hp / b.init → 교차 곱.
    final ra = a.grid.totalHp * b.grid.initialTotalHp;
    final rb = b.grid.totalHp * a.grid.initialTotalHp;
    winner = ra == rb ? -1 : (ra > rb ? 0 : 1);
  }
  state
    ..outcome = MatchOutcome.timeDecision
    ..winner = winner;
}
