import 'package:pb_sim/src/match/match_state.dart';
import 'package:pb_sim/src/match/sim_event.dart';
import 'package:pb_sim/src/math/fx.dart';
import 'package:pb_sim/src/pirate/crew.dart';
import 'package:pb_sim/src/pirate/pirate_spec.dart';
import 'package:pb_sim/src/ship/support.dart';
import 'package:pb_sim/src/world/world.dart';

/// 착탄 칸 밖 폭발 피해 비율(%). 착탄 칸은 100%.
const int blastEdgePercent = 50;

/// 바다에 빠진 해적이 폭발·물보라에 맞는 최소 거리: 1칸.
const int swimmerHitRange = cellUnit;

/// [target] 배의 로컬 칸 ([cx], [cy]) 에 착탄했다. 월드 착탄 지점은 ([x], [y]).
///
/// 순서: 블록 피해(칸 인덱스 순) → 지지 구조 붕괴 → 선실 해적 폭발 피해(슬롯 순) →
/// 헤엄치는 해적 → 선실이 없어진 해적 낙하 (설계서 §2.3, §3.4).
void resolveImpact(
  SideState target, {
  required PirateSpec spec,
  required int cx,
  required int cy,
  required int x,
  required int y,
  required List<SimEvent> events,
}) {
  final grid = target.grid;
  final side = target.side;
  final r = spec.blastRadius;
  final hadCabin = [for (final c in target.cabins) grid.hasBlock(c.x, c.y)];

  for (var by = cy - r; by <= cy + r; by++) {
    for (var bx = cx - r; bx <= cx + r; bx++) {
      if (!_inBlast(bx - cx, by - cy, r) || !grid.inBounds(bx, by)) continue;
      final dmg = _falloff(spec.blockDamage, bx == cx && by == cy);
      if (grid.damage(bx, by, dmg)) {
        events.add(
          SimEvent(
            SimEventKind.blockDestroyed,
            side: side,
            cell: grid.indexOf(bx, by),
          ),
        );
      }
    }
  }
  for (final i in collapseUnsupported(grid)) {
    events.add(SimEvent(SimEventKind.blockCollapsed, side: side, cell: i));
  }

  final crew = target.crew;
  for (var slot = 0; slot < crew.size; slot++) {
    final c = target.cabins[slot];
    if (crew.pirates[slot].status != PirateStatus.aboard) continue;
    if (!_inBlast(c.x - cx, c.y - cy, r)) continue;
    final dmg = _falloff(spec.pirateDamage, c.x == cx && c.y == cy);
    crew.damage(slot, dmg, side, events);
  }
  _hitSwimmers(target, x, y, r, events);
  for (var slot = 0; slot < crew.size; slot++) {
    final c = target.cabins[slot];
    if (hadCabin[slot] && !grid.hasBlock(c.x, c.y)) {
      crew.fall(slot, side, events);
    }
  }
}

/// 탄이 [target] 쪽 바다 ([x], 0) 에 떨어졌다. 블록은 다치지 않고, 가까이
/// 헤엄치는 해적만 맞는다.
void resolveSplash(
  SideState target, {
  required PirateSpec spec,
  required int x,
  required List<SimEvent> events,
}) {
  _hitSwimmers(target, x, 0, spec.blastRadius, events);
}

void _hitSwimmers(
  SideState target,
  int x,
  int y,
  int radius,
  List<SimEvent> events,
) {
  final range = radius * cellUnit > swimmerHitRange
      ? radius * cellUnit
      : swimmerHitRange;
  final (sx, sy) = target.swimmerPosition;
  final dx = sx - x;
  final dy = sy - y;
  if (dx * dx + dy * dy > range * range) return;
  final crew = target.crew;
  for (var slot = 0; slot < crew.size; slot++) {
    if (crew.pirates[slot].status == PirateStatus.swimming) {
      crew.damage(slot, 1, target.side, events);
    }
  }
}

/// 칸 단위 원형 폭발 범위 (dx² + dy² ≤ r²).
bool _inBlast(int dx, int dy, int r) => dx * dx + dy * dy <= r * r;

int _falloff(int damage, bool center) =>
    center ? damage : roundDiv(damage * blastEdgePercent, 100);
