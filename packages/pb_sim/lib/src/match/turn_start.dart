import 'package:pb_sim/src/combat/boarding.dart';
import 'package:pb_sim/src/combat/effect_runner.dart';
import 'package:pb_sim/src/match/judge.dart';
import 'package:pb_sim/src/match/match_state.dart';
import 'package:pb_sim/src/match/sim_event.dart';
import 'package:pb_sim/src/ship/motion.dart';

/// 턴 시작 (설계서 §2.3): 내 연료를 가득 채움 → 적 배 위 강습 해적 복귀·근접 수비
/// → 턴 시작 효과(설치탄·물기) → 즉시 판정.
void beginTurn(MatchState state) {
  final side = state.activeSide;
  state.events
    ..clear()
    ..add(SimEvent(SimEventKind.turnStart, side: side, value: state.turn));
  refillFuel(state.sides[side]);
  boardingTurnStart(state);
  runTurnEffects(state);
  judgeInstant(state);
}
