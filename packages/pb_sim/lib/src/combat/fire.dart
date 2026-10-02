import 'package:pb_sim/src/combat/module_effects.dart';
import 'package:pb_sim/src/match/match_state.dart';
import 'package:pb_sim/src/match/sim_event.dart';
import 'package:pb_sim/src/math/fx.dart';
import 'package:pb_sim/src/pirate/crew.dart';
import 'package:pb_sim/src/random/xorshift32.dart';
import 'package:pb_sim/src/ship/flooding.dart';
import 'package:pb_sim/src/ship/material.dart';
import 'package:pb_sim/src/ship/support.dart';

/// 불붙은 블록의 턴 끝 피해 (BALANCE.md A2.5, 임시값 ADR-075, R1d 10 → 6).
const int fireBlockDamage = 6;

/// 불붙은 선실 칸 해적의 턴 끝 피해 (BALANCE.md A2.5, 임시값 ADR-075).
const int firePirateDamage = 10;

/// 이웃 나무 블록으로 번질 확률(%): 소나무 50, 그 밖의 나무 25 (BALANCE.md A2.5).
const int fireSpreadPercent = 25;
const int pineSpreadPercent = 50;

/// 화상 지대 반경: 착탄 칸 중심 3×3 (BALANCE.md A2.5, 임시값 ADR-075).
const int fireZoneRadius = 1;

/// 번진 불과 모듈 폭발 불의 지속 턴 (BALANCE.md A2.5, 임시값 ADR-075).
const int spreadFireTurns = 2;

/// [ship] 배 로컬 칸 ([cx], [cy]) 둘레 [radius] 칸(정사각형) 블록에 불을 붙인다
/// (설계서 §2.5). 철판과 물에 잠긴 칸은 붙지 않는다. 이미 타는 칸은 더 긴 쪽·큰 쪽을
/// 남긴다. 칸 인덱스 순서로 본다.
void igniteAround(
  SideState ship,
  int cx,
  int cy, {
  required int radius,
  required int turns,
  required int extraPercent,
  required List<SimEvent> events,
}) {
  for (var y = cy - radius; y <= cy + radius; y++) {
    for (var x = cx - radius; x <= cx + radius; x++) {
      _ignite(ship, x, y, turns, extraPercent, events);
    }
  }
}

bool _ignite(
  SideState ship,
  int x,
  int y,
  int turns,
  int extra,
  List<SimEvent> events,
) {
  final grid = ship.grid;
  if (turns <= 0 || !grid.hasBlock(x, y)) return false;
  if (grid.materialAt(x, y)!.fireImmune) return false;
  if (submersionOf(y, ship.draft) != Submersion.dry) return false;
  final i = grid.indexOf(x, y);
  final fresh = ship.fireTurns[i] == 0;
  if (turns > ship.fireTurns[i]) ship.fireTurns[i] = turns;
  if (extra > ship.fireExtra[i]) ship.fireExtra[i] = extra;
  if (fresh) {
    events.add(SimEvent(SimEventKind.ignited, side: ship.side, cell: i));
  }
  return fresh;
}

/// 턴 끝 화재 (설계서 §2.3 턴 끝 처리 1번째, §2.5): [ship] 은 지금 턴을 둔 배.
///
/// 순서: 꺼질 칸 정리(블록 없음·물에 잠김) → 타는 칸마다 블록 피해와 선실 해적 피해
/// (칸 인덱스 순) → 붕괴·모듈 → 떨어진 해적 → 번짐(타던 칸 순, 매치 난수 [rng]) →
/// 타던 칸 지속 턴 1 감소. 이번에 번진 불은 줄이지 않는다.
void burnAtTurnEnd(SideState ship, XorShift32 rng, List<SimEvent> events) {
  final grid = ship.grid;
  final burning = <int>[];
  for (var i = 0; i < grid.cellCount; i++) {
    if (ship.fireTurns[i] == 0) continue;
    final y = i ~/ grid.width;
    if (!grid.hasBlockAt(i) || submersionOf(y, ship.draft) != Submersion.dry) {
      _douse(ship, i);
      continue;
    }
    burning.add(i);
  }
  if (burning.isEmpty) return;
  final hadCabin = [for (final c in ship.cabins) grid.hasBlock(c.x, c.y)];
  final hit = <int>[];
  for (final i in burning) {
    final x = i % grid.width;
    final y = i ~/ grid.width;
    final dmg = roundDiv(fireBlockDamage * (100 + ship.fireExtra[i]), 100);
    hit.add(i);
    events.add(SimEvent(SimEventKind.burned, side: ship.side, cell: i));
    if (grid.damage(x, y, dmg)) {
      events.add(
        SimEvent(SimEventKind.blockDestroyed, side: ship.side, cell: i),
      );
    }
    for (var slot = 0; slot < ship.crew.size; slot++) {
      final c = ship.cabins[slot];
      if (c.x != x || c.y != y) continue;
      if (ship.crew.pirates[slot].status != PirateStatus.aboard) continue;
      ship.crew.damage(slot, firePirateDamage, ship.side, events);
    }
  }
  for (final i in collapseUnsupported(grid)) {
    events.add(SimEvent(SimEventKind.blockCollapsed, side: ship.side, cell: i));
  }
  settleModules(ship, events, rng: rng, hit: hit);
  for (var slot = 0; slot < ship.crew.size; slot++) {
    final c = ship.cabins[slot];
    if (hadCabin[slot] && !grid.hasBlock(c.x, c.y)) {
      ship.crew.fall(slot, ship.side, events);
    }
  }
  for (final i in burning) {
    if (grid.hasBlockAt(i)) _spread(ship, i, rng, events);
  }
  for (final i in burning) {
    if (ship.fireTurns[i] > 0) ship.fireTurns[i]--;
    if (ship.fireTurns[i] == 0 || !grid.hasBlockAt(i)) _douse(ship, i);
  }
}

/// 타는 칸 [i] 의 이웃(위·오른쪽·아래·왼쪽) 중 붙을 수 있는 블록 하나를 고르고
/// 그 재질의 확률로 번진다. 후보가 없으면 난수를 뽑지 않는다.
void _spread(SideState ship, int i, XorShift32 rng, List<SimEvent> events) {
  final grid = ship.grid;
  final x = i % grid.width;
  final y = i ~/ grid.width;
  final candidates = <(int, int)>[];
  for (final (dx, dy) in const [(0, 1), (1, 0), (0, -1), (-1, 0)]) {
    final nx = x + dx;
    final ny = y + dy;
    if (!grid.hasBlock(nx, ny)) continue;
    if (grid.materialAt(nx, ny)!.fireImmune) continue;
    if (submersionOf(ny, ship.draft) != Submersion.dry) continue;
    if (ship.fireTurns[grid.indexOf(nx, ny)] > 0) continue;
    candidates.add((nx, ny));
  }
  if (candidates.isEmpty) return;
  final (nx, ny) = candidates[rng.nextInt(candidates.length)];
  final chance = grid.materialAt(nx, ny) == BlockMaterial.pine
      ? pineSpreadPercent
      : fireSpreadPercent;
  if (rng.nextInt(100) >= chance) return;
  _ignite(ship, nx, ny, spreadFireTurns, ship.fireExtra[i], events);
}

void _douse(SideState ship, int i) {
  ship
    ..fireTurns[i] = 0
    ..fireExtra[i] = 0;
}
