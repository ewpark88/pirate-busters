/// 해적 고유 동작: 선체 명중 분기와 관통 변형 (설계서 §4.8 고유 효과, ADR-078).
library;

import 'package:pb_sim/src/combat/ability_effects.dart';
import 'package:pb_sim/src/combat/hit_effects.dart';
import 'package:pb_sim/src/combat/impact.dart';
import 'package:pb_sim/src/combat/unique_moves.dart';
import 'package:pb_sim/src/match/match_state.dart';
import 'package:pb_sim/src/match/sim_event.dart';
import 'package:pb_sim/src/pirate/ability.dart';
import 'package:pb_sim/src/pirate/crew.dart';
import 'package:pb_sim/src/pirate/pirate_spec.dart';
import 'package:pb_sim/src/projectile/projectile.dart';
import 'package:pb_sim/src/ship/material.dart';
import 'package:pb_sim/src/ship/ship_grid.dart';
import 'package:pb_sim/src/world/world.dart';

/// 바라 어뢰가 이보다 깊이 내려가면 사라진다(1/1000칸, ADR-078).
const int torpedoDepthLimit = 8 * cellUnit;

/// 해적 고유 동작이 있는 탄의 선체 명중 (설계서 §4.8 고유 효과, ADR-078).
/// 처리했으면 탄이 끝났는지(true)·계속 나는지(false), 고유 동작이 없으면 null.
bool? uniqueHullHit(
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
        rng: state.rng,
        blockPercent: block,
        centerPiratePercent: pirate,
      );
  switch (spec.ability) {
    case Ability.drill:
      if (p.pierceLeft > 1) {
        // 층을 뚫는 동안은 착탄 칸만 절반 피해로 친다.
        impact(
          singleCell(spec),
          block: uniqueHalfPercent,
          pirate: uniqueHalfPercent,
        );
        p
          ..pierceLeft -= 1
          ..passedNet = target.grid.indexOf(cx, cy);
        return false;
      }
      impact(spec);
      return true;
    case Ability.skewer || Ability.rip || Ability.saw || Ability.torpedo:
      return _pierce(state, p, target, cx: cx, cy: cy, x: x, y: y);
    case Ability.ricochet:
      impact(spec, block: p.bounced ? 150 : 100);
      if (p.bouncesLeft <= 0) return true;
      p
        ..bouncesLeft -= 1
        ..bounced = true
        ..placeAt(x, y)
        ..vx = -p.vx * 55 ~/ 100
        ..passedNet = target.grid.indexOf(cx, cy);
      state.events.add(
        SimEvent(SimEventKind.bounce, side: target.side, x: x, y: y),
      );
      return false;
    case Ability.cling:
      impact(spec, block: p.bounced ? 150 : 100);
      final cell = waterlineCellIn(target, cx);
      for (var i = 1; i < spec.ammoValue && cell >= 0; i++) {
        strikeCell(
          state,
          target,
          singleCell(spec),
          cell,
          block: uniqueHalfPercent,
        );
      }
      return true;
    case Ability.slide:
      impact(spec, block: p.bounced ? 150 : 100);
      slideAlong(state, p, target, cx, x);
      return true;
    case Ability.wave:
      impact(spec, block: p.bounced ? 150 : 100);
      if (!p.abilityDone) sweepDeck(state, target, spec.abilityValue);
      p.abilityDone = true;
      return true;
    case Ability.leap:
      final before = state.events.length;
      impact(spec);
      leapKills(state, target, spec, cx, cy, before);
      return true;
    case Ability.summon:
      impact(spec);
      summonSkeletons(state, p, target, target.grid.indexOf(cx, cy));
      return true;
    case Ability.none ||
        Ability.steer ||
        Ability.pull ||
        Ability.sealCabin ||
        Ability.blindTrail ||
        Ability.floatMine ||
        Ability.bail ||
        Ability.cooldownCut ||
        Ability.lantern ||
        Ability.twin ||
        Ability.scope ||
        Ability.shred ||
        Ability.gnaw ||
        Ability.tentacle ||
        Ability.grab ||
        Ability.coral:
      return null;
  }
}

/// 관통탄 변형(나르·왈러스·소오·바라). 기본 관통 규칙(두 번째 칸부터 50%)을 따른다.
bool _pierce(
  MatchState state,
  Projectile p,
  SideState target, {
  required int cx,
  required int cy,
  required int x,
  required int y,
}) {
  final spec = p.spec;
  final grid = target.grid;
  if (spec.ability == Ability.saw && !p.abilityDone) {
    p.abilityDone = true;
    final dmg = spec.blockDamage * uniqueHalfPercent ~/ 100;
    final column = [
      for (var cy2 = 0; cy2 < grid.height; cy2++)
        if (grid.hasBlock(cx, cy2)) grid.indexOf(cx, cy2),
    ];
    damageCells(state, target, column, dmg);
  }
  final percent = p.piercedCells == 0 ? 100 : pierceFalloffPercent;
  var piratePercent = percent;
  if (spec.ability == Ability.skewer && _aboardAt(target, cx, cy)) {
    piratePercent = p.skeweredPirates < spec.abilityValue ? 100 : 0;
    p.skeweredPirates++;
  }
  resolveImpact(
    target,
    spec: spec,
    cx: cx,
    cy: cy,
    x: x,
    y: y,
    events: state.events,
    rng: state.rng,
    blockPercent: percent,
    centerPiratePercent: piratePercent,
  );
  // 왈러스는 약한 재질(소나무·코르크·망사)만 뜯어낸다(R1d, 참나무·철판 사다리 유지).
  if (spec.ability == Ability.rip &&
      grid.hasBlock(cx, cy) &&
      grid.stageAt(cx, cy) == DamageStage.holed &&
      _rippable(grid.materialAt(cx, cy)!)) {
    damageCells(state, target, [grid.indexOf(cx, cy)], grid.hpAt(cx, cy));
  }
  p.piercedCells++;
  if (!grid.hasBlock(cx, cy) && p.pierceLeft > 1) {
    p.pierceLeft--;
    return false;
  }
  return true;
}

bool _rippable(BlockMaterial m) =>
    m == BlockMaterial.pine ||
    m == BlockMaterial.cork ||
    m == BlockMaterial.net;

bool _aboardAt(SideState target, int cx, int cy) {
  for (var slot = 0; slot < target.crew.size; slot++) {
    final c = target.cabins[slot];
    if (c.x == cx &&
        c.y == cy &&
        target.crew.pirates[slot].status == PirateStatus.aboard) {
      return true;
    }
  }
  return false;
}
