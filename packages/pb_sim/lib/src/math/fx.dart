/// ×1000 고정소수점 수 (개발 계획서 §2.2, 설계서 §7.1).
///
/// `Fx(1500)` 은 1.5 다. 곱셈·나눗셈은 0에서 먼 쪽으로 반올림한다(1.5 → 2,
/// -1.5 → -2). 값이 [Fx.maxRaw] 범위를 벗어나면 [StateError] 를 던진다.
extension type const Fx(int raw) {
  /// 정수 [n] 을 고정소수점으로 (`n × 1000`).
  factory Fx.fromInt(int n) => Fx._checked(n * scale);

  factory Fx._checked(int raw) {
    if (raw > maxRaw || raw < -maxRaw) {
      throw StateError('Fx 범위 초과: $raw');
    }
    return Fx(raw);
  }

  /// 1.0 에 해당하는 raw 값.
  static const int scale = 1000;

  /// 허용하는 raw 절댓값 상한(2^40). 곱셈 중간값이 64비트를 넘지 않게 한다.
  static const int maxRaw = 1 << 40;

  static const Fx zero = Fx(0);
  static const Fx one = Fx(scale);

  Fx operator +(Fx other) => Fx._checked(raw + other.raw);
  Fx operator -(Fx other) => Fx._checked(raw - other.raw);
  Fx operator -() => Fx(-raw);

  /// 고정소수점 곱셈. 결과를 반올림한다.
  Fx operator *(Fx other) =>
      Fx._checked(roundDiv(mulChecked(raw, other.raw), scale));

  /// 고정소수점 나눗셈. 결과를 반올림한다. 0 으로 나누면 [ArgumentError].
  Fx operator ~/(Fx other) {
    if (other.raw == 0) throw ArgumentError('Fx 를 0 으로 나눌 수 없다');
    return Fx._checked(roundDiv(raw * scale, other.raw));
  }

  /// 정수배.
  Fx scaleBy(int n) => Fx._checked(mulChecked(raw, n));

  bool operator <(Fx other) => raw < other.raw;
  bool operator <=(Fx other) => raw <= other.raw;
  bool operator >(Fx other) => raw > other.raw;
  bool operator >=(Fx other) => raw >= other.raw;

  Fx abs() => raw < 0 ? Fx(-raw) : this;

  /// 가장 가까운 정수 (0.5 는 0 에서 먼 쪽).
  int toIntRound() => roundDiv(raw, scale);

  /// 0 쪽으로 버린 정수.
  int toIntTrunc() => raw ~/ scale;
}

/// [n] ÷ [d] 를 0에서 먼 쪽 반올림으로. [d] 는 0 이 아니어야 한다.
int roundDiv(int n, int d) {
  if (d == 0) throw ArgumentError('0 으로 나눌 수 없다');
  final negative = (n < 0) != (d < 0);
  final an = n < 0 ? -n : n;
  final ad = d < 0 ? -d : d;
  final q = (an + (ad >> 1)) ~/ ad;
  return negative ? -q : q;
}

/// 64비트를 넘지 않는 곱셈. 넘을 것 같으면 [StateError].
int mulChecked(int a, int b) {
  const limit = 1 << 62;
  final aa = a < 0 ? -a : a;
  final ab = b < 0 ? -b : b;
  if (aa != 0 && ab > limit ~/ aa) {
    throw StateError('정수 곱셈 오버플로: $a × $b');
  }
  return a * b;
}
