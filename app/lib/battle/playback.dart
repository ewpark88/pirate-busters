import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/battle/shot_path.dart';

/// 시뮬레이션이 한 번에 끝낸 행동을 화면에서 시간을 들여 보여주는 연출.
sealed class Playback {
  Playback(this.durationMs);

  /// 연출 길이(밀리초).
  final int durationMs;

  /// 지난 시간(밀리초).
  int elapsedMs = 0;

  bool get isDone => elapsedMs >= durationMs;

  /// 0~1 진행 비율.
  double get progress =>
      durationMs <= 0 ? 1 : (elapsedMs / durationMs).clamp(0, 1).toDouble();
}

/// 탄 비행. 착탄 전까지는 [before] 격자 스냅숏을 그리고, 끝나면 [landing]
/// 이벤트(착탄·파괴·붕괴·피격 …)로 효과를 낸다.
class ShotPlayback extends Playback {
  ShotPlayback({
    required this.side,
    required this.slot,
    required this.path,
    required this.before,
    required this.landing,
  }) : super(path.lastTick * 1000 ~/ simTickHz);

  /// 쏜 진영.
  final int side;
  final int slot;
  final ShotPath path;

  /// 쏘기 전 양쪽 격자(재질, 내구도). 착탄 전까지 이 모습으로 그린다.
  final List<GridSnapshot> before;

  /// 착탄 순간의 이벤트.
  final List<SimEvent> landing;

  /// 지금 틱(소수, 보간용).
  double get tick => elapsedMs * simTickHz / 1000;
}

/// 배 이동. 뱃머리 x 가 [fromX] 에서 [toX] 로 간다.
class MovePlayback extends Playback {
  MovePlayback({
    required this.side,
    required this.fromX,
    required this.toX,
    required int durationMs,
  }) : super(durationMs);

  final int side;
  final int fromX;
  final int toX;

  /// 지금 뱃머리 x (1/1000칸).
  double get bowX => fromX + (toX - fromX) * progress;
}

/// 격자 한 척의 재질·내구도 사본.
class GridSnapshot {
  GridSnapshot(ShipGrid grid)
    : materials = List.of(grid.rawMaterials),
      hp = List.of(grid.rawHp);

  final List<int> materials;
  final List<int> hp;
}
