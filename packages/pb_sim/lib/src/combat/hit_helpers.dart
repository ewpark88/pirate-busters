/// 착탄 도우미: 칸 피해·가까운 해적·흘수선 칸·배 밀기 (설계서 §4.8).
library;

import 'package:pb_sim/src/combat/block_damage.dart';
import 'package:pb_sim/src/combat/module_effects.dart';
import 'package:pb_sim/src/match/match_state.dart';
import 'package:pb_sim/src/match/sim_event.dart';
import 'package:pb_sim/src/pirate/crew.dart';
import 'package:pb_sim/src/pirate/pirate_spec.dart';
import 'package:pb_sim/src/ship/motion.dart';
import 'package:pb_sim/src/ship/support.dart';
import 'package:pb_sim/src/world/world.dart';

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
  for (final i in cells) {
    if (!grid.hasBlockAt(i)) continue;
    damageBlock(
      grid,
      target.side,
      i % grid.width,
      i ~/ grid.width,
      amount,
      events,
    );
  }
  for (final i in collapseUnsupported(grid)) {
    events.add(
      SimEvent(SimEventKind.blockCollapsed, side: target.side, cell: i),
    );
  }
  settleModules(target, events);
  for (var slot = 0; slot < target.crew.size; slot++) {
    final c = target.cabins[slot];
    if (hadCabin[slot] && !grid.hasBlock(c.x, c.y)) {
      target.crew.fall(slot, target.side, events);
    }
  }
}

/// 배 위 해적 슬롯을 ([cx], [cy]) 에서 가까운 순(같으면 낮은 슬롯)으로.
List<int> aboardByDistance(SideState target, int cx, int cy) {
  final list = <(int, int)>[];
  for (var slot = 0; slot < target.crew.size; slot++) {
    if (target.crew.pirates[slot].status != PirateStatus.aboard) continue;
    final c = target.cabins[slot];
    list.add(((c.x - cx) * (c.x - cx) + (c.y - cy) * (c.y - cy), slot));
  }
  list.sort((a, b) => a.$1 != b.$1 ? a.$1 - b.$1 : a.$2 - b.$2);
  return [for (final (_, slot) in list) slot];
}

/// [cx] 세로줄에서 흘수선에 가장 가까운 블록 칸 인덱스. 없으면 −1.
int waterlineCellIn(SideState ship, int cx) {
  final grid = ship.grid;
  if (cx < 0 || cx >= grid.width) return -1;
  final water = (ship.draft ~/ cellUnit).clamp(0, grid.height - 1);
  for (var d = 0; d < grid.height; d++) {
    for (final cy in [water - d, water + d]) {
      if (cy >= 0 && cy < grid.height && grid.hasBlock(cx, cy)) {
        return grid.indexOf(cx, cy);
      }
    }
  }
  return -1;
}

/// [target] 배를 [cells] 칸 민다(음수면 끌어당긴다). 그 배 기준 뒤로 가는 쪽이
/// 미는 것이다. 바다 끝·최소 간격에서 멈춘다 (설계서 §2.6·§4.8).
void pushShip(MatchState state, SideState target, int cells) {
  final moved = shoveShip(
    target,
    state.otherOf(target.side),
    state.rules,
    -cells * cellUnit,
  );
  if (moved == 0) return;
  state.events.add(
    SimEvent(
      SimEventKind.pushed,
      side: target.side,
      value: moved,
      x: target.bowX,
    ),
  );
}
