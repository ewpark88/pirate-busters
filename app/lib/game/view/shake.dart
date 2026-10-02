import 'dart:math' as math;

import 'package:flame/components.dart';

/// 화면 흔들림 (설계서 §10.4 카메라). 좌우로 번갈아 튀지 않게 주파수가 다른 사인파를
/// 섞은 매끄러운 떨림을 쓰고, 세기는 지수로 잦아든다. 시간만으로 정해지므로 같은
/// 시각·세기면 같은 흔들림이다(렌더 전용, 판정과 무관).
abstract final class Shake {
  /// 1초에 남는 비율의 지수. 12px 흔들림이 약 0.45초 만에 잦아든다.
  static const double decayRate = 9;

  /// 이보다 작으면 멈춘다(px).
  static const double rest = 0.2;

  /// [amp] 세기의 흔들림이 [t] 초에 카메라를 옮기는 양(월드 px). 세로는 절반.
  static Vector2 offset(double amp, double t) => Vector2(
    amp * (0.6 * math.sin(t * 47) + 0.4 * math.sin(t * 83 + 1.3)),
    amp * 0.5 * (0.6 * math.sin(t * 59 + 0.7) + 0.4 * math.sin(t * 97 + 2.1)),
  );

  /// [dt] 초 뒤 남은 세기.
  static double decay(double amp, double dt) {
    final next = amp * math.exp(-decayRate * dt);
    return next < rest ? 0 : next;
  }
}
