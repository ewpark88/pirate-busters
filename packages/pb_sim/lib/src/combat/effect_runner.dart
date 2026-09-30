import 'package:pb_sim/src/combat/ammo_rules.dart';
import 'package:pb_sim/src/combat/impact.dart';
import 'package:pb_sim/src/combat/launch.dart';
import 'package:pb_sim/src/combat/volley.dart';
import 'package:pb_sim/src/match/match_state.dart';
import 'package:pb_sim/src/match/rules.dart';
import 'package:pb_sim/src/match/sim_event.dart';
import 'package:pb_sim/src/match/turn_effects.dart';
import 'package:pb_sim/src/math/fx.dart';
import 'package:pb_sim/src/world/world.dart';

/// 턴 시작: [MatchState.activeSide] 진영의 턴에 세는 효과를 1 줄이고, 0 이 된 것을
/// 건 순서대로 터뜨린다 (설계서 §4.3 턴 효과). 판정은 부르는 쪽이 한다.
void runTurnEffects(MatchState state) {
  final side = state.activeSide;
  final due = <TurnEffect>[];
  for (final e in state.effects) {
    if (e.trigger != side) continue;
    e.turnsLeft--;
    if (e.turnsLeft <= 0) due.add(e);
  }
  if (due.isEmpty) return;
  state.effects.removeWhere((e) => e.turnsLeft <= 0);
  state.lastTraces = const [];
  for (final e in due) {
    _fire(state, e);
  }
}

void _fire(MatchState state, TurnEffect e) {
  final target = state.sides[e.target];
  final grid = target.grid;
  final ms = realMs(state, 0);
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
  switch (e.kind) {
    case EffectKind.mineBlast || EffectKind.biteAgain:
      final cx = e.cell % grid.width;
      final cy = e.cell ~/ grid.width;
      final (x, y) = fromShipLocal(
        state,
        e.target,
        ms,
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
        // 물기는 해적만 문다.
        blockPercent: mine ? 100 : 0,
      );
      if (mine && e.spec.ammoValue2 > 0) {
        final flood = target.flood + e.spec.ammoValue2;
        target.flood = flood > fullFlood ? fullFlood : flood;
        state.events.add(
          SimEvent(
            SimEventKind.flood,
            side: e.target,
            value: e.spec.ammoValue2,
          ),
        );
      }
    case EffectKind.flockDrop:
      final bombs = dropBombs(
        state,
        side: e.owner,
        slot: e.ownerSlot,
        spec: e.spec,
        x: e.x,
      );
      final ticks = runVolley(state, bombs, ms);
      state.pausedMs += roundDiv(ticks * 1000, simTickHz);
  }
}
