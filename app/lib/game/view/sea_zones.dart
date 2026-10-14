import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/game/coords.dart';

/// 파도 구간을 화면에 그리는 값 (설계서 §2.6·§10.2, BALANCE.md A2.5).
///
/// 구간 세기는 판 시드로 정해진 `MatchState.waveZones` 를 그대로 읽는다. 구간은
/// 가운데에서 떨어진 정도로 나뉘고 좌우 대칭이다(`waveZoneIndex` 와 같은 나눔).
/// 경계 앞뒤 [blend] 안에서는 이웃 구간 세기와 부드럽게 섞어, 물빛·너울이 칼로
/// 자른 듯 바뀌지 않게 한다. 그리기 전용이라 판정과 무관하다.
class SeaZones {
  SeaZones(List<int> levels, {required this.width})
    : levels = List.unmodifiable(levels);

  /// 판 [state] 의 구간.
  factory SeaZones.of(MatchState state) =>
      SeaZones(state.waveZones, width: Coords.x(state.rules.waveZoneWidth));

  /// 가운데에서 바깥쪽으로 구간 세기(0·1·3).
  final List<int> levels;

  /// 구간 폭(월드 px).
  final double width;

  /// 경계 앞뒤로 섞는 폭(월드 px).
  static const double blend = 24;

  /// 가장 센 세기(거침).
  static const int maxLevel = 3;

  /// 월드 x [x](px)가 속한 구간 번호. 바깥 구간 너머는 마지막 구간이다. 나눔은
  /// 시뮬과 같은 pb_sim `zoneIndexAt` 을 쓴다.
  int indexAt(double x) => zoneIndexAt(
    (x * cellUnit / Coords.cell).truncate(),
    width: _simWidth,
    zones: levels.length,
  );

  late final int _simWidth = (width * cellUnit / Coords.cell).round();

  /// [x] 의 구간 세기(0~3).
  int levelAt(double x) => levels[indexAt(x)];

  /// [x] 의 섞인 세기(0~3): 경계 [blend] 안에서는 두 구간 사이 값이다.
  double smoothLevelAt(double x) {
    final d = x.abs();
    final i = indexAt(x);
    final here = levels[i].toDouble();
    // 가장 가까운 경계: 안쪽(i·width) 또는 바깥쪽((i+1)·width).
    final inner = i * width;
    final outer = (i + 1) * width;
    if (i > 0 && d - inner < blend) {
      final k = (d - inner + blend) / (2 * blend);
      return _mix(levels[i - 1].toDouble(), here, k);
    }
    if (i < levels.length - 1 && outer - d < blend) {
      final k = (d - outer + blend) / (2 * blend);
      return _mix(here, levels[i + 1].toDouble(), k);
    }
    return here;
  }

  /// 구간 경계 x 목록(월드 px, 오른쪽 양수만). 대칭이라 음수 쪽은 부호만 바꾼다.
  List<double> get edges => [
    for (var i = 1; i < levels.length; i++) i * width,
  ];

  static double _mix(double a, double b, double k) {
    final u = k.clamp(0.0, 1.0);
    final s = u * u * (3 - 2 * u);
    return a + (b - a) * s;
  }
}
