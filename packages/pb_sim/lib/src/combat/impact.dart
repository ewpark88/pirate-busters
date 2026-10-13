import 'package:pb_sim/src/combat/block_damage.dart';
import 'package:pb_sim/src/combat/boarding.dart';
import 'package:pb_sim/src/combat/module_effects.dart';
import 'package:pb_sim/src/match/match_state.dart';
import 'package:pb_sim/src/match/sim_event.dart';
import 'package:pb_sim/src/math/fx.dart';
import 'package:pb_sim/src/pirate/ammo.dart';
import 'package:pb_sim/src/pirate/crew.dart';
import 'package:pb_sim/src/pirate/pirate_spec.dart';
import 'package:pb_sim/src/ship/support.dart';

/// 폭발탄·화염탄이 아닌 탄의 착탄 칸 밖 폭발 피해 비율(%). 착탄 칸은 100%.
/// 폭발탄·화염탄은 사다리 값(BALANCE.md A4.8)을 쓴다.
const int blastEdgePercent = 50;

/// [spec] 의 바깥 칸 피해 비율(%).
int edgePercentOf(PirateSpec spec) => switch (spec.ammo) {
  AmmoType.explosive => spec.ammoValue,
  AmmoType.fire => spec.ammoValue2,
  _ => blastEdgePercent,
};

/// [target] 배의 로컬 칸 ([cx], [cy]) 에 착탄했다. 월드 착탄 지점은 ([x], [y]).
///
/// 순서: 폭발 반경 안 블록 피해(가운데 100%, 둘레는 바깥 칸 비율, 칸 순) → 지지 구조
/// 붕괴 → 모듈(돛대 붕괴) → 선실 해적 폭발 피해(슬롯 순) → 적 배 위 강습 해적 →
/// 선실이 없어진 해적 낙하(KO) (설계서 §2.3, §3.4, §4.8). [blockPercent] 는 블록 피해
/// 배율, [centerPiratePercent] 는 착탄 칸 해적 피해 배율(저격탄 치명).
void resolveImpact(
  SideState target, {
  required PirateSpec spec,
  required int cx,
  required int cy,
  required int x,
  required int y,
  required List<SimEvent> events,
  int blockPercent = 100,
  int centerPiratePercent = 100,
  bool hitBoarders = true,
}) {
  final grid = target.grid;
  final side = target.side;
  final r = cappedBlastRadius(spec.blastRadius);
  final edge = edgePercentOf(spec);
  final hadCabin = [for (final c in target.cabins) grid.hasBlock(c.x, c.y)];

  final damage = spec.blockDamage * blockPercent ~/ 100;
  for (var by = cy - r; by <= cy + r; by++) {
    for (var bx = cx - r; bx <= cx + r; bx++) {
      if (!_inBlast(bx - cx, by - cy, r) || !grid.inBounds(bx, by)) continue;
      final dmg = _falloff(damage, bx == cx && by == cy, edge);
      if (dmg > 0) damageBlock(grid, side, bx, by, dmg, events);
    }
  }
  for (final i in collapseUnsupported(grid)) {
    events.add(SimEvent(SimEventKind.blockCollapsed, side: side, cell: i));
  }
  // 부서진 모듈의 효과(돛대 붕괴)는 해적 피해보다 먼저 (설계서 §3.3).
  settleModules(target, events);

  final crew = target.crew;
  for (var slot = 0; slot < crew.size; slot++) {
    final c = target.cabins[slot];
    if (crew.pirates[slot].status != PirateStatus.aboard) continue;
    if (!_inBlast(c.x - cx, c.y - cy, r)) continue;
    final center = c.x == cx && c.y == cy;
    final base = center
        ? spec.pirateDamage * centerPiratePercent ~/ 100
        : spec.pirateDamage;
    crew.damage(slot, _falloff(base, center, edge), side, events);
  }
  // 이 배에 선 상대 강습 해적도 맞는다(그 강습 해적의 물기는 빼고, ADR-110).
  if (hitBoarders) {
    strikeBoarders(
      target,
      cx,
      cy,
      r,
      events,
      center: spec.pirateDamage * centerPiratePercent ~/ 100,
      edge: _falloff(spec.pirateDamage, false, edge),
    );
  }
  for (var slot = 0; slot < crew.size; slot++) {
    final c = target.cabins[slot];
    if (hadCabin[slot] && !grid.hasBlock(c.x, c.y)) {
      crew.fall(slot, side, events);
    }
  }
  dropUnsupportedBoarders(target, events);
}

/// 칸 단위 원형 폭발 범위 (dx² + dy² ≤ r²).
bool _inBlast(int dx, int dy, int r) => dx * dx + dy * dy <= r * r;

int _falloff(int damage, bool center, int edgePercent) =>
    center ? damage : roundDiv(damage * edgePercent, 100);
