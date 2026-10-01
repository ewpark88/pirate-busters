import 'package:pb_sim/src/math/fx.dart';
import 'package:pb_sim/src/random/xorshift32.dart';
import 'package:pb_sim/src/ship/ship_grid.dart';

/// 균열 피해 (설계서 §4.8, BALANCE.md A4.8, ADR-052).
///
/// 폭발 범위가 있는 탄은 착탄 칸에 피해 전부를 주고, 바깥 몫을 균열 조각으로
/// 나눠 매치 시드 난수로 착탄 칸에서 지그재그로 흩뿌린다. 조각 수는 반경 안
/// 바깥 칸 수, 조각 하나의 피해는 바깥 칸 비율만큼이라 기대 총피해는 바깥 칸
/// 균일 피해와 같다.

/// 8방향 고정 순서(행 우선). 걸음마다 이 중 하나를 난수로 고른다.
const List<(int, int)> crackDirections = [
  (-1, -1),
  (0, -1),
  (1, -1),
  (-1, 0),
  (1, 0),
  (-1, 1),
  (0, 1),
  (1, 1),
];

/// 반경 [r] 안 바깥 칸 수 = 균열 조각 수 (반경 1칸 → 4개, 2칸 → 12개).
int crackShardCount(int r) {
  var n = 0;
  for (var dy = -r; dy <= r; dy++) {
    for (var dx = -r; dx <= r; dx++) {
      if ((dx != 0 || dy != 0) && dx * dx + dy * dy <= r * r) n++;
    }
  }
  return n;
}

/// 조각 하나의 피해: 기본 피해 × 바깥 칸 비율(%), 반올림.
int crackShardDamage(int damage, int edgePercent) =>
    roundDiv(damage * edgePercent, 100);

/// 조각 하나가 착탄 칸 ([cx], [cy]) 에서 걸어가 멈추는 칸 인덱스.
///
/// 걸음 수는 1 ~ [r] + 1. 걸음마다 8방향 중 하나를 [rng] 로 고르고, 그 칸에 블록이
/// 없거나(빈 칸·바다·배 밖) 착탄 칸이면 더 가지 않는다: 첫 걸음이면 조각은 바다로
/// 흩어져 사라지고(−1), 도중이면 그 자리에서 멈춘다 (ADR-056: 가장자리에서는
/// 바깥 피해가 버려지던 원래 균형을 지킨다).
int walkCrackShard(ShipGrid grid, int cx, int cy, int r, XorShift32 rng) {
  final steps = 1 + rng.nextInt(r + 1);
  var x = cx;
  var y = cy;
  var moved = false;
  for (var s = 0; s < steps; s++) {
    final (dx, dy) = crackDirections[rng.nextInt(crackDirections.length)];
    final nx = x + dx;
    final ny = y + dy;
    if (nx == cx && ny == cy) break;
    if (!grid.inBounds(nx, ny) || !grid.hasBlock(nx, ny)) break;
    x = nx;
    y = ny;
    moved = true;
  }
  return moved ? grid.indexOf(x, y) : -1;
}
