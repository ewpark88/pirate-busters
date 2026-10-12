import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:pb_sim/pb_sim.dart' show MatchState;
import 'package:pirate_busters/game/camera_motion.dart';
import 'package:pirate_busters/game/coords.dart';

/// 카메라 목표 계산 (설계서 §2.1, 렌더 전용). Flame 과 무관한 순수 계산이라 테스트한다.
///
/// 착탄 화면 폭 700 은 에셋 tokens.json `camera` 값이고, 머묾(0.8초)·탄 추적 폭(760)은
/// 손맛 조정으로 에셋 값과 다르다 (A14·A40). 움직임은 임계 감쇠 스프링이다 (A60).
/// 기본 화면은 내 배와 앞바다, 조준할수록 줌아웃. 탄을 쏘면 탄을 화면 가운데 가까이
/// 두고 거의 같은 줌으로 따라간다(높이 올라가면 해수면이 보일 만큼만 넓힌다). 탄이 목표
/// 배에 가까워지면 목표 배가 들어오고, 착탄·파괴 연출이 끝날 때까지 착탄 지점에 머문 뒤
/// 천천히 돌아간다. 상대 턴에는 상대 배와 그 앞바다를 같은 방식으로 보여 준다
/// ([anchorSide], 설계서 §2.1·§10.4, ADR-043·ADR-069). 핀치 줌은 1.5배 확대부터
/// 간격 42칸까지.
class CameraDirector {
  /// 기본 화면이 기준으로 삼는 배: 지금 턴 진영. 판이 끝나면 보는 사람 쪽 [viewSide].
  static int anchorSide(MatchState state, int viewSide) =>
      state.isOver ? viewSide : state.activeSide;

  /// 기본 화면 폭(월드 px, 약 24칸). 전장이 넓어 보여 900(28칸)에서 줄였다 (ADR-072).
  static const double baseWidth = 760;

  /// 기본 화면에서 내 배 가운데부터 화면 가운데까지(월드 px): 기준 배 브리건틴(14칸)
  /// 전체가 들어오고 남는 폭을 앞바다로 쓴다 (ADR-072).
  static const double idleAhead = baseWidth / 2 - 7 * Coords.cell - 16;

  /// 기본 화면 가운데 높이(월드 px): 돛대 끝이 폭 900 때와 같은 높이까지 보인다 (ADR-072).
  static const double idleY = -150;

  /// 내 배 위 끝(월드 px, 위가 −). 있으면 작은 배는 기본 화면에서 더 위로 올려
  /// 아래쪽 이동 패널·카드에 선실이 가리지 않게 한다. 큰 배는 [idleY] 그대로 돛대
  /// 끝을 보인다 (설계서 §2.1, A42).
  double? shipTop;

  /// 작은 배일 때 수면이 오는 화면 높이(위에서 비율)와 배 위 여백(월드 px).
  static const double idleWaterline = 0.7;
  static const double idleTopMargin = 40;

  /// 화면 폭 [w]·세로 비율 [aspect] 에서 기본 화면 가운데 높이.
  double idleYFor(double w, double aspect) {
    final top = shipTop;
    if (top == null) return idleY;
    final halfH = w * aspect / 2;
    final low = (0.5 - idleWaterline) * 2 * halfH;
    final fit = top - idleTopMargin + halfH;
    return math.max(idleY, math.min(low, fit));
  }

  /// 가장 멀리 본 화면 폭: 간격 42칸 + 배 두 척 + 여백 (ADR-048).
  static const double maxWidth = 2528;
  static const double minWidth = baseWidth / 1.5;
  static const double impactWidth = 700;
  static const double impactHoldSec = 0.8;

  /// 착탄에 머물 때 착탄 지점을 화면 가운데보다 위로 올리는 비율(반 높이 기준).
  static const double impactLift = 0.2;
  static const double followRate = 4;

  /// 탄을 따라갈 때는 더 빨리 붙는다(탄이 화면 밖으로 나가지 않게). 쏜 뒤
  /// [shotRampSec] 초 동안 [followRate] 에서 이 값까지 부드럽게 올린다 (A60).
  static const double shotFollowRate = 12;
  static const double shotRampSec = 0.35;

  /// 탄 추적 중 세로는 가로보다 느슨하게 따라가 화면이 탄과 함께 출렁이지 않는다.
  static const double shotYLoose = 0.5;

  /// 탄이 나아가는 쪽으로 앞을 비워 두는 시간(초)과 그 상한(화면 폭 비율) (A60).
  static const double shotLeadSec = 0.3;
  static const double shotLeadMax = 0.12;

  /// rate 를 스프링 세기로 바꾸는 배율: 1차 추종과 비슷한 시간에 도착한다.
  static const double springBoost = 1.5;

  /// 탄을 따라가는 화면 폭(월드 px). 기본 화면과 같은 줌이다.
  static const double shotWidth = baseWidth;

  /// 탄이 목표 배에서 이 거리(월드 px) 안으로 들어오면 목표 배가 화면에 들어오기 시작한다.
  static const double approachDist = 900;

  /// 착탄 지점에서 머문 뒤 돌아갈 때 쓰는 느린 추종(휙 넘어가지 않게, 설계서 §10.4)과 그 시간.
  static const double returnRate = 1.8;
  static const double returnSec = 1.2;
  double _returnLeft = 0;
  bool _holding = false;

  /// 탄 위·아래 여백(월드 px). 아래는 해수면·배까지 보이게.
  static const double shotMarginTop = 90;
  static const double shotMarginBottom = 110;

  double _rate = followRate;
  double _rateY = followRate;
  final CameraSpring _sx = CameraSpring();
  final CameraSpring _sy = CameraSpring();
  final CameraSpring _sw = CameraSpring();

  final ShotTrack _track = ShotTrack();

  /// 빈 바다 끌기(설계서 §2.1, A60). 기본 화면에서만 쓰고, 끄는 동안은 [panRate].
  final CameraPan pan = CameraPan();
  static const double panRate = 25;
  int? _anchor;

  final Vector2 center = Vector2(0, idleY);
  double width = baseWidth;

  /// 사람이 핀치로 고른 배율(1 = 기본, 1.5 = 최대 확대).
  double userZoom = 1;

  bool overview = false;

  /// 고른 해적의 발 위치(월드 px). 있으면 그 해적으로 다가가 줌인한다
  /// (설계서 §2.2, ADR-033). 에셋 tokens.json `camera.aimZoom*` 값.
  Vector2? focusFeet;
  static const double focusWidth = 440;
  static final Vector2 focusOffset = Vector2(50, -10);

  /// 고른 해적을 끝까지 당겼을 때 화면 폭 증가 비율. 해적 자리를 고정한 채 앞을
  /// 예전(폭 +80%, 가운데 +200px)과 비슷하게 보이도록 넓힌다 (A33).
  static const double aimFocusZoom = 1.1;

  Vector2? _impact;
  double _impactLeft = 0;

  /// 맞은 배의 가운데 x 와 폭. 착탄에 머무는 동안 배 전체를 담는다 (A33).
  (double, double)? _impactShip;

  /// 착탄 화면에서 배 양옆에 남길 여백(월드 px).
  static const double impactShipMargin = 90;

  /// 명중 때 당기는 줌 (설계서 §10.4, A32): 화면 폭을 한 방 크기에 비례하는 비율
  /// (4~12%, `HitWeight.punch`)만큼 [punchIn] 초에 빠르게 좁혔다가 [punchOut] 초에
  /// 걸쳐 부드럽게 푼다.
  static const double punchIn = 0.05;
  static const double punchOut = 0.3;
  double _punchZoom = 0;
  double _punchT = punchIn + punchOut;

  /// 지금 화면 폭에 곱할 배율(1 이하).
  double get punchScale {
    if (_punchT >= punchIn + punchOut) return 1;
    final k = _punchT < punchIn
        ? _punchT / punchIn
        : math.pow(1 - (_punchT - punchIn) / punchOut, 2).toDouble();
    return 1 - _punchZoom * k;
  }

  /// 착탄 지점을 잠깐 보여준다. [punch] 가 0 보다 크면 그 비율로 당기는 줌도 건다.
  /// 이미 당긴 줌보다 약하면 덮어쓰지 않는다.
  void impact(Vector2 at, {double punch = 0, (double, double)? ship}) {
    _impact = at.clone();
    _impactShip = ship;
    _impactLeft = impactHoldSec;
    if (punch > 0 && punch >= 1 - punchScale) {
      _punchZoom = punch;
      _punchT = 0;
    }
  }

  /// 핀치 배율을 범위 안으로 맞춘다.
  void setUserZoom(double z) {
    userZoom = z.clamp(baseWidth / maxWidth, baseWidth / minWidth);
  }

  /// [myX]·[enemyX] 는 두 배 가운데(월드 px), [facing] 은 내 배가 보는 방향.
  (Vector2, double) target({
    required double myX,
    required double enemyX,
    required int facing,
    Vector2? projectile,
    double? targetX,
    double aimStretch = 0,
    bool holdImpact = false,
    double aspect = 0.46,
    int anchor = 0,
  }) {
    final impactAt = _impact;
    // 착탄 뒤 0.8초, 또는 부서지는 연출이 끝날 때까지 착탄 지점에 머문다.
    final holding = impactAt != null && (_impactLeft > 0 || holdImpact);
    if (_holding && !holding) _returnLeft = returnSec;
    _holding = holding;
    _track.shot = projectile?.clone();
    // 턴이 바뀌거나, 해적을 고르거나, 탄·착탄·전체 보기가 시작되면 끌기를 푼다.
    if ((_anchor != null && anchor != _anchor) || !canPan) pan.reset();
    _anchor = anchor;
    final ramp = smooth01(_track.t / shotRampSec);
    _rate = projectile != null
        ? followRate + (shotFollowRate - followRate) * ramp
        : _returnLeft > 0
        ? returnRate
        : pan.dragging
        ? panRate
        : followRate;
    _rateY = projectile != null ? _rate * shotYLoose : _rate;
    if (overview) {
      final w = ((myX - enemyX).abs() + 800).clamp(baseWidth, maxWidth);
      return (Vector2((myX + enemyX) / 2, -150), w);
    }
    if (holding) {
      final ship = _impactShip;
      var w = impactWidth;
      var x = impactAt.x;
      if (ship != null) {
        // 맞은 배가 화면 끝에 잘리지 않게: 배 전체 + 여백이 들어오는 폭으로 넓히고,
        // 가운데는 착탄 지점에서 배가 다 보이는 범위로만 옮긴다.
        final (sx, sw) = ship;
        w = math.max(impactWidth, sw + 2 * impactShipMargin);
        final reach = (w - sw) / 2 - impactShipMargin;
        x = impactAt.x.clamp(sx - reach, sx + reach);
      }
      // 착탄 지점이 화면 위에서 40% 쯤에 오게 가운데를 아래로 둔다: 아래쪽 해적 카드에
      // 가리지 않고, 위쪽 정보는 연출 중 흐려진다 (설계서 §10.4·§13.4, A40).
      return (Vector2(x, impactAt.y + w * aspect / 2 * impactLift), w);
    }
    if (projectile != null) {
      // 탄을 가운데에 두고 같은 줌으로 따라간다. 맞을 배(없으면 상대 배)에 가까워지면
      // 그 배가 들어오도록 가운데를 옮기고 넓힌다.
      final aimX = targetX ?? enemyX;
      final dist = (projectile.x - aimX).abs();
      final near = smooth01(1 - dist / approachDist);
      // 세로: 탄 위 여백부터 해수면 아래 여백까지가 화면 높이 안에 든다.
      final top = math.min(projectile.y, -60) - shotMarginTop;
      const bottom = shotMarginBottom;
      final follow = math.max(shotWidth, (bottom - top) / aspect);
      final both = math.max(follow, dist + 500);
      final w = (follow + (both - follow) * near).clamp(minWidth, maxWidth);
      final halfH = w * aspect / 2;
      final double y = math.min(
        math.max((top + bottom) / 2, top + halfH),
        bottom - halfH,
      );
      final lead = (_track.vx * shotLeadSec).clamp(
        -shotLeadMax * w,
        shotLeadMax * w,
      );
      final x =
          projectile.x +
          lead * ramp * (1 - near) +
          ((projectile.x + aimX) / 2 - projectile.x) * near;
      return (Vector2(x, y), w);
    }
    final feet = focusFeet;
    if (feet != null) {
      // 당기는 만큼 줌아웃해 앞(상대 쪽)을 더 보여준다. 해적 발을 기준점으로 늘려
      // 해적이 화면에서 같은 자리에 머문다: 당기는 손가락 밑에서 미끄러지지 않는다 (A33).
      final k = 1 + aimFocusZoom * aimStretch;
      return (
        Vector2(
          feet.x + facing * focusOffset.x * k,
          feet.y + focusOffset.y * k,
        ),
        focusWidth * k,
      );
    }
    final w = (baseWidth * (1 + 0.6 * aimStretch) / userZoom).clamp(
      minWidth,
      maxWidth,
    );
    final ahead = idleAhead + 300 * aimStretch;
    // 줌아웃할수록 두 배 가운데로 옮겨, 최대 축소에서는 간격 42칸이어도 두 배가
    // 모두 보인다 (설계서 §2.1).
    final t = ((w - baseWidth) / (maxWidth - baseWidth)).clamp(0.0, 1.0);
    final near = myX + facing * ahead;
    final mid = (myX + enemyX) / 2;
    final x = pan.apply(
      near + (mid - near) * t,
      math.min(myX, enemyX),
      math.max(myX, enemyX),
    );
    return (Vector2(x, idleYFor(w, aspect)), w);
  }

  /// 지금 끌어서 화면을 옮길 수 있는가: 기본 화면일 때만.
  bool get canPan =>
      !overview && focusFeet == null && _track.shot == null && !_holding;

  /// 빈 바다를 끈 만큼(월드 px) 화면을 옮긴다. 손을 떼면 `pan.dragging = false`.
  void panBy(double dx) {
    if (canPan) pan.by(dx);
  }

  /// 목표로 부드럽게 다가간다.
  void update(double dt, (Vector2, double) goal) {
    // 착탄 지점은 다음 착탄까지 남겨 둔다: 부서지는 연출이 길면 계속 머문다.
    _impactLeft = math.max(0, _impactLeft - dt);
    _returnLeft = math.max(0, _returnLeft - dt);
    _punchT += dt;
    _track.update(dt);
    pan.update(dt);
    final k = _rate * springBoost;
    center.setValues(
      _sx.step(center.x, goal.$1.x, k, dt),
      _sy.step(center.y, goal.$1.y, _rateY * springBoost, dt),
    );
    width = _sw.step(width, goal.$2, k, dt);
  }
}
