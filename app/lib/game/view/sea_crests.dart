import 'dart:math' as math;

import 'package:pirate_busters/game/view/sea_shape.dart';

/// 파도 구간과 바람이 바다 모양에 주는 값 (설계서 §2.4·§2.6·§10.2). `SeaView` 가 쓰는
/// 순수 계산이라 테스트한다. 그리기 전용이라 판정과 무관하다.
abstract final class SeaCrests {
  /// 바람 [wind](−3~+3) 에 포말이 흐르는 빠르기(월드 px/초, 오른쪽 +).
  static double foamDrift(double wind) => wind * 9;

  /// 구간 세기 [level] 에서 포말이 생길 비율(거침 = 1, 잔잔은 아주 조금).
  static double foamWeight(double level) => (0.12 + level) / 3.12;

  /// 구간 세기 [level] 의 잔물결 배율: 잔잔하면 거의 평평하다.
  static double rippleFor(double level) =>
      0.3 + 0.7 * math.min(level, 1) + 0.25 * math.max(level - 1, 0);

  /// 세기 [level] 구간의 [x] 꼭대기에 물마루가 서는가: 잔잔하면 없고, 보통은 둘에
  /// 하나, 거칠면 모든 꼭대기.
  static bool shown(double level, double x) {
    if (level < .3) return false;
    if (level >= 2) return true;
    return (x / SeaShape.length).round().isEven;
  }

  /// 물마루 점들(꼭대기에서 x 거리, 수면 위 높이, 반지름). 바람 [lean](−1~1) 쪽은
  /// 더 길게 이어지고 끝이 살짝 말려 오르며, 반대쪽은 촘촘하다. 무풍이면 대칭이다.
  static List<(double, double, double)> dots(double lean) {
    final dir = lean < 0 ? -1.0 : 1.0;
    final k = lean.abs().clamp(0.0, 1.0);
    final extra = (k * 2).round();
    return [
      for (var d = -3; d <= 3 + extra; d++)
        (
          dir * d * 9 * (d > 0 ? 1 + .35 * k : 1 - .2 * k),
          d > 0 ? d * d * .35 * k : 0,
          (2.6 - d.abs() * .4).clamp(.8, 2.6),
        ),
    ];
  }
}
