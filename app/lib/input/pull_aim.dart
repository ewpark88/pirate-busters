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

  /// 손가락을 떼는 순간의 미끄러짐으로 보는 시간(밀리초). 놓을 때는 이보다 앞선
  /// 마지막 값, 곧 화면에서 보던 조준으로 쏜다.
  static const int releaseSlipMs = 50;

  /// 최근 당김 기록 (밀리초, dx, dy). 시간 순서.
  final List<(int, double, double)> _trail = [];

  double _dx = 0;
  double _dy = 0;
  bool _active = false;

  /// 한 번이라도 [minPower] 이상 당겼다.
  bool _armed = false;

  bool get isActive => _active;

  /// 지금 놓으면 쏘지 않는다(힘이 [minPower] 미만).
  bool get isWeak => shot.power < minPower;

  /// 충분히 당겼다가 누른 자리 가까이 되돌렸다: 놓으면 취소된다.
  bool get isCancelling => _armed && isWeak;

  void start() {
    _active = true;
    _armed = false;
    _dx = 0;
    _dy = 0;
    _trail.clear();
  }

  /// 누른 지점 기준 끈 거리 ([dx], [dy]). [ms] 는 입력 시각(놓을 때 미끄러짐을
  /// 걸러 내는 데 쓴다).
  void drag(double dx, double dy, {int? ms}) {
    if (!_active) return;
    final len = math.sqrt(dx * dx + dy * dy);
    final k = len > maxPullPx ? maxPullPx / len : 1.0;
    _dx = dx * k;
    _dy = dy * k;
    if (!isWeak) _armed = true;
    if (ms == null) return;
    _trail.add((ms, _dx, _dy));
    // 놓을 때 되돌아볼 만큼만 남긴다.
    while (_trail.length > 2 && _trail[1].$1 <= ms - releaseSlipMs) {
      _trail.removeAt(0);
    }
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

  /// 놓기. 너무 약하면 null(취소). [ms] 를 주면 놓기 직전 [releaseSlipMs] 안의
  /// 움직임(손가락이 떨어지며 미끄러진 것)은 빼고 그 앞의 마지막 값으로 쏜다.
  AimShot? release({int? ms}) {
    if (!_active) return null;
    _active = false;
    if (ms != null) {
      for (final (t, dx, dy) in _trail.reversed) {
        if (t <= ms - releaseSlipMs) {
          _dx = dx;
          _dy = dy;
          break;
        }
      }
    }
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
