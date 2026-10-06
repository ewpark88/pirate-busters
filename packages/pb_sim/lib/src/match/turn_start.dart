import 'package:pb_sim/src/combat/barrier_effects.dart';
import 'package:pb_sim/src/combat/effect_runner.dart';
import 'package:pb_sim/src/match/boss_gimmick.dart';
import 'package:pb_sim/src/match/judge.dart';
import 'package:pb_sim/src/match/mast_seats.dart';
import 'package:pb_sim/src/match/match_state.dart';
import 'package:pb_sim/src/match/sim_event.dart';
import 'package:pb_sim/src/ship/motion.dart';

/// 턴 시작 (설계서 §2.3): 폭풍 타임 시작(양쪽 연료·후퇴 한계) → 내 연료 회복 →
/// 해적 복귀 → 턴 시작 효과(설치탄·투하·물기) → 즉시 판정.
void beginTurn(MatchState state) {
  final side = state.activeSide;
  final turn = state.turn;
  final rules = state.rules;
  state.events
    ..clear()
    ..add(SimEvent(SimEventKind.turnStart, side: side, value: turn));
  if (turn == rules.stormStartTurn) {
    for (final s in state.sides) {
      final moved = startStorm(s, rules, turn);
      if (moved != 0) {
        state.events.add(
          SimEvent(SimEventKind.move, side: s.side, x: s.bowX, value: moved),
        );
      }
    }
    state.events.add(
      SimEvent(SimEventKind.stormStart, side: side, value: turn),
    );
  }
  expireBarriers(state);
  updatePatrol(state);
  refuel(state.sides[side], rules.fuelPerTurn);
  state.sides[side]
    ..moveFallenSeats()
    ..crew.startOwnTurn(side, state.events);
  runTurnEffects(state);
  judgeInstant(state);
}
