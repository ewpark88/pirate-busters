import 'package:pb_sim/src/ship/ship_grid.dart';

/// 지지 구조 판정 (설계서 §3.4). 용골 줄(y = 0) 블록에서 상하좌우로 BFS 를 돌려
/// 닿지 않는 블록을 모두 없애고, 없앤 칸 인덱스를 오름차순으로 돌려준다.
///
/// 격자가 작아서(슬루프 96칸) 파괴가 일어날 때마다 전체를 다시 돈다.
List<int> collapseUnsupported(ShipGrid grid) {
  final w = grid.width;
  final h = grid.height;
  final reached = List<bool>.filled(grid.cellCount, false);
  final queue = <int>[];
  for (var x = 0; x < w; x++) {
    if (grid.hasBlockAt(x)) {
      reached[x] = true;
      queue.add(x);
    }
  }
  for (var head = 0; head < queue.length; head++) {
    final i = queue[head];
    final x = i % w;
    final y = i ~/ w;
    void visit(int nx, int ny) {
      if (nx < 0 || nx >= w || ny < 0 || ny >= h) return;
      final n = ny * w + nx;
      if (reached[n] || !grid.hasBlockAt(n)) return;
      reached[n] = true;
      queue.add(n);
    }

    visit(x + 1, y);
    visit(x - 1, y);
    visit(x, y + 1);
    visit(x, y - 1);
  }
  final removed = <int>[];
  for (var i = 0; i < grid.cellCount; i++) {
    if (grid.hasBlockAt(i) && !reached[i]) {
      grid.removeAt(i);
      removed.add(i);
    }
  }
  return removed;
}
