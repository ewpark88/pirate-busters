import 'package:pb_sim/src/math/trig.dart';

/// atan2 입력 절댓값 상한. `값 × 1,000,000` 이 64비트 안에 들어가게 한다.
const int atan2MaxInput = 1 << 40;

/// ⌊√n⌋. [n] 은 0 이상 (뉴턴법, 정수만 쓴다).
int isqrt(int n) {
  if (n < 0) throw ArgumentError.value(n, 'n', '0 이상이어야 한다');
  if (n < 2) return n;
  var x = n;
  var y = (x + 1) >> 1;
  while (y < x) {
    x = y;
    y = (x + n ~/ x) >> 1;
  }
  return x;
}

/// atan2(y, x) 를 밀리도로. 결과는 (-180000, 180000], 원점이면 0.
///
/// 0~90° 에서 `ay·cos θ − ax·sin θ` 가 0 이 되는 θ 를 이분 탐색한다.
int atan2Mdeg(int y, int x) {
  if (x == 0 && y == 0) return 0;
  final ax = x < 0 ? -x : x;
  final ay = y < 0 ? -y : y;
  if (ax > atan2MaxInput || ay > atan2MaxInput) {
    throw ArgumentError('atan2 입력 범위 초과: ($y, $x)');
  }
  // f(θ) = ay·cos θ − ax·sin θ 는 [0°, 90°] 에서 감소한다. f(θ) ≥ 0 인 최대 θ.
  var lo = 0;
  var hi = 90000;
  while (lo < hi) {
    final mid = (lo + hi + 1) >> 1;
    if (ay * cosMicro(mid) - ax * sinMicro(mid) >= 0) {
      lo = mid;
    } else {
      hi = mid - 1;
    }
  }
  // lo 와 lo+1 중 f 의 절댓값이 작은 쪽으로 반올림한다.
  var theta = lo;
  if (lo < 90000) {
    final fLo = ay * cosMicro(lo) - ax * sinMicro(lo);
    final fHi = ax * sinMicro(lo + 1) - ay * cosMicro(lo + 1);
    if (fHi < fLo) theta = lo + 1;
  }
  if (x >= 0) return y >= 0 ? theta : -theta;
  if (y >= 0 || theta == 0) return 180000 - theta;
  return -(180000 - theta);
}
