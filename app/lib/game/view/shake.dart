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

/// 쌓이는 흔들림 (설계서 §10.4, A32): 명중마다 충격량(0~1)을 더하고 일정하게 줄인다.
/// 화면 이동은 충격량의 제곱에 비례해, 작은 한 방과 큰 한 방이 확실히 갈린다
/// (Eiserloh, GDC 2016 "Math for Game Programmers: Juicing Your Cameras").
class ScreenTrauma {
  /// 충격량 1 일 때 흔들림(월드 px)과 기울기(rad, 약 1.5°).
  static const double maxPx = 24;
  static const double maxAngle = 0.026;

  /// 1초에 줄어드는 충격량.
  static const double fallPerSec = 1.8;

  /// 설정 '화면 흔들림 줄이기'(§13.8)를 켰을 때 곱하는 비율.
  static const double calmScale = 0.35;

  double value = 0;

  /// 충격량 [amount] 를 더한다(최대 1).
  void add(double amount) => value = math.min(1, value + amount);

  /// 충격량이 적어도 [amount] 가 되게 한다(겹쳐 쌓지 않는 효과).
  void atLeast(double amount) => value = math.max(value, math.min(1, amount));

  void update(double dt) => value = math.max(0, value - fallPerSec * dt);

  /// 지금 흔들림 세기(월드 px). [calm] 이면 줄인다.
  double amp({bool calm = false}) =>
      maxPx * value * value * (calm ? calmScale : 1);

  /// [t] 초의 카메라 기울기(rad). 떨림과 다른 주파수라 위치와 따로 논다.
  double angle(double t, {bool calm = false}) =>
      maxAngle *
      value *
      value *
      (calm ? calmScale : 1) *
      (0.6 * math.sin(t * 37 + 0.4) + 0.4 * math.sin(t * 71 + 1.9));
}
