import 'package:flame/components.dart';
import 'package:pirate_busters/game/view/collapse_fx.dart';
import 'package:pirate_busters/game/view/explosion_fx.dart';
import 'package:pirate_busters/game/view/fx_layer.dart';

/// 파괴 조각과 덩어리 붕괴 (설계서 §10.4, A32). 판정은 이미 끝났고 그리기만 한다.
extension BreakageFx on FxLayer {
  /// 부서진 칸 (설계서 §10.4 파괴): [tile] 그림이 재질별 조각으로 튀어 돌며 떨어지고
  /// 물에 닿으면 작은 물보라를 낸다. [from] 은 착탄 지점(없으면 위로 튄다), [seed] 는 칸
  /// 위치. 그림이 없으면 나무 조각 파편만 튄다.
  void shatter(
    Vector2 at, {
    required Sprite? tile,
    required int seed,
    bool iron = false,
    Vector2? from,
  }) {
    spawn(ExplosionFx.debris(sprites, rnd, at, count: few(3), plank: !iron));
    if (tile == null) return;
    final away = from == null ? 0.0 : (at.x - from.x).clamp(-24.0, 24.0) / 24;
    final plan = shardPlan(
      seed,
      iron: iron,
      fewer: few(2) == 1,
      away: away,
    );
    for (final s in plan) {
      final src = tile.srcSize;
      final part = Sprite(
        tile.image,
        srcPosition:
            tile.srcPosition + Vector2(s.src.left * src.x, s.src.top * src.y),
        srcSize: Vector2(s.src.width * src.x, s.src.height * src.y),
      );
      final size = Vector2(s.src.width * pieceCell, s.src.height * pieceCell);
      final center = Vector2(
        (s.src.center.dx - .5) * pieceCell,
        (s.src.center.dy - .5) * pieceCell,
      );
      spawn(
        FallingPiece(
          parts: [PiecePart(part, Vector2.zero(), size)],
          at: at + center,
          velocity: s.velocity,
          spin: s.spin,
          onSplash: (sea) => spawn(
            popSprite('fx/splash.png', sea - Vector2(0, 12), 30, .4),
          ),
        ),
      );
    }
  }

  /// 지지가 끊긴 칸들 (설계서 §10.4 붕괴): 이웃끼리 한 덩어리로 묶어 배 가운데에서 먼
  /// 쪽으로 기울며 떨어뜨린다. 덩어리마다 [collapseStagger] 초씩 늦게 떨어지고, 수면에
  /// 닿으면 흔들림과 큰 물보라를 낸다. [cellAt]·[tileOf] 는 칸의 월드 위치와 그림,
  /// [shipX] 는 배 가운데 x 다. 덩어리 수를 돌려준다.
  int collapseCells(
    List<int> cells,
    int width, {
    required Vector2 Function(int cell) cellAt,
    required Sprite? Function(int cell) tileOf,
    required double shipX,
  }) {
    final groups = groupCells(cells, width);
    for (var g = 0; g < groups.length; g++) {
      final group = groups[g];
      final spots = [for (final c in group) cellAt(c)];
      final center = spots.reduce((a, b) => a + b) / spots.length.toDouble();
      final parts = [
        for (var i = 0; i < group.length; i++)
          if (tileOf(group[i]) case final sprite?)
            PiecePart(sprite, spots[i] - center, Vector2.all(pieceCell)),
      ];
      final outward = center.x >= shipX ? 1.0 : -1.0;
      spawn(
        ExplosionFx.debris(sprites, rnd, center, count: few(2), plank: true),
      );
      if (parts.isEmpty) continue;
      spawn(
        FallingPiece(
          parts: parts,
          at: center,
          velocity: Vector2(outward * 30, 0),
          spin: outward * collapseSpin(group.length),
          delay: g * collapseStagger,
          onSplash: (sea) {
            nudge(group.length >= 4 ? 0.5 : 0.35);
            spawn(
              popSprite(
                'fx/collapse/splash_big.png',
                sea - Vector2(0, 22),
                64.0 + group.length * 4,
                .5,
              ),
            );
            if (few(2) == 2) {
              spawn(popSprite('fx/collapse/foam_ring.png', sea, 56, 0.6));
            }
          },
        ),
      );
    }
    return groups.length;
  }
}
