import 'package:pb_sim/src/combat/boarding.dart';
import 'package:pb_sim/src/combat/impact.dart';
import 'package:pb_sim/src/combat/launch.dart';
import 'package:pb_sim/src/match/match_state.dart';
import 'package:pb_sim/src/match/sim_event.dart';
import 'package:pb_sim/src/match/turn_effects.dart';
import 'package:pb_sim/src/pirate/crew.dart';
import 'package:pb_sim/src/world/world.dart';

/// 턴 시작: [MatchState.activeSide] 진영의 턴에 세는 효과를 1 줄이고, 0 이 된 것을
/// 건 순서대로 터뜨린다 (설계서 §4.8). 판정은 부르는 쪽이 한다.
void runTurnEffects(MatchState state) {
  final side = state.activeSide;
  final due = <TurnEffect>[];
  for (final e in state.effects) {
    if (e.trigger != side) continue;
    e.turnsLeft--;
    if (e.turnsLeft <= 0) due.add(e);
  }
  if (due.isEmpty) return;
  state.effects.removeWhere((e) => e.trigger == side && e.turnsLeft <= 0);
  state.lastTraces = const [];
  for (final e in due) {
    _fire(state, e);
  }
}

void _fire(MatchState state, TurnEffect e) {
  final target = state.sides[e.target];
  final grid = target.grid;
  // 강습 물기는 쏜 해적이 적 배 위에 서 있을 때만, 밟은 칸 중심으로 문다 (ADR-110).
  final boarder = isBoarderBite(e)
      ? state.sides[e.owner].crew.pirates[e.ownerSlot]
      : null;
  if (boarder != null && boarder.status != PirateStatus.boarding) return;
  state.events.add(
    SimEvent(
      SimEventKind.effectFired,
      side: e.target,
      slot: e.ownerSlot,
      cell: e.cell,
      x: e.x,
      value: e.kind.index,
    ),
  );
  final (cx, cy) = boarder != null
      ? boardPosOf(grid, boarder.boardCell)
      : (e.cell % grid.width, e.cell ~/ grid.width);
  final (x, y) = fromShipLocal(
    state,
    e.target,
    realMs(state, 0),
    cx * cellUnit + cellUnit ~/ 2,
    cy * cellUnit + cellUnit ~/ 2,
  );
  final mine = e.kind == EffectKind.mineBlast;
  resolveImpact(
    target,
    spec: e.spec,
    cx: cx,
    cy: cy,
    x: x,
    y: y,
    events: state.events,
    // 물기는 해적만 문다. 문 강습 해적 자신(같은 배 위)은 맞지 않는다.
    blockPercent: mine ? 100 : 0,
    hitBoarders: mine,
  );
}
