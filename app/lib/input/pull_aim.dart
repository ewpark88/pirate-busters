// mozzi lib/domain/sim/launch_controller.dart 에서 가져와 고쳤다 (ADR-004).
// 정확도 게이지는 빼고, 결과를 FIRE 커맨드의 정수 밀리도·힘으로 바꾼다.
import 'dart:math' as math;

import 'package:pb_sim/pb_sim.dart';

/// 당긴 결과: FIRE 커맨드에 그대로 넣는 정수 값.
class AimShot {
  const AimShot({required this.angle, required this.power});

  /// 상대 쪽 수평이 0 인 밀리도 (0 ~ [PullAim.maxAngleMdeg]).
  final int angle;

  /// 0 ~ [maxFirePower].
  final int power;
}

/// 당겨서 쏘기 (설계서 §2.2): 누른 지점에서 끌면, 끈 방향의 반대로 날아간다.
///
/// 좌표는 화면 논리 px (x 오른쪽, y 아래 +). [facing] 은 쏘는 배가 바라보는 방향
/// (+1 오른쪽, −1 왼쪽)이다. 뒤로 넘어가는 각도는 최대 각, 아래쪽은 수평으로 막는다.
class PullAim {
  PullAim({required this.facing, this.maxPullPx = 160});

  static const int maxAngleMdeg = 85000;

  /// 이보다 약하게 당기면 놓아도 쏘지 않는다(취소).
  static const int minPower = 1000;

  final int facing;

  /// 이만큼 당기면 최대 힘.
  final double maxPullPx;

  double _dx = 0;
  double _dy = 0;
  bool _active = false;

  bool get isActive => _active;

  void start() {
    _active = true;
    _dx = 0;
    _dy = 0;
  }

  /// 누른 지점 기준 끈 거리 ([dx], [dy]).
  void drag(double dx, double dy) {
    if (!_active) return;
    final len = math.sqrt(dx * dx + dy * dy);
    final k = len > maxPullPx ? maxPullPx / len : 1.0;
    _dx = dx * k;
    _dy = dy * k;
  }

  /// 지금 당긴 상태의 발사 값.
  AimShot get shot {
    final len = math.sqrt(_dx * _dx + _dy * _dy);
    final power = (len / maxPullPx * maxFirePower).round();
    return AimShot(angle: _angle(), power: power.clamp(0, maxFirePower));
  }

  /// 0~1 당긴 정도 (자동 줌아웃·연출용).
  double get stretch =>
      (math.sqrt(_dx * _dx + _dy * _dy) / maxPullPx).clamp(0, 1).toDouble();

  /// 놓기. 너무 약하면 null(취소).
  AimShot? release() {
    if (!_active) return null;
    _active = false;
    final s = shot;
    return s.power < minPower ? null : s;
  }

  void cancel() => _active = false;

  int _angle() {
    // 발사 방향 = 끈 방향의 반대. 화면 y 는 아래가 + 라 위쪽 성분은 +_dy.
    final forward = -_dx * facing;
    final up = _dy;
    if (forward == 0 && up == 0) return 0;
    final rad = math.atan2(up, forward);
    if (rad < 0) return 0;
    final mdeg = (rad * 180 / math.pi * 1000).round();
    return mdeg > maxAngleMdeg ? maxAngleMdeg : mdeg;
  }
}
