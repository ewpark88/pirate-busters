import 'dart:math' as math;

import 'package:flame/components.dart';

/// 카메라 목표 계산 (설계서 §2.1, 렌더 전용). Flame 과 무관한 순수 계산이라 테스트한다.
///
/// 수치는 에셋 tokens.json `camera` 를 따른다: 착탄 뒤 1.3초 머묾, 착탄 화면 폭 700.
/// 기본 화면은 내 배와 앞바다, 조준할수록 줌아웃. 탄을 쏘면 발사부터 착탄·파괴 연출이
/// 끝날 때까지 탄을 따라가고 탄이 화면 밖으로 나가지 않는다(높이 올라가면 넓게 본다).
/// 상대 턴도 같다 (설계서 §2.1, ADR-043). 핀치 줌은 1.5배 확대부터 간격 42칸까지.
class CameraDirector {
  /// 기본 화면 폭(월드 px, 약 28칸).
  static const double baseWidth = 900;

  /// 가장 멀리 본 화면 폭: 간격 42칸 + 배 두 척 + 여백 (ADR-048).
  static const double maxWidth = 2528;
  static const double minWidth = baseWidth / 1.5;
  static const double impactWidth = 700;
  static const double impactHoldSec = 1.3;
  static const double followRate = 4;

  /// 탄을 따라갈 때는 더 빨리 붙는다(탄이 화면 밖으로 나가지 않게).
  static const double shotFollowRate = 12;

  /// 탄 위·아래 여백(월드 px). 아래는 해수면·배까지 보이게.
  static const double shotMarginTop = 90;
  static const double shotMarginBottom = 110;

  double _rate = followRate;

  final Vector2 center = Vector2(0, -120);
  double width = baseWidth;

  /// 사람이 핀치로 고른 배율(1 = 기본, 1.5 = 최대 확대).
  double userZoom = 1;

  bool overview = false;

  /// 고른 해적의 발 위치(월드 px). 있으면 그 해적으로 다가가 줌인한다
  /// (설계서 §2.2, ADR-033). 에셋 tokens.json `camera.aimZoom*` 값.
  Vector2? focusFeet;
  static const double focusWidth = 440;
  static final Vector2 focusOffset = Vector2(50, -10);

  Vector2? _impact;
  double _impactLeft = 0;

  /// 명중 때 살짝 당기는 줌 (설계서 §10.4): 화면 폭을 이 비율만큼 좁혔다가 푼다.
  static const double punchZoom = 0.06;
  static const double punchSec = 0.25;
  double _punch = 0;

  /// 지금 화면 폭에 곱할 배율(1 이하). 명중 직후 가장 작고 [punchSec] 뒤 1 로 돌아온다.
  double get punchScale => 1 - punchZoom * _punch;

  /// 착탄 지점을 잠깐 보여준다. [punch] 면 살짝 당기는 줌도 건다.
  void impact(Vector2 at, {bool punch = false}) {
    _impact = at.clone();
    _impactLeft = impactHoldSec;
    if (punch) _punch = 1;
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
  }) {
    _rate = projectile != null ? shotFollowRate : followRate;
    if (overview) {
      final w = ((myX - enemyX).abs() + 800).clamp(baseWidth, maxWidth);
      return (Vector2((myX + enemyX) / 2, -150), w);
    }
    final impactAt = _impact;
    // 착탄 뒤 1.3초, 또는 부서지는 연출이 끝날 때까지 착탄 지점에 머문다.
    if (impactAt != null && (_impactLeft > 0 || holdImpact)) {
      final double y = math.min(-60, impactAt.y);
      return (Vector2(impactAt.x, y), impactWidth);
    }
    if (projectile != null) {
      // 탄과 맞을 배(없으면 상대 배)를 한 화면에.
      final aimX = targetX ?? enemyX;
      // 세로: 탄 위 여백부터 해수면 아래 여백까지가 화면 높이 안에 든다.
      final top = math.min(projectile.y, -60) - shotMarginTop;
      const bottom = shotMarginBottom;
      final byHeight = (bottom - top) / aspect;
      final w = math
          .max((projectile.x - aimX).abs() + 500, byHeight)
          .clamp(
            baseWidth,
            maxWidth,
          );
      final halfH = w * aspect / 2;
      final double y = math.min(
        math.max((top + bottom) / 2, top + halfH),
        bottom - halfH,
      );
      return (Vector2((projectile.x + aimX) / 2, y), w);
    }
    final feet = focusFeet;
    if (feet != null) {
      // 당기는 만큼 이 폭에서 줌아웃하고 앞(상대 쪽)을 더 보여준다.
      final fw = focusWidth * (1 + 0.8 * aimStretch);
      return (
        Vector2(
          feet.x + facing * (focusOffset.x + 200 * aimStretch),
          feet.y + focusOffset.y,
        ),
        fw,
      );
    }
    final w = (baseWidth * (1 + 0.6 * aimStretch) / userZoom).clamp(
      minWidth,
      maxWidth,
    );
    final ahead = 260 + 300 * aimStretch;
    // 줌아웃할수록 두 배 가운데로 옮겨, 최대 축소에서는 간격 42칸이어도 두 배가
    // 모두 보인다 (설계서 §2.1).
    final t = ((w - baseWidth) / (maxWidth - baseWidth)).clamp(0.0, 1.0);
    final near = myX + facing * ahead;
    final mid = (myX + enemyX) / 2;
    return (Vector2(near + (mid - near) * t, -120), w);
  }

  /// 목표로 부드럽게 다가간다.
  void update(double dt, (Vector2, double) goal) {
    // 착탄 지점은 다음 착탄까지 남겨 둔다: 부서지는 연출이 길면 계속 머문다.
    _impactLeft = math.max(0, _impactLeft - dt);
    _punch = math.max(0, _punch - dt / punchSec);
    final k = 1 - math.exp(-_rate * dt);
    center.add((goal.$1 - center) * k);
    width += (goal.$2 - width) * k;
  }
}
