import 'package:pb_sim/src/ship/blueprint.dart';
import 'package:pb_sim/src/ship/hull.dart';
import 'package:pb_sim/src/ship/module.dart';

/// 건조 검증 (설계서 §3.3, §3.4). 규칙을 어기면 첫 문제를 설명하는 글(개발용,
/// 화면에 쓰지 않는다), 지키면 null. 조선소 화면은 [disconnectedBlocks] 로 끊긴
/// 블록을 따로 칠한다.
///
/// 순서: 격자 범위 → 칸 중복 → 블록 건조 포인트 → 용골 연결 → 선실 → 모듈 → 합계
/// 건조 포인트. [cells] 는 (y, x) 순으로 정렬돼 있어야 한다.
String? buildProblem(
  HullSpec hull,
  List<BlockCell> cells, {
  required List<CabinCell> cabins,
  required List<ModuleCell> modules,
}) {
  var cost = 0;
  for (var i = 0; i < cells.length; i++) {
    final c = cells[i];
    if (c.x < 0 || c.x >= hull.width || c.y < 0 || c.y >= hull.height) {
      return '격자 밖 블록: (${c.x}, ${c.y})';
    }
    if (i > 0 && cells[i - 1].x == c.x && cells[i - 1].y == c.y) {
      return '같은 칸에 블록이 둘: (${c.x}, ${c.y})';
    }
    cost += c.material.cost;
  }
  if (cost > hull.buildPoints) return '건조 포인트 초과: $cost > ${hull.buildPoints}';
  if (!cells.any((c) => c.y == 0)) return '용골 줄(y = 0)에 블록이 없다';
  final loose = disconnectedBlocks(hull, cells);
  if (loose.isNotEmpty) {
    final c = loose.first;
    return '용골과 이어지지 않은 블록: (${c.x}, ${c.y})';
  }
  bool hasBlock(int x, int y) => cells.any((b) => b.x == x && b.y == y);
  final cabinProblem = _cabinProblem(hull, cabins, hasBlock);
  if (cabinProblem != null) return cabinProblem;
  final moduleProblemText = moduleProblem(
    hull,
    sortModules(modules),
    hasBlock: hasBlock,
    isCabin: (x, y) => cabins.any((c) => c.x == x && c.y == y),
  );
  if (moduleProblemText != null) return moduleProblemText;
  cost += moduleCost(modules);
  if (cost > hull.buildPoints) return '건조 포인트 초과: $cost > ${hull.buildPoints}';
  return null;
}

/// 용골(y = 0 줄)과 상하좌우로 이어지지 않은 블록 (설계서 §3.4). 조선소에서 빨간색.
List<BlockCell> disconnectedBlocks(HullSpec hull, List<BlockCell> cells) {
  final w = hull.width;
  final filled = List<bool>.filled(w * hull.height, false);
  for (final c in cells) {
    if (c.x >= 0 && c.x < w && c.y >= 0 && c.y < hull.height) {
      filled[c.y * w + c.x] = true;
    }
  }
  final seen = List<bool>.filled(filled.length, false);
  final queue = <int>[
    for (var x = 0; x < w; x++)
      if (filled[x]) x,
  ];
  for (final i in queue) {
    seen[i] = true;
  }
  for (var head = 0; head < queue.length; head++) {
    final i = queue[head];
    final x = i % w;
    final y = i ~/ w;
    for (final (nx, ny) in [(x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)]) {
      if (nx < 0 || nx >= w || ny < 0 || ny >= hull.height) continue;
      final j = ny * w + nx;
      if (filled[j] && !seen[j]) {
        seen[j] = true;
        queue.add(j);
      }
    }
  }
  return [
    for (final c in cells)
      if (c.x >= 0 &&
          c.x < w &&
          c.y >= 0 &&
          c.y < hull.height &&
          !seen[c.y * w + c.x])
        c,
  ];
}

String? _cabinProblem(
  HullSpec hull,
  List<CabinCell> cabins,
  bool Function(int x, int y) hasBlock,
) {
  if (cabins.length != hull.cabinSlots) {
    return '선실 수는 ${hull.cabinSlots} 이어야 한다: ${cabins.length}';
  }
  for (var i = 0; i < cabins.length; i++) {
    final c = cabins[i];
    if (!hasBlock(c.x, c.y)) return '선실은 블록 위에 있어야 한다: (${c.x}, ${c.y})';
    for (var j = 0; j < i; j++) {
      if (cabins[j].x == c.x && cabins[j].y == c.y) {
        return '같은 칸에 선실이 둘: (${c.x}, ${c.y})';
      }
    }
  }
  return null;
}
