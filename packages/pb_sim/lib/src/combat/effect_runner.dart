import 'package:pb_sim/src/combat/ammo_rules.dart';
import 'package:pb_sim/src/combat/boarding.dart';
import 'package:pb_sim/src/combat/impact.dart';
import 'package:pb_sim/src/combat/launch.dart';
import 'package:pb_sim/src/combat/unique_turns.dart';
import 'package:pb_sim/src/combat/volley.dart';
import 'package:pb_sim/src/match/match_state.dart';
import 'package:pb_sim/src/match/rules.dart';
import 'package:pb_sim/src/match/sim_event.dart';
import 'package:pb_sim/src/match/turn_effects.dart';
import 'package:pb_sim/src/math/fx.dart';
import 'package:pb_sim/src/pirate/crew.dart';
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
  // 지속 턴이 끝난 떠 있는 기뢰·펌프 무력화는 조용히 사라진다.
  if (e.kind == EffectKind.floatMine || e.kind == EffectKind.pumpOff) return;
  final target = state.sides[e.target];
  final grid = target.grid;
  // 강습 물기는 쏜 해적이 적 배 위에 서 있을 때만, 밟은 칸 중심으로 문다 (ADR-110).
  final boarder = isBoarderBite(e)
      ? state.sides[e.owner].crew.pirates[e.ownerSlot]
      : null;
  if (boarder != null && boarder.status != PirateStatus.boarding) return;
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
      final (cx, cy) = boarder != null
          ? boardPosOf(grid, boarder.boardCell)
          : (e.cell % grid.width, e.cell ~/ grid.width);
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
        // 강습 물기는 특성·세트와 상관없이 반경 1칸이다 (설계서 §4.8).
        spec: boarder == null
            ? e.spec
            : e.spec.withDamage(
                blockDamage: e.spec.blockDamage,
                pirateDamage: e.spec.pirateDamage,
                blastRadius: 1,
              ),
        cx: cx,
        cy: cy,
        x: x,
        y: y,
        events: state.events,
        rng: state.rng,
        // 물기는 해적만 문다. 문 강습 해적 자신(같은 배 위)은 맞지 않는다.
        blockPercent: mine ? 100 : 0,
        hitBoarders: mine,
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
    case EffectKind.gnawBite:
      gnawBite(state, e);
    case EffectKind.floatMine || EffectKind.pumpOff || EffectKind.tentacle:
      break;
  }
}
