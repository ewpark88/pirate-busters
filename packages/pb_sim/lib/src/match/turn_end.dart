import 'package:pb_sim/src/combat/legend_effects.dart';
import 'package:pb_sim/src/match/judge.dart';
import 'package:pb_sim/src/match/match_state.dart';

/// 턴 끝 처리 (설계서 §2.3): 지금 턴 진영 배에 붙은 크라키 촉수가 친다(전설 능력).
/// 판이 이미 끝났으면 부르지 않는다.
void endTurnUpkeep(MatchState state) {
  runTentacles(state);
  judgeInstant(state);
}

/// 다음 턴으로 넘긴다: 턴 번호·바람·턴 안 계수를 바꾸고 진영의 턴 번호를 맞춘다.
void advanceTurn(MatchState state) {
  final next = state.turn + 1;
  state
    ..turn = next
    ..wind = state.rules.windForTurn(state.seed, next)
    ..firesThisTurn = 0
    ..pausedMs = 0
    ..busyUntilMs = 0
    ..syncTurn();
}
