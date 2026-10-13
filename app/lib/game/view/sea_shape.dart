import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/battle/playback.dart';
import 'package:pirate_busters/game/coords.dart';
import 'package:pirate_busters/game/view/ship_view.dart';

/// 배 한 척이 수면에 주는 값: 가운데 x·반폭·파도 높이(월드 px), 뱃머리 쪽
/// (+1 오른쪽), 이동 연출 중인지.
typedef ShipOnSea = ({
  double x,
  double half,
  double heave,
  int facing,
  bool moving,
});

/// 수면 모양 (설계서 §10.2 “큰 너울과 물마루”): 두 배의 파도 위아래(시뮬레이션
/// heave)를 잇고, 배에서 먼 바다에만 긴 너울을 더한다. 배 자리에서는 너울이 0이라
/// 배와 물이 어긋나지 않는다. 너울은 [scale] 배로 그린다.
/// 그리기 전용이라 판정과 무관하다.
class SeaShape extends Component {
  SeaShape({required this.ships, required this.scale});

  /// 지금 두 배 (진영 0, 1 순).
  final List<ShipOnSea> Function() ships;

  /// 너울 배율 (평소 1, 폭풍 타임이면 `stormWavePercent / 100`).
  final double Function() scale;

  /// 너울 높이(월드 px), 파장(월드 px), 흐르는 속도(라디안/초), 배 둘레 잔잔한 폭.
  static const double amp = 9;
  static const double length = 560;
  static const double speed = 0.6;
  static const double calmMargin = 260;

  double t = 0;

  /// 이번 프레임의 두 배와 너울 배율 ([update] 때 한 번 읽는다).
  List<ShipOnSea> current = const [];
  double _scale = 1;

  @override
  void update(double dt) {
    t += dt;
    current = ships();
    _scale = scale();
  }

  /// 수면 높이(월드 px, 아래가 +).
  double call(double x) => lerp(current, x) + swell(x, t, current, _scale);

  /// 두 배의 파도 높이를 x 로 잇는다. 배 바깥은 가까운 배 높이.
  static double lerp(List<ShipOnSea> s, double x) {
    if (s.length < 2 || s[0].x == s[1].x) return s.isEmpty ? 0 : s[0].heave;
    final k = ((x - s[0].x) / (s[1].x - s[0].x)).clamp(0.0, 1.0);
    return s[0].heave + (s[1].heave - s[0].heave) * k;
  }

  /// 배에서 멀수록 1, 배 위와 둘레는 0 (부드러운 계단).
  static double calm(List<ShipOnSea> s, double x) {
    var w = 1.0;
    for (final ship in s) {
      final d = ((x - ship.x).abs() - ship.half) / calmMargin;
      final k = d.clamp(0.0, 1.0);
      w = math.min(w, k * k * (3 - 2 * k));
    }
    return w;
  }

  /// 긴 너울 높이(월드 px).
  static double swell(double x, double t, List<ShipOnSea> s, double scale) =>
      amp * scale * calm(s, x) * math.sin(x / length * 2 * math.pi - t * speed);

  /// [from]~[to] 안의 물마루(너울 꼭대기, 수면이 가장 높은 곳) x 목록.
  Iterable<double> crests(double from, double to) sync* {
    // 꼭대기: sin(...) = −1 (화면 아래가 + 라 높이가 가장 작을 때).
    const step = length;
    final phase = (t * speed - math.pi / 2) / (2 * math.pi) * length;
    var x = (from / step).floorToDouble() * step + phase % step;
    for (; x <= to; x += step) {
      if (x >= from) yield x;
    }
  }
}

/// [ship] 이 수면에 주는 값 (월드 px). 이동 연출 중이면 그 중간 자리.
ShipOnSea shipOnSea(ShipView ship) {
  final width = ship.session.state.sides[ship.side].grid.width;
  final facing = facingOf(ship.side);
  final p = ship.session.playback;
  return (
    x: Coords.x(ship.bowX) - facing * width * Coords.cell / 2,
    half: width * Coords.cell / 2,
    heave: Coords.y(ship.heave),
    facing: facing,
    moving: p is MovePlayback && p.side == ship.side,
  );
}
