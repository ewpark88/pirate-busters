// mozzi lib/domain/sim/launch_controller.dart 에서 가져와 고쳤다 (ADR-004).
// 정확도 게이지는 빼고, 결과를 FIRE 커맨드의 정수 밀리도·힘으로 바꾼다.
import 'dart:math' as math;

import 'package:pb_sim/pb_sim.dart';

/// 당긴 결과: FIRE 커맨드에 그대로 넣는 정수 값.
class AimShot {
  const AimShot({required this.angle, required this.power});

  /// 상대 쪽 수평이 0 인 밀리도. 아래쪽(어뢰)은 360° 에서 뺀 값(0 ~ 359999)이다.
  final int angle;

  /// 0 ~ [maxFirePower].
  final int power;
}

/// 당겨서 쏘기 (설계서 §2.2): 누른 지점에서 끌면, 끈 방향의 반대로 날아간다.
///
/// 좌표는 화면 논리 px (x 오른쪽, y 아래 +). [facing] 은 쏘는 배가 바라보는 방향
/// (+1 오른쪽, −1 왼쪽)이다. 각도는 [minAngle]~[maxAngle] 로 막는다: 보통은
/// 0~85°(뒤로 넘어가면 최대 각, 아래쪽은 수평), 지원 해적은 내 배로 쏘도록 뒤쪽까지,
/// 어뢰(바라)는 아래쪽까지 (설계서 §2.2, §4.8, `aimRangeFor`).
class PullAim {
  PullAim({
    required this.facing,
    this.maxPullPx = 160,
    this.minAngle = 0,
    this.maxAngle = maxAngleMdeg,
  });

  static const int maxAngleMdeg = 85000;

  /// 허용 각도(밀리도, 위가 +). 아래쪽은 음수.
  final int minAngle;
  final int maxAngle;

  /// 이보다 약하게 당기면 놓아도 쏘지 않는다(취소).
  static const int minPower = 1000;

  final int facing;

  /// 이만큼 당기면 최대 힘.
  final double maxPullPx;

  /// 손가락을 떼는 순간의 미끄러짐으로 보는 시간(밀리초). 놓을 때는 이보다 앞선
  /// 마지막 값, 곧 화면에서 보던 조준으로 쏜다.
  static const int releaseSlipMs = 50;

  /// 이보다 짧게 당긴 동안은 각도를 천천히 따라간다(화면 논리 px). 조금만 움직여도
  /// 각도가 크게 튀지 않게 한다 (A33).
  static const double steadyPx = 24;

  /// 짧게 당긴 동안 새 각도 쪽으로 한 번에 옮기는 비율.
  static const double steadyFollow = .35;

  /// 최근 당김 기록 (밀리초, dx, dy, 각도). 시간 순서.
  final List<(int, double, double, int)> _trail = [];

  double _dx = 0;
  double _dy = 0;

  /// 지금 각도(밀리도, 위가 +, 아래쪽은 음수). 처음 당기면 null.
  int? _signed;
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
    _signed = null;
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
    final raw = _rawAngle();
    final prev = _signed;
    _signed = prev == null || len * k >= steadyPx
        ? raw
        : prev + ((raw - prev) * steadyFollow).round();
    if (!isWeak) _armed = true;
    if (ms == null) return;
    _trail.add((ms, _dx, _dy, _signed!));
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
      for (final (t, dx, dy, a) in _trail.reversed) {
        if (t <= ms - releaseSlipMs) {
          _dx = dx;
          _dy = dy;
          _signed = a;
          break;
        }
      }
    }
    final s = shot;
    return s.power < minPower ? null : s;
  }

  void cancel() => _active = false;

  int _angle() {
    final a = _signed ?? _rawAngle();
    return a < 0 ? a + 360000 : a;
  }

  /// 끈 거리로 바로 구한 각도(밀리도, [minAngle]~[maxAngle], 아래쪽은 음수).
  int _rawAngle() {
    // 발사 방향 = 끈 방향의 반대. 화면 y 는 아래가 + 라 위쪽 성분은 +_dy.
    final forward = -_dx * facing;
    final up = _dy;
    if (forward == 0 && up == 0) return 0.clamp(minAngle, maxAngle);
    final rad = math.atan2(up, forward);
    // 뒤로 크게 넘어간 아래쪽(왼쪽 아래)은 위로 넘어간 것으로 본다.
    var mdeg = (rad * 180 / math.pi * 1000).round();
    if (mdeg < -90000) mdeg += 360000;
    return mdeg.clamp(minAngle, maxAngle);
  }
}
