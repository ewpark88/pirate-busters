import 'package:pb_sim/src/combat/fire.dart';
import 'package:pb_sim/src/combat/module_effects.dart';
import 'package:pb_sim/src/combat/unique_turns.dart';
import 'package:pb_sim/src/match/judge.dart';
import 'package:pb_sim/src/match/match_state.dart';

/// 턴 끝 처리 1~3번째 (설계서 §2.3): 지금 턴 진영 배의 화재 → 침수 증가 → 수리·펌프.
/// 단계마다 즉시 판정한다. 판이 이미 끝났으면 부르지 않는다.
void endTurnUpkeep(MatchState state) {
  final ship = state.sides[state.activeSide];
  burnAtTurnEnd(ship, state.rng, state.events);
  judgeInstant(state);
  if (state.isOver) return;
  endTurnWater(
    ship,
    state.rules,
    state.turn,
    state.events,
    beforePumps: () => runTentacles(state),
    pumpsOff: pumpsOffFor(state),
  );
  judgeInstant(state);
}

/// 다음 턴으로 넘긴다: 턴 번호·바람(바람 변경, 턴 끝 처리 5번째)·턴 안 계수를 바꾸고
/// 진영의 턴 번호를 맞춘다.
void advanceTurn(MatchState state) {
  final next = state.turn + 1;
  state
    ..turn = next
    ..wind = windOf(state, next)
    ..firesThisTurn = 0
    ..pausedMs = 0
    ..busyUntilMs = 0
    ..syncTurn();
}

/// [turn] 의 바람: 매치 시드 바람에 그 턴 진영의 지속 상태를 적용한다. 바람 무시(램프)
/// 가 바람 역전(알바)보다 앞선다 (설계서 §4.8 고유 효과 공통 규칙, ADR-075).
int windOf(MatchState state, int turn) {
  final base = state.rules.windForTurn(state.seed, turn);
  final side = turn.isOdd ? state.firstSide : 1 - state.firstSide;
  final status = state.sides[side].status;
  if (status.windIgnoreTurn == turn) return 0;
  if (status.windReverseTurn == turn) return -base;
  return base;
}
