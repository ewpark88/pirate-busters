import 'package:pb_sim/src/math/fx.dart';
import 'package:pb_sim/src/world/world.dart';

/// 선분이 처음 닿은 칸과 그 칸에 들어간 지점.
typedef TraceHit = ({int cx, int cy, int x, int y});

/// 로컬 좌표 선분 (x0, y0) → (x1, y1) 이 지나는 칸을 순서대로 훑어, [solid] 가 참인
/// 첫 칸을 찾는다 (정수 DDA, Amanatides–Woo). 틱 사이 이동 구간 전체를 훑으므로
/// 빠른 탄도 얇은 벽을 건너뛰지 않는다(터널링 방지).
///
/// 모서리를 정확히 지날 때는 x 쪽 칸을 먼저 본다. 좌표 단위는 [cellUnit].
TraceHit? traceCells(
  int x0,
  int y0,
  int x1,
  int y1,
  bool Function(int cx, int cy) solid,
) {
  final dx = x1 - x0;
  final dy = y1 - y0;
  final adx = dx.abs();
  final ady = dy.abs();
  final stepX = dx.sign;
  final stepY = dy.sign;
  var cx = floorDiv(x0, cellUnit);
  var cy = floorDiv(y0, cellUnit);
  if (solid(cx, cy)) return (cx: cx, cy: cy, x: x0, y: y0);

  // 다음 경계까지의 축 거리. 경계를 넘을 때마다 한 칸(cellUnit)씩 늘어난다.
  var distX = stepX > 0 ? (cx + 1) * cellUnit - x0 : x0 - cx * cellUnit;
  var distY = stepY > 0 ? (cy + 1) * cellUnit - y0 : y0 - cy * cellUnit;
  while (true) {
    // t = dist / |d|. 분수 비교는 교차 곱으로 한다. d = 0 인 축은 무한대.
    final xInRange = adx > 0 && distX <= adx;
    final yInRange = ady > 0 && distY <= ady;
    if (!xInRange && !yInRange) return null;
    final bool takeX;
    if (!yInRange) {
      takeX = true;
    } else if (!xInRange) {
      takeX = false;
    } else {
      takeX = distX * ady <= distY * adx;
    }
    final int tNum;
    final int tDen;
    if (takeX) {
      cx += stepX;
      tNum = distX;
      tDen = adx;
      distX += cellUnit;
    } else {
      cy += stepY;
      tNum = distY;
      tDen = ady;
      distY += cellUnit;
    }
    if (solid(cx, cy)) {
      return (
        cx: cx,
        cy: cy,
        x: x0 + roundDiv(dx * tNum, tDen),
        y: y0 + roundDiv(dy * tNum, tDen),
      );
    }
  }
}
