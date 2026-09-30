import 'dart:math' as math;

import 'package:flame/components.dart';

/// 카메라 목표 계산 (설계서 §2.1, 렌더 전용). Flame 과 무관한 순수 계산이라 테스트한다.
///
/// 수치는 에셋 tokens.json `camera` 를 따른다: 착탄 뒤 1.3초 머묾, 착탄 화면 폭 700.
/// 기본 화면은 내 배와 앞바다, 조준할수록 줌아웃, 탄을 쏘면 탄과 표적이 한 화면에
/// 들어오게 따라간다. 핀치 줌은 1.5배 확대부터 간격 48칸이 다 보이는 배율까지.
class CameraDirector {
  /// 기본 화면 폭(월드 px, 약 28칸).
  static const double baseWidth = 900;

  /// 가장 멀리 본 화면 폭: 간격 48칸 + 배 두 척 + 여백.
  static const double maxWidth = 2720;
  static const double minWidth = baseWidth / 1.5;
  static const double impactWidth = 700;
  static const double impactHoldSec = 1.3;
  static const double followRate = 4;

  final Vector2 center = Vector2(0, -120);
  double width = baseWidth;

  /// 사람이 핀치로 고른 배율(1 = 기본, 1.5 = 최대 확대).
  double userZoom = 1;

  bool overview = false;

  Vector2? _impact;
  double _impactLeft = 0;

  /// 착탄 지점을 잠깐 보여준다.
  void impact(Vector2 at) {
    _impact = at.clone();
    _impactLeft = impactHoldSec;
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
  }) {
    if (overview) {
      final w = ((myX - enemyX).abs() + 800).clamp(baseWidth, maxWidth);
      return (Vector2((myX + enemyX) / 2, -150), w);
    }
    final impactAt = _impact;
    if (impactAt != null && _impactLeft > 0) {
      final double y = math.min(-60, impactAt.y);
      return (Vector2(impactAt.x, y), impactWidth);
    }
    if (projectile != null) {
      // 탄과 맞을 배(없으면 상대 배)를 한 화면에.
      final aimX = targetX ?? enemyX;
      final w = ((projectile.x - aimX).abs() + 500).clamp(
        baseWidth,
        maxWidth,
      );
      final double y = math.min(-120, projectile.y * 0.6);
      return (Vector2((projectile.x + aimX) / 2, y), w);
    }
    final w = (baseWidth * (1 + 0.6 * aimStretch) / userZoom).clamp(
      minWidth,
      maxWidth,
    );
    final ahead = 260 + 300 * aimStretch;
    return (Vector2(myX + facing * ahead, -120), w);
  }

  /// 목표로 부드럽게 다가간다.
  void update(double dt, (Vector2, double) goal) {
    _impactLeft = math.max(0, _impactLeft - dt);
    if (_impactLeft == 0) _impact = null;
    final k = 1 - math.exp(-followRate * dt);
    center.add((goal.$1 - center) * k);
    width += (goal.$2 - width) * k;
  }
}
