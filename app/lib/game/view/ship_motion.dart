import 'dart:math' as math;

import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/battle/battle_session.dart';

/// 배의 연출 움직임 (설계서 §10.4): 맞은 쪽으로 흔들렸다 돌아옴, 진 배가 기울며
/// 가라앉는 격침. 그리기만 하고 기울기·침수 판정(§2.5)과는 무관하다.
class ShipMotion {
  double _rockDir = 0;
  double _rockT = 10;

  /// 가라앉기 시작한 뒤 지난 초. 음수면 가라앉지 않는다.
  double sinkT = -1;

  /// 가라앉는 데 걸리는 시간(초), 끝까지 내려가는 깊이(월드 px), 더 기우는 각(라디안).
  static const double sinkDuration = 2.6;
  static const double sinkDepth = 150;
  static const double sinkTilt = 0.42;

  /// 맞은 방향으로 흔든다. [dir] 은 화면에서 밀리는 쪽(+1 오른쪽).
  void rock(int dir) {
    _rockDir = dir.sign.toDouble();
    _rockT = 0;
  }

  /// 격침 연출을 시작한다(한 번만).
  void startSink() {
    if (sinkT < 0) sinkT = 0;
  }

  bool get sinking => sinkT >= 0;

  /// 다 가라앉았다(결과 창을 띄워도 된다).
  bool get settled => !sinking || sinkT >= sinkDuration;

  void update(double dt) {
    _rockT += dt;
    if (sinkT >= 0) sinkT += dt;
  }

  /// 흔들림 각(라디안): 2° 로 밀렸다가 0.6초쯤 출렁이며 잦아든다.
  double get rockAngle =>
      _rockDir * 0.035 * math.exp(-5 * _rockT) * math.cos(_rockT * 14);

  /// 가라앉은 정도 0~1 (처음과 끝이 부드러운 곡선).
  static double sinkProgress(double t) {
    if (t <= 0) return 0;
    final k = (t / sinkDuration).clamp(0.0, 1.0);
    return k * k * (3 - 2 * k);
  }

  /// 지금 내려간 깊이(월드 px, 아래가 +).
  double get depth => sinkDepth * sinkProgress(sinkT);

  /// 지금 더 기운 각(라디안). [lean] 은 기우는 쪽(침수 기울기 부호).
  double extraTilt(double lean) => sinkTilt * sinkProgress(sinkT) * lean;
}

/// 판이 배가 가라앉아 끝났나(격침·침수 격침, 설계서 §2.4).
bool isSinkOutcome(MatchOutcome o) =>
    o == MatchOutcome.sunk || o == MatchOutcome.floodSunk;

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
