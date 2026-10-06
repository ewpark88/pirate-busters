import 'dart:math' as math;
import 'dart:ui';

import 'package:pb_sim/pb_sim.dart';

/// 보스 기믹 표시 (설계서 §5.4). 판정은 시뮬레이션에 있고 그리기만 한다.
abstract final class GimmickMarks {
  static final Paint _plate = Paint()..color = const Color(0x997D8590);
  static final Paint _rim = Paint()
    ..color = const Color(0xFF2E3440)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  static final Paint _rivet = Paint()..color = const Color(0xFF2E3440);

  /// 뱃머리 철판 방패: 남은 방패 칸에 철판을 덧대고, 서 있는 동안 반짝임이 지나간다.
  /// [t] 는 초 단위 시계(반짝임 위치).
  static void shield(
    Canvas canvas,
    SideState ship,
    List<int> materials,
    Rect Function(int x, int y) cellRect,
    double t,
  ) {
    final width = ship.grid.width;
    final cells = [
      for (final i in ship.shieldCells)
        if (materials[i] != ShipGrid.emptyCell) i,
    ];
    if (cells.isEmpty) return;
    final shine = (t * 0.6) % 1;
    for (final i in cells) {
      final r = cellRect(i % width, i ~/ width).deflate(2);
      final plate = RRect.fromRectAndRadius(r, const Radius.circular(4));
      canvas
        ..drawRRect(plate, _plate)
        ..drawRRect(plate, _rim);
      for (final (dx, dy) in const [
        (0.2, 0.2),
        (0.8, 0.2),
        (0.2, 0.8),
        (0.8, 0.8),
      ]) {
        canvas.drawCircle(
          Offset(r.left + r.width * dx, r.top + r.height * dy),
          1.6,
          _rivet,
        );
      }
      final y = r.top + r.height * shine;
      canvas.drawLine(
        Offset(r.left + 2, y),
        Offset(r.right - 2, math.max(r.top, y - r.height * 0.3)),
        Paint()
          ..color = const Color(0x88FFFFFF)
          ..strokeWidth = 2,
      );
    }
  }
}
