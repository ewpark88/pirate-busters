/// 전설 고유 능력 (설계서 §4.8 ★, BALANCE.md A4.2, ADR-111).
library;

import 'package:pb_sim/src/combat/hit_helpers.dart';
import 'package:pb_sim/src/combat/impact.dart';
import 'package:pb_sim/src/match/match_state.dart';
import 'package:pb_sim/src/match/sim_event.dart';
import 'package:pb_sim/src/match/turn_effects.dart';
import 'package:pb_sim/src/pirate/ability.dart';
import 'package:pb_sim/src/pirate/crew.dart';
import 'package:pb_sim/src/pirate/pirate_spec.dart';
import 'package:pb_sim/src/projectile/projectile.dart';
import 'package:pb_sim/src/world/world.dart';

/// 고유 능력의 ‘절반’ 피해 비율(%) (BALANCE.md A4.2).
const int legendHalfPercent = 50;

/// 크라키 촉수가 턴 끝마다 둘레 칸 블록에 주는 피해 (BALANCE.md A4.2).
const int tentacleBlockDamage = 30;

/// 데비 해골 선원이 무는 범위(칸): 착지 칸에서 이 안의 배 위 해적.
const int skeletonReach = 2;

/// 바라 어뢰가 이보다 깊이 내려가면 사라진다(1/1000칸).
const int torpedoDepthLimit = 8 * cellUnit;

/// 볼케·오르카·데비의 선체 명중. 처리했으면 탄이 끝났는지(true)·계속 나는지(false),
/// 고유 동작이 없으면 null.
bool? legendHullHit(
  MatchState state,
  Projectile p,
  SideState target, {
  required int cx,
  required int cy,
  required int x,
  required int y,
}) {
  final spec = p.spec;
  void impact(PirateSpec s, {int block = 100, int pirate = 100}) =>
      resolveImpact(
        target,
        spec: s,
        cx: cx,
        cy: cy,
        x: x,
        y: y,
        events: state.events,
        blockPercent: block,
        centerPiratePercent: pirate,
      );
  switch (spec.ability) {
    case Ability.drill:
      if (p.pierceLeft > 1) {
        // 층을 뚫는 동안은 착탄 칸만 절반 피해로 친다.
        impact(
          singleCell(spec),
          block: legendHalfPercent,
          pirate: legendHalfPercent,
        );
        p
          ..pierceLeft -= 1
          ..passedCell = target.grid.indexOf(cx, cy);
        return false;
      }
      // 마지막 층에서 반경 +1 로 터진다.
      impact(
        spec.withDamage(
          blockDamage: spec.blockDamage,
          pirateDamage: spec.pirateDamage,
          blastRadius: spec.blastRadius + 1,
        ),
      );
      return true;
    case Ability.wave:
      impact(spec, block: p.bounced ? 150 : 100);
      if (!p.abilityDone && target.side != p.side) {
        p.abilityDone = true;
        _sweepDeck(state, target, spec);
        pushShip(state, target, spec.abilityValue);
      }
      return true;
    case Ability.summon:
      impact(spec);
      if (target.side != p.side) _skeletons(state, target, spec, cx, cy);
      return true;
    case _:
      return null;
  }
}

/// 오르카: 머리 위에 블록이 없는 배 위 해적들에게 해적 피해 50%.
void _sweepDeck(MatchState state, SideState target, PirateSpec spec) {
  final grid = target.grid;
  final dmg = spec.pirateDamage * legendHalfPercent ~/ 100;
  for (var slot = 0; slot < target.crew.size; slot++) {
    if (target.crew.pirates[slot].status != PirateStatus.aboard) continue;
    final c = target.cabins[slot];
    var covered = false;
    for (var cy = c.y + 1; cy < grid.height && !covered; cy++) {
      covered = grid.hasBlock(c.x, cy);
    }
    if (!covered) target.crew.damage(slot, dmg, target.side, state.events);
  }
}

/// 데비: 해골 선원 인자 명이 착지 칸에서 가까운 배 위 해적을 한 명씩 문다(50%).
void _skeletons(
  MatchState state,
  SideState target,
  PirateSpec spec,
  int cx,
  int cy,
) {
  final dmg = spec.pirateDamage * legendHalfPercent ~/ 100;
  var n = 0;
  for (final slot in aboardByDistance(target, cx, cy)) {
    if (n >= spec.abilityValue) break;
    final c = target.cabins[slot];
    final dx = c.x - cx;
    final dy = c.y - cy;
    if (dx * dx + dy * dy > skeletonReach * skeletonReach) break;
    target.crew.damage(slot, dmg, target.side, state.events);
    n++;
  }
}

/// 상대 배에 맞았을 때의 고유 효과(모비 끌기·만타 궤적 가림). 탄마다 한 번만 낸다.
void applyHitAbility(MatchState state, Projectile p, SideState target) {
  final spec = p.spec;
  if (p.abilityDone) return;
  switch (spec.ability) {
    case Ability.pull:
      pushShip(state, target, -spec.abilityValue);
    case Ability.blindTrail:
      target.status.trailBlockTurn = state.turn + 1;
    case _:
      return;
  }
  p.abilityDone = true;
  state.events.add(
    SimEvent(
      SimEventKind.statusApplied,
      side: target.side,
      value: spec.ability.index,
    ),
  );
}

/// 크라키: 붙는 순간 설치탄처럼 터지고, 인자 턴 동안 대상 배의 턴이 끝날 때마다
/// 둘레 칸을 친다. 처리했으면 true.
bool attachTentacle(
  MatchState state,
  Projectile p,
  SideState target,
  int cell,
) {
  final spec = p.spec;
  if (spec.ability != Ability.tentacle) return false;
  final grid = target.grid;
  final cx = cell % grid.width;
  final cy = cell ~/ grid.width;
  final (x, y) = target.frame.cellCenter(cx, cy);
  resolveImpact(
    target,
    spec: spec,
    cx: cx,
    cy: cy,
    x: x,
    y: y,
    events: state.events,
  );
  state.effects.add(
    TurnEffect(
      kind: EffectKind.tentacle,
      owner: p.side,
      ownerSlot: p.slot,
      target: target.side,
      trigger: -1,
      turnsLeft: spec.abilityValue,
      spec: spec,
      cell: cell,
    ),
  );
  state.events.add(
    SimEvent(SimEventKind.mineAttached, side: target.side, cell: cell),
  );
  return true;
}

/// 턴 끝: 지금 턴 진영 배에 붙은 촉수가 둘레 1칸 블록을 치고 1 줄어든다.
void runTentacles(MatchState state) {
  final side = state.activeSide;
  final ship = state.sides[side];
  final grid = ship.grid;
  for (final e in state.effects) {
    if (e.kind != EffectKind.tentacle || e.target != side) continue;
    final cx = e.cell % grid.width;
    final cy = e.cell ~/ grid.width;
    state.events.add(
      SimEvent(
        SimEventKind.effectFired,
        side: side,
        slot: e.ownerSlot,
        cell: e.cell,
        value: e.kind.index,
      ),
    );
    damageCells(state, ship, [
      for (var dy = -1; dy <= 1; dy++)
        for (var dx = -1; dx <= 1; dx++)
          if (grid.inBounds(cx + dx, cy + dy)) grid.indexOf(cx + dx, cy + dy),
    ], tentacleBlockDamage);
    e.turnsLeft--;
  }
  state.effects.removeWhere(
    (e) => e.kind == EffectKind.tentacle && e.turnsLeft <= 0,
  );
}

/// 탄 준비: 볼케는 뚫을 층 수(+ 마지막 폭발 1), 바라는 중력 없이 물속으로.
void armLegend(Projectile p) {
  switch (p.spec.ability) {
    case Ability.drill:
      p.pierceLeft = p.spec.abilityValue + 1;
    case Ability.torpedo:
      p
        ..gravity = false
        ..submerged = true;
    case _:
      break;
  }
}
