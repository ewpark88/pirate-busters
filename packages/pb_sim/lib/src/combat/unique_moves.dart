/// 해적 고유 동작 도우미: 칸 피해·미끄러짐·쓸어냄·점프·소환 (ADR-078).
library;

import 'package:pb_sim/src/combat/ability_effects.dart';
import 'package:pb_sim/src/combat/impact.dart';
import 'package:pb_sim/src/combat/module_effects.dart';
import 'package:pb_sim/src/match/match_state.dart';
import 'package:pb_sim/src/match/sim_event.dart';
import 'package:pb_sim/src/match/turn_effects.dart';
import 'package:pb_sim/src/pirate/ability.dart';
import 'package:pb_sim/src/pirate/crew.dart';
import 'package:pb_sim/src/pirate/pirate_spec.dart';
import 'package:pb_sim/src/projectile/projectile.dart';
import 'package:pb_sim/src/ship/support.dart';
import 'package:pb_sim/src/world/world.dart';

/// 해적 고유 동작의 ‘절반’ 피해 비율(%) (BALANCE.md A4.2, 임시값 ADR-078).
const int uniqueHalfPercent = 50;

/// 반경 0 사본.
PirateSpec singleCell(PirateSpec s) => s.withDamage(
  blockDamage: s.blockDamage,
  pirateDamage: s.pirateDamage,
  blastRadius: 0,
);

/// [cells](칸 인덱스, 순서대로)의 블록에 [amount] 피해를 주고 붕괴·모듈·낙하를 정리한다.
void damageCells(
  MatchState state,
  SideState target,
  List<int> cells,
  int amount,
) {
  final grid = target.grid;
  final events = state.events;
  final hadCabin = [for (final c in target.cabins) grid.hasBlock(c.x, c.y)];
  final hit = <int>[];
  for (final i in cells) {
    if (!grid.hasBlockAt(i)) continue;
    hit.add(i);
    if (grid.damage(i % grid.width, i ~/ grid.width, amount)) {
      events.add(
        SimEvent(SimEventKind.blockDestroyed, side: target.side, cell: i),
      );
    }
  }
  for (final i in collapseUnsupported(grid)) {
    events.add(
      SimEvent(SimEventKind.blockCollapsed, side: target.side, cell: i),
    );
  }
  settleModules(target, events, rng: state.rng, hit: hit);
  for (var slot = 0; slot < target.crew.size; slot++) {
    final c = target.cabins[slot];
    if (hadCabin[slot] && !grid.hasBlock(c.x, c.y)) {
      target.crew.fall(slot, target.side, events);
    }
  }
}

/// 칸 [cell] 에 [spec] 으로 한 번 더 친다(해적 피해 없음).
void strikeCell(
  MatchState state,
  SideState target,
  PirateSpec spec,
  int cell, {
  required int block,
}) {
  final grid = target.grid;
  final cx = cell % grid.width;
  final cy = cell ~/ grid.width;
  if (!grid.hasBlock(cx, cy)) return;
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
    blockPercent: block,
    centerPiratePercent: 0,
  );
}

/// 핑구: 진행 방향으로 [Ability] 인자 칸만큼 각 세로줄 맨 위 블록을 절반으로 친다.
void slideAlong(
  MatchState state,
  Projectile p,
  SideState target,
  int cx,
  int x,
) {
  final grid = target.grid;
  final ahead = x + (p.vx >= 0 ? cellUnit : -cellUnit);
  final step = target.frame.toLocalX(ahead) > target.frame.toLocalX(x) ? 1 : -1;
  final spec = singleCell(p.spec);
  for (var k = 1; k <= p.spec.abilityValue; k++) {
    final col = cx + step * k;
    if (col < 0 || col >= grid.width) return;
    var top = -1;
    for (var cy = grid.height - 1; cy >= 0 && top < 0; cy--) {
      if (grid.hasBlock(col, cy)) top = cy;
    }
    if (top < 0) return;
    final (wx, wy) = target.frame.cellCenter(col, top);
    resolveImpact(
      target,
      spec: spec,
      cx: col,
      cy: top,
      x: wx,
      y: wy,
      events: state.events,
      rng: state.rng,
      blockPercent: uniqueHalfPercent,
    );
  }
}

/// 오르카: 침수 [flood](0.1%p)를 더하고 선실 블록이 없어 드러난 해적을 쓸어낸다.
void sweepDeck(MatchState state, SideState target, int flood) {
  addFlood(state, target, flood);
  for (var slot = 0; slot < target.crew.size; slot++) {
    final c = target.cabins[slot];
    if (!target.grid.hasBlock(c.x, c.y)) {
      target.crew.fall(slot, target.side, state.events);
    }
  }
}

/// 랍: 쓰러뜨릴 때마다 가장 가까운 배 위 해적으로 뛰어 해적 피해를 준다(사다리 횟수).
void leapKills(
  MatchState state,
  SideState target,
  PirateSpec spec,
  int cx,
  int cy,
  int from,
) {
  var lx = cx;
  var ly = cy;
  var since = from;
  for (var n = 0; n < spec.ammoValue; n++) {
    final events = state.events;
    var downed = false;
    for (var i = since; i < events.length; i++) {
      final e = events[i];
      if (e.kind == SimEventKind.pirateDown && e.side == target.side) {
        downed = true;
      }
    }
    if (!downed) return;
    final slot = nearestAboard(target, lx, ly);
    if (slot < 0) return;
    since = events.length;
    final c = target.cabins[slot];
    lx = c.x;
    ly = c.y;
    target.crew.damage(slot, spec.pirateDamage, target.side, events);
  }
}

/// [cx], [cy] 에서 가장 가까운 배 위 해적 슬롯(같으면 낮은 슬롯), 없으면 −1.
int nearestAboard(SideState target, int cx, int cy) {
  var best = -1;
  var bestD = 0;
  for (var slot = 0; slot < target.crew.size; slot++) {
    if (target.crew.pirates[slot].status != PirateStatus.aboard) continue;
    final c = target.cabins[slot];
    final d = (c.x - cx) * (c.x - cx) + (c.y - cy) * (c.y - cy);
    if (best < 0 || d < bestD) {
      best = slot;
      bestD = d;
    }
  }
  return best;
}

/// 데비: 해골 선원 인자 명이 다음 상대 턴 시작에 해적 피해 50% 로 문다.
void summonSkeletons(
  MatchState state,
  Projectile p,
  SideState target,
  int cell,
) {
  final spec = p.spec;
  final skeleton = spec.withDamage(
    blockDamage: 0,
    pirateDamage: spec.pirateDamage * uniqueHalfPercent ~/ 100,
    blastRadius: 1,
  );
  for (var i = 0; i < spec.abilityValue; i++) {
    state.effects.add(
      TurnEffect(
        kind: EffectKind.biteAgain,
        owner: p.side,
        ownerSlot: p.slot,
        target: target.side,
        trigger: target.side,
        turnsLeft: 1,
        spec: skeleton,
        cell: cell,
      ),
    );
  }
}
