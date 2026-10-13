import 'dart:math' as math;

import 'package:pirate_busters/battle/battle_session.dart';

/// 배의 연출 움직임 (설계서 §10.4): 맞은 쪽으로 흔들렸다 돌아옴, 쏠 때 반동.
/// 그리기만 하고 판정과는 무관하다.
class ShipMotion {
  double _rockDir = 0;
  double _rockT = 10;
  double _kickDir = 0;
  double _kickT = 10;

  /// 맞았을 때 기우는 최대 각(라디안)과 내려앉는 깊이(월드 px) (A20 에서 키움).
  static const double rockAmp = 0.06;
  static const double rockDip = 5;

  /// 쏠 때 밀리는 거리(월드 px)와 뒤로 젖는 각(라디안).
  static const double recoilPx = 7;
  static const double recoilTilt = 0.02;

  /// 맞은 방향으로 흔든다. [dir] 은 화면에서 밀리는 쪽(+1 오른쪽).
  void rock(int dir) {
    _rockDir = dir.sign.toDouble();
    _rockT = 0;
  }

  /// 쏠 때 반동: [dir] 쪽(+1 오른쪽)으로 살짝 밀렸다가 돌아온다 (설계서 §10.4, A20).
  void recoil(int dir) {
    _kickDir = dir.sign.toDouble();
    _kickT = 0;
  }

  /// 반동으로 밀린 거리(월드 px).
  double get recoilX => _kickDir * recoilPx * math.exp(-9 * _kickT);

  /// 반동으로 젖은 각(라디안). 미는 쪽으로 살짝 기운다.
  double get recoilAngle => _kickDir * recoilTilt * math.exp(-8 * _kickT);

  /// 맞고 살짝 가라앉았다 떠오르는 깊이(월드 px, + 아래).
  double get dip => _rockDir == 0
      ? 0
      : rockDip * math.exp(-6 * _rockT) * math.sin(_rockT * 9).abs();

  void update(double dt) {
    _rockT += dt;
    _kickT += dt;
  }

  /// 흔들림 각(라디안): 약 3.4° 로 밀렸다가 0.6초쯤 출렁이며 잦아든다.
  double get rockAngle =>
      _rockDir * rockAmp * math.exp(-5 * _rockT) * math.cos(_rockT * 14);
}

/// 조준 자세: 사람은 당긴 만큼, 상대는 쏘기 직전에 몸을 젖힌다 (설계서 §2.3).
double leanOf(BattleSession session, int side, int slot) {
  final aim = session.aim;
  if (aim != null && aim.slot == slot && session.state.activeSide == side) {
    return 14 * aim.stretch;
  }
  final foe = session.opponentAim;
  if (foe != null && foe.slot == slot && session.state.activeSide == side) {
    return 14 * foe.progress;
  }
  return 0;
}
