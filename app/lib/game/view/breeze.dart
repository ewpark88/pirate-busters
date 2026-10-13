import 'dart:math' as math;

/// 돛·깃발에 닿는 바람 (설계서 §10.2 ‘바람’, A35): 세기 0~1, 배 로컬 기준 바람이
/// 부는 쪽(−1·0·+1), 시각(초).
typedef Breeze = ({double strength, int dir, double t});

/// 무풍.
const Breeze stillAir = (strength: 0, dir: 0, t: 0);

/// 깃발 공통 모양 (설계서 §2.4 “돛과 깃발이 펄럭인다”). 그리기 전용이다.
abstract final class FlagWave {
  /// 깃발이 아래로 처지는 각(라디안): 무풍이면 가장 처지고 세질수록 펴진다.
  static double droop(Breeze b) => (1 - b.strength) * 1.1;

  /// 깃발 끝이 위아래로 흔들리는 비율: 셀수록 빠르고 크다.
  static double flutter(Breeze b) =>
      .14 * b.strength * math.sin(b.t * (5 + 8 * b.strength));
}
