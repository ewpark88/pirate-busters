// mozzi lib/core/random/seeded_rng.dart — double 함수를 빼고 정수 범위 함수만 남겼다 (ADR-004).

/// 매치 시드 기반 결정론 난수 생성기 (xorshift32, 설계서 §7.1).
///
/// 같은 시드면 어느 기기에서나 같은 수열을 낸다. 시뮬레이션의 모든 난수는
/// 이 클래스만 쓴다.
class XorShift32 {
  /// [seed] 가 0 이면 xorshift 가 멈추므로 고정 상수로 대체한다.
  XorShift32(int seed) : _state = _normalize(seed);

  /// 저장해 둔 [state] 에서 이어서 만든다(스냅샷 복원).
  XorShift32.fromState(int state) : _state = _normalize(state);

  static const int _mask32 = 0xFFFFFFFF;
  static const int _zeroSeedReplacement = 0x9E3779B9;

  int _state;

  /// 현재 내부 상태(상태 해시·스냅샷용).
  int get state => _state;

  static int _normalize(int seed) {
    final s = seed & _mask32;
    return s == 0 ? _zeroSeedReplacement : s;
  }

  /// 다음 32비트 부호 없는 정수 (0 ~ 2^32-1).
  int nextUint32() {
    var x = _state;
    x ^= (x << 13) & _mask32;
    x ^= x >> 17;
    x ^= (x << 5) & _mask32;
    _state = x;
    return x;
  }

  /// [0, max) 범위 정수. [max] 는 1 이상 2^31 이하.
  int nextInt(int max) {
    if (max <= 0 || max > 0x80000000) {
      throw ArgumentError.value(max, 'max', '1 이상 2^31 이하여야 한다');
    }
    return (nextUint32() * max) >> 32;
  }

  /// [min, max) 범위 정수.
  int nextRange(int min, int max) => min + nextInt(max - min);

  /// [numerator]/[denominator] 확률로 true.
  bool nextChance(int numerator, int denominator) =>
      nextInt(denominator) < numerator;
}
