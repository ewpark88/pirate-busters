import 'dart:math' as math;
import 'dart:ui';

import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/game/coords.dart';
import 'package:pirate_busters/game/view/hull_trim.dart';
import 'package:pirate_busters/game/view/sea_theme.dart';
import 'package:pirate_busters/game/view/ship_view.dart';

/// 물에 잠긴 선체 (설계서 §10.2 “수면 아래 선체는 깊이에 따라 물들고 일렁이는 빛
/// 무늬가 얹히며, 선체와 수면이 만나는 자리에 수면선 띠를 그린다”, A24).
///
/// 배 로컬 좌표(원점 용골 바닥 가운데, 아래가 +)에서 그린다. 수면은 배의 기울기·
/// 격침 깊이·흔들림을 되돌려 구한 직선이라 배가 기울어도 수면과 맞는다. 침수로
/// 흘수가 깊어지면 수면선도 같이 오른다. 그리기만 하고 판정과 무관하다.
abstract final class HullWater {
  /// 배 로컬 x 에서의 수면 y. [w0] 은 기울기가 없을 때 수면 y, [angle] 은 배가 기운
  /// 각(라디안), [sx] 는 좌우 뒤집기(±1).
  static double surfaceAt(
    double lx, {
    required double w0,
    required double angle,
    required double sx,
  }) => (w0 - math.sin(angle) * sx * lx) / math.cos(angle);

  /// 선체 모양: 블록 칸(돛대 칸 제외)과 틀의 비스듬한 판.
  static Path hullPath(
    HullSpec hull,
    List<int> materials,
    int width,
    Rect Function(int x, int y) cellRect,
  ) {
    bool filled(int x, int y) {
      final m = materials[y * width + x];
      return m != ShipGrid.emptyCell && !BlockMaterial.values[m].rig;
    }

    final path = Path();
    for (var i = 0; i < materials.length; i++) {
      if (filled(i % width, i ~/ width)) {
        path.addRect(cellRect(i % width, i ~/ width));
      }
    }
    for (final step in HullTrim.steps(hull, filled)) {
      path.addPath(HullTrim.wedge(step, cellRect), Offset.zero);
    }
    return path;
  }

  /// [ship] 의 잠긴 부분을 그린다. [materials] 는 지금 보이는 격자.
  static void paint(Canvas canvas, ShipView ship, List<int> materials) {
    final state = ship.session.state.sides[ship.side];
    final grid = state.grid;
    final motion = ship.motion;
    final hull = hullPath(grid.hull, materials, grid.width, ship.cellRect);
    final w0 =
        -state.draft * Coords.cell / cellUnit - motion.depth - motion.dip;
    draw(
      canvas,
      hull: hull,
      bounds: hull.getBounds(),
      waterAt: (lx) =>
          surfaceAt(lx, w0: w0, angle: ship.angle, sx: ship.scale.x),
      t: ship.session.turnMs / 1000,
      lowEnd: ship.fewer,
    );
  }

  /// 선체 [hull] 의 수면 아래에 깊이 물빛·빛 무늬를, 수면 자리에 수면선 띠를 그린다.
  /// 저사양([lowEnd])이면 빛 무늬를 끈다. 잠긴 곳이 없으면 아무것도 그리지 않는다.
  static void draw(
    Canvas canvas, {
    required Path hull,
    required Rect bounds,
    required double Function(double lx) waterAt,
    required double t,
    bool lowEnd = false,
    SeaTheme theme = SeaTheme.tropicalDay,
  }) {
    if (bounds.isEmpty) return;
    final l = bounds.left - 4;
    final r = bounds.right + 4;
    final yl = waterAt(l);
    final yr = waterAt(r);
    final bottom = bounds.bottom + 4;
    if (yl >= bottom && yr >= bottom) return;
    final below = Path()
      ..moveTo(l, yl)
      ..lineTo(r, yr)
      ..lineTo(r, bottom)
      ..lineTo(l, bottom)
      ..close();
    canvas
      ..save()
      ..clipPath(below)
      ..clipPath(hull)
      ..drawRect(
        Rect.fromLTRB(l, math.min(yl, yr), r, bottom),
        Paint()
          ..shader = Gradient.linear(
            Offset(0, math.min(yl, yr)),
            Offset(0, bottom),
            [
              theme.sea[0].withValues(alpha: .28),
              theme.sea[1].withValues(alpha: .5),
              theme.sea[2].withValues(alpha: .66),
            ],
            const [0, .4, 1],
          ),
      );
    if (!lowEnd) _caustics(canvas, l, r, waterAt, bottom, t, theme);
    canvas.restore();
    _waterline(canvas, hull, l, r, waterAt, t, theme);
  }

  /// 일렁이는 빛 무늬: 수면 가까이 밝고 깊을수록 옅은 물결 선들.
  static void _caustics(
    Canvas canvas,
    double l,
    double r,
    double Function(double) waterAt,
    double bottom,
    double t,
    SeaTheme theme,
  ) {
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var k = 0; k < 6; k++) {
      final depth = 8.0 + k * 14;
      line.color = theme.foam.withValues(alpha: .16 * (1 - k / 6));
      final p = Path();
      for (var x = l; x <= r; x += 8) {
        final y = waterAt(x) + depth + math.sin(x / 21 + t * 1.8 + k * 1.7) * 3;
        if (x == l) {
          p.moveTo(x, y);
        } else {
          p.lineTo(x, y);
        }
      }
      if (waterAt(l) + depth > bottom) break;
      canvas.drawPath(p, line);
    }
  }

  /// 수면선 띠: 선체에 젖은 어두운 띠와 그 위 밝은 물결 선.
  static void _waterline(
    Canvas canvas,
    Path hull,
    double l,
    double r,
    double Function(double) waterAt,
    double t,
    SeaTheme theme,
  ) {
    final wave = Path();
    for (var x = l; x <= r; x += 6) {
      final y = waterAt(x) + math.sin(x / 14 + t * 3) * 1.2;
      if (x == l) {
        wave.moveTo(x, y);
      } else {
        wave.lineTo(x, y);
      }
    }
    canvas
      ..save()
      ..clipPath(hull)
      ..drawPath(
        wave.shift(const Offset(0, 3)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..color = theme.sea[2].withValues(alpha: .35),
      )
      ..drawPath(
        wave,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..color = theme.foam.withValues(alpha: .85),
      )
      ..restore();
  }
}
