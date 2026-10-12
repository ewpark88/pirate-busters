import 'dart:math' as math;

import 'package:flame/components.dart';

/// 임계 감쇠 스프링 한 축 (렌더 전용, A60). 목표가 갑자기 바뀌어도 속도를 들고 가서
/// 화면이 휙 꺾이지 않는다. `omega` 가 클수록 빨리 붙는다(1차 추종의 rate 와 같은 눈금).
class CameraSpring {
  double velocity = 0;

  /// [value] 에서 [goal] 쪽으로 [dt] 초만큼 움직인 값. 넘치지 않는다(임계 감쇠).
  double step(double value, double goal, double omega, double dt) {
    if (dt <= 0) return value;
    // 정확한 해: x(t) = goal + (c0 + c1 t) e^{-ωt}.
    final c0 = value - goal;
    final c1 = velocity + omega * c0;
    final e = math.exp(-omega * dt);
    velocity = (c1 - omega * (c0 + c1 * dt)) * e;
    return goal + (c0 + c1 * dt) * e;
  }
}

/// 0~1 을 양 끝이 부드러운 0~1 로 (smoothstep).
double smooth01(double t) {
  final u = t.clamp(0.0, 1.0);
  return u * u * (3 - 2 * u);
}

/// 따라가는 탄의 가로 속도(앞 비우기)와 추적 시간 (A60). 분열처럼 따라가는 탄이
/// 바뀌어 크게 뛰면 속도를 새로 잰다.
class ShotTrack {
  Vector2? shot;
  Vector2? _prev;
  double vx = 0;
  double t = 0;

  void update(double dt) {
    final now = shot;
    final prev = _prev;
    if (now == null) {
      t = 0;
      vx = 0;
      _prev = null;
      return;
    }
    if (prev != null && dt > 0 && (now - prev).length < 200) {
      final k = 1 - math.exp(-10 * dt);
      vx += ((now.x - prev.x) / dt - vx) * k;
    } else if (prev != null) {
      vx = 0;
    }
    t += dt;
    _prev = now;
  }
}

/// 빈 바다를 끌어 옮긴 가로 거리 (설계서 §2.1, A60). 손을 떼고 [returnDelay] 초가
/// 지나면 0 으로 돌아간다(카메라 스프링이 부드럽게 옮긴다).
class CameraPan {
  static const double returnDelay = 2.5;

  double x = 0;
  bool dragging = false;
  double _idle = 0;

  void by(double dx) {
    x += dx;
    dragging = true;
    _idle = 0;
  }

  void reset() {
    x = 0;
    dragging = false;
  }

  void update(double dt) {
    if (dragging || x == 0) return;
    _idle += dt;
    if (_idle >= returnDelay) x = 0;
  }

  /// 기본 화면 가운데 [base] 에 끈 거리를 더한다. 두 배 가운데([lo]~[hi]) 바깥으로는
  /// 끌어 나가지 않는다.
  double apply(double base, double lo, double hi) {
    if (x == 0) return base;
    final px = (base + x)
        .clamp(math.min(base, lo), math.max(base, hi))
        .toDouble();
    x = px - base;
    return px;
  }
}
