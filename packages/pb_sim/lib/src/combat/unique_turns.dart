/// 해적 고유 동작 중 턴을 넘기는 것과 비행 중 요격·무작위 피해 (ADR-078).
library;

import 'package:pb_sim/src/combat/ability_effects.dart';
import 'package:pb_sim/src/combat/ammo_rules.dart';
import 'package:pb_sim/src/combat/impact.dart';
import 'package:pb_sim/src/combat/unique_moves.dart';
import 'package:pb_sim/src/match/match_state.dart';
import 'package:pb_sim/src/match/sim_event.dart';
import 'package:pb_sim/src/match/turn_effects.dart';
import 'package:pb_sim/src/pirate/ability.dart';
import 'package:pb_sim/src/pirate/pirate_spec.dart';
import 'package:pb_sim/src/projectile/projectile.dart';
import 'package:pb_sim/src/world/world.dart';

/// 설치탄 고유 부착(모레이·크라키). 처리했으면 true.
bool attachUnique(MatchState state, Projectile p, SideState target, int cell) {
  final spec = p.spec;
  TurnEffect effect(EffectKind kind, int trigger, int turns) => TurnEffect(
    kind: kind,
    owner: p.side,
    ownerSlot: p.slot,
    target: target.side,
    trigger: trigger,
    turnsLeft: turns,
    spec: spec,
    cell: cell,
  );
  switch (spec.ability) {
    case Ability.gnaw:
      state.effects
        ..add(effect(EffectKind.gnawBite, target.side, 1))
        ..add(effect(EffectKind.pumpOff, p.side, 1));
    case Ability.tentacle:
      // 붙는 순간 설치탄처럼 터지고(R1d), 촉수는 턴 시작에는 세지 않고(trigger −1)
      // 상대 턴 끝 침수 단계에서 센다.
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
        rng: state.rng,
      );
      state.effects.add(effect(EffectKind.tentacle, -1, spec.ammoValue));
    case _:
      return false;
  }
  state.events.add(
    SimEvent(SimEventKind.mineAttached, side: target.side, cell: cell),
  );
  return true;
}

/// 모레이 물어뜯기: 붙은 칸과 위·오른쪽·아래·왼쪽 블록에 인자만큼 피해.
void gnawBite(MatchState state, TurnEffect e) {
  final target = state.sides[e.target];
  final grid = target.grid;
  final cx = e.cell % grid.width;
  final cy = e.cell ~/ grid.width;
  final cells = [
    for (final (dx, dy) in const [(0, 0), (0, 1), (1, 0), (0, -1), (-1, 0)])
      if (grid.hasBlock(cx + dx, cy + dy)) grid.indexOf(cx + dx, cy + dy),
  ];
  damageCells(state, target, cells, e.spec.abilityValue);
}

/// 턴 끝 침수 단계에서 크라키 촉수가 지금 턴 진영 배에 침수를 더하고 1 줄어든다.
void runTentacles(MatchState state) {
  final side = state.activeSide;
  final ship = state.sides[side];
  for (final e in state.effects) {
    if (e.kind != EffectKind.tentacle || e.target != side) continue;
    addFlood(state, ship, e.spec.ammoValue2);
    e.turnsLeft--;
  }
  state.effects.removeWhere(
    (e) => e.kind == EffectKind.tentacle && e.turnsLeft <= 0,
  );
}

/// 지금 턴 진영 배의 펌프가 멈췄는가(모레이).
bool pumpsOffFor(MatchState state) => state.effects.any(
  (e) => e.kind == EffectKind.pumpOff && e.target == state.activeSide,
);

/// 펠리 투하 표시 요격: 상대 탄이 표시 지점(투하 높이) 1칸 안을 지나면 표시가 사라진다.
void interceptDrops(MatchState state, Projectile p, {int tick = 0}) {
  final hits = [
    for (final e in state.effects)
      if (e.kind == EffectKind.flockDrop &&
          e.owner != p.side &&
          (p.x - e.x).abs() <= cellUnit &&
          (p.y - flockDropHeight).abs() <= cellUnit)
        e,
  ];
  if (hits.isEmpty) return;
  state.effects.removeWhere(hits.contains);
  for (final e in hits) {
    state.events.add(
      SimEvent(
        SimEventKind.intercepted,
        side: e.owner,
        slot: e.ownerSlot,
        x: e.x,
        value: tick,
      ),
    );
  }
}

/// 만타 무작위 피해: 대상 배 블록 중 [count] 칸을 매치 난수로 골라 절반 피해.
void randomStrikes(
  MatchState state,
  SideState target,
  PirateSpec spec,
  int count,
) {
  final grid = target.grid;
  final blocks = [
    for (var i = 0; i < grid.cellCount; i++)
      if (grid.hasBlockAt(i)) i,
  ];
  if (blocks.isEmpty || count <= 0) return;
  final picks = [
    for (var n = 0; n < count; n++) blocks[state.rng.nextInt(blocks.length)],
  ];
  damageCells(
    state,
    target,
    picks,
    spec.blockDamage * uniqueHalfPercent ~/ 100,
  );
}

/// 탄종 설정: 볼케는 뚫을 층 수, 바라는 중력 없이 물속으로 (ADR-078).
void armUnique(Projectile p) {
  switch (p.spec.ability) {
    case Ability.drill:
      p.pierceLeft = p.spec.abilityValue;
    case Ability.torpedo:
      p
        ..gravity = false
        ..submerged = true;
    case _:
      break;
  }
}
