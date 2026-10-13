import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:pirate_busters/battle/battle_session.dart';

/// 전장이 느끼는 바람 (설계서 §2.4·§10.2): 지금 턴 바람(−3~+3)을 부드럽게 따라가는
/// 값. 턴이 바뀌어 바람이 바뀌어도 구름·포말·물보라가 한 프레임에 꺾이지 않고
/// [easeSec] 초쯤에 걸쳐 새 바람으로 돈다. 그리기 전용이라 판정과 무관하다.
class WindFeel extends Component {
  WindFeel({required this.session}) : value = session.state.wind.toDouble();

  final BattleSession session;

  /// 지금 느끼는 바람(−3~+3, 오른쪽이 +).
  double value;

  /// 새 바람으로 거의 다 바뀌는 시간(초).
  static const double easeSec = 0.8;

  /// 지금 턴의 바람(시뮬레이션 값).
  int get target => session.state.wind;

  /// 바람이 부는 쪽(−1·0·+1). 거의 무풍이면 0.
  int get dir => value.abs() < .05 ? 0 : value.sign.toInt();

  /// 세기 0~1 (3단계 = 1).
  double get strength => (value.abs() / 3).clamp(0.0, 1.0);

  @override
  void update(double dt) {
    value = approach(value, target.toDouble(), dt);
  }

  /// [from] 에서 [to] 로 [dt] 초만큼 다가간 값 (지수 감쇠).
  static double approach(double from, double to, double dt) {
    if (dt <= 0) return from;
    final k = 1 - math.exp(-4 * dt / easeSec);
    return from + (to - from) * k;
  }
}
