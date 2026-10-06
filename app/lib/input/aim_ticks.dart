/// 당길 때 진동의 종류 (설계서 §10.4 발사, A32).
enum AimTick {
  /// 힘 링 눈금을 하나 넘었다: 가벼운 톡.
  step,

  /// 최대 힘에 닿았다: 딸깍.
  full,
}

/// 당길 때 진동 (설계서 §10.4 발사, A32): 힘이 힘 링 10칸의 눈금을 새로 넘을 때마다
/// 한 번, 최대 힘에 닿으면 딸깍을 낸다. 힘을 줄일 때는 울리지 않는다.
class AimTicks {
  /// 힘 링 칸 수 (설계서 §10.4 조준 표시).
  static const int steps = 10;

  int _last = 0;

  /// 새로 당기기 시작했다.
  void reset() => _last = 0;

  /// 지금 힘 [power] (0~[max]). 울릴 진동이 있으면 돌려준다.
  AimTick? update(int power, int max) {
    final tick = max <= 0 ? 0 : (power * steps ~/ max).clamp(0, steps);
    final last = _last;
    _last = tick;
    if (tick <= last) return null;
    return tick == steps ? AimTick.full : AimTick.step;
  }
}
