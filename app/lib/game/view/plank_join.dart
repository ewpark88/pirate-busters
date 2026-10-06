import 'dart:ui';

import 'package:flame/components.dart';
import 'package:pb_sim/pb_sim.dart';

/// 판자 이음 (설계서 §10.2): 같은 나무 재질 이웃끼리는 칸 테두리를 지워 판자가
/// 이어져 보이게 하고, 배 바깥 둘레에만 굵은 외곽선을 그린다. 그리기만 한다.
abstract final class PlankJoin {
  /// 이웃 방향 비트: 위·오른쪽·아래·왼쪽 (y 는 위로 클수록 높다).
  static const int up = 1;
  static const int right = 2;
  static const int down = 4;
  static const int left = 8;

  /// 타일 그림(64px)의 칸 테두리 두께(px). 이웃과 이어지는 변은 이만큼 잘라 늘린다.
  static const double border = 2;

  /// 이어 그리는 재질: 나무 판자 계열. 철판·망사는 칸마다 따로 보인다.
  static bool joins(int material) =>
      material == BlockMaterial.oak.index ||
      material == BlockMaterial.pine.index ||
      material == BlockMaterial.cork.index;

  /// 칸 ([x], [y]) 의 이음 비트: 같은 이음 재질 이웃이 있는 방향.
  /// [materials] 는 `ShipGrid.rawMaterials` 와 같은 줄 우선 배열이다.
  static int mask(List<int> materials, int width, int x, int y) {
    final height = materials.length ~/ width;
    final m = materials[y * width + x];
    if (!joins(m)) return 0;
    bool same(int nx, int ny) =>
        nx >= 0 &&
        nx < width &&
        ny >= 0 &&
        ny < height &&
        materials[ny * width + nx] == m;
    return (same(x, y + 1) ? up : 0) |
        (same(x + 1, y) ? right : 0) |
        (same(x, y - 1) ? down : 0) |
        (same(x - 1, y) ? left : 0);
  }

  /// [src] 그림 영역에서 이어지는 변의 테두리를 잘라낸 영역. 화면 위가 그림 위다.
  static Rect trimmed(Rect src, int mask) => Rect.fromLTRB(
    src.left + (mask & left != 0 ? border : 0),
    src.top + (mask & up != 0 ? border : 0),
    src.right - (mask & right != 0 ? border : 0),
    src.bottom - (mask & down != 0 ? border : 0),
  );

  static final Paint _tilePaint = Paint()..filterQuality = FilterQuality.medium;

  /// 이음을 반영해 타일 [sprite] 를 [dst] 칸에 그린다.
  static void drawTile(Canvas canvas, Sprite sprite, Rect dst, int mask) {
    canvas.drawImageRect(
      sprite.image,
      trimmed(sprite.src, mask),
      dst,
      _tilePaint,
    );
  }

  static final Paint _outline = Paint()
    ..color = const Color(0xFF2A160B)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.5
    ..strokeCap = StrokeCap.round;

  /// 블록이 있는 칸과 없는 칸 사이 변(배 바깥 둘레·구멍 둘레)에 외곽선을 긋는다.
  /// [hidden] 의 (x, y, 방향 비트) 변은 선체 판이 덮으므로 건너뛴다.
  static void outline(
    Canvas canvas,
    List<int> materials,
    int width,
    Rect Function(int x, int y) cellRect, {
    Set<(int, int, int)> hidden = const {},
  }) {
    final height = materials.length ~/ width;
    bool filled(int x, int y) =>
        x >= 0 &&
        x < width &&
        y >= 0 &&
        y < height &&
        materials[y * width + x] != ShipGrid.emptyCell;
    final path = Path();
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        if (!filled(x, y)) continue;
        final r = cellRect(x, y);
        if (!filled(x, y + 1) && !hidden.contains((x, y, up))) {
          path
            ..moveTo(r.left, r.top)
            ..lineTo(r.right, r.top);
        }
        if (!filled(x, y - 1) && !hidden.contains((x, y, down))) {
          path
            ..moveTo(r.left, r.bottom)
            ..lineTo(r.right, r.bottom);
        }
        if (!filled(x - 1, y) && !hidden.contains((x, y, left))) {
          path
            ..moveTo(r.left, r.top)
            ..lineTo(r.left, r.bottom);
        }
        if (!filled(x + 1, y) && !hidden.contains((x, y, right))) {
          path
            ..moveTo(r.right, r.top)
            ..lineTo(r.right, r.bottom);
        }
      }
    }
    canvas.drawPath(path, _outline);
  }
}
