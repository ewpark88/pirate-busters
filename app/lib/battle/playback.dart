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

/// 탄 비행. 여러 발(분열 조각·연사·다중투하)도 시뮬레이션이 남긴 경로
/// ([MatchState.lastTraces])를 그대로 그리고, 착탄·파괴·피격 이벤트는 각자의 틱에
/// 낸다. 배는 [live] 를 그린다: [before] 에서 시작해 이벤트가 나올 때마다 그 칸의
/// 피해를 더하므로, 탄이 닿기 전에는 그대로이고 탄마다 차례로 부서진다 (A33).
///
/// 분열탄은 계산을 미룬 채 날아가며 탭을 기다린다([awaitingTap]). 이때 경로는 앱이
/// 같은 계산으로 예측한 한 발이고, 탭하거나 착탄 틱이 되면 세션이 `TAP` 을 내고
/// [ShotPlayback.resolved] 로 바꾼다.
class ShotPlayback extends Playback {
  ShotPlayback._({
    required this.side,
    required this.slot,
    required this.fireT,
    required this.traces,
    required this.before,
    required this.lastTick,
    required this.awaitingTap,
    required List<(int, SimEvent)> timed,
    int breakMs = 0,
  }) : flightMs = roundDiv(lastTick * 1000, simTickHz),
       live = [for (final g in before) GridSnapshot.copy(g)],
       _timed = timed,
       super(roundDiv(lastTick * 1000, simTickHz) + breakMs) {
    for (final (tick, e) in timed) {
      if (e.kind == SimEventKind.impact || e.kind == SimEventKind.splash) {
        _landTick = tick;
        break;
      }
    }
  }

  /// 계산이 끝난 발사. [events] 는 이번 발사로 생긴 이벤트, [traces] 는 경로.
  /// 블록이 부서졌으면 [breakPauseMs] 만큼 부서지는 연출을 붙인다 (설계서 §2.3).
  factory ShotPlayback.resolved({
    required int side,
    required int slot,
    required int fireT,
    required List<ShotTrace> traces,
    required List<GridSnapshot> before,
    required List<SimEvent> events,
    required int breakPauseMs,
    int elapsedMs = 0,
  }) {
    var last = 1;
    for (final t in traces) {
      if (t.endTick > last) last = t.endTick;
    }
    // 착탄·물보라·튕김·갈라짐·방향 전환·방벽·요격 이벤트가 틱을 갖고, 뒤따르는
    // 파괴·피격은 그 틱에 낸다.
    var tick = 0;
    final timed = <(int, SimEvent)>[];
    for (final e in events) {
      if (e.kind == SimEventKind.fire) continue;
      if (_timedKinds.contains(e.kind)) tick = e.value;
      timed.add((tick > last ? last : tick, e));
    }
    final broke = events.any(
      (e) =>
          e.kind == SimEventKind.blockDestroyed ||
          e.kind == SimEventKind.blockCollapsed,
    );
    return ShotPlayback._(
      side: side,
      slot: slot,
      fireT: fireT,
      traces: traces,
      before: before,
      lastTick: last,
      awaitingTap: false,
      timed: timed,
      breakMs: broke ? breakPauseMs : 0,
    )..elapsedMs = elapsedMs;
  }

  /// 탭을 기다리는 분열탄: 예측 경로 [path](착탄 지점에서 끝남)로 난다.
  factory ShotPlayback.awaitingTap({
    required int side,
    required int slot,
    required int fireT,
    required ShotPath path,
    required List<GridSnapshot> before,
  }) {
    final trace = ShotTrace(id: -1, startTick: 0);
    for (var i = 0; i <= path.lastTick; i++) {
      trace.add(path.xs[i], path.ys[i]);
    }
    return ShotPlayback._(
      side: side,
      slot: slot,
      fireT: fireT,
      traces: [trace],
      before: before,
      lastTick: path.lastTick,
      awaitingTap: true,
      timed: const [],
    );
  }

  static const Set<SimEventKind> _timedKinds = {
    SimEventKind.impact,
    SimEventKind.splash,
    SimEventKind.bounce,
    SimEventKind.divide,
    SimEventKind.steered,
    SimEventKind.barrierHit,
    SimEventKind.intercepted,
  };

  /// 탄 비행 시간. 그 뒤 [durationMs] 까지는 부서지는 연출(턴 타이머 정지, §2.3).
  final int flightMs;

  /// 쏜 진영.
  final int side;
  final int slot;

  /// 발사 커맨드의 `t`. 분열 `TAP` 도 같은 `t` 로 낸다(ADR-035).
  final int fireT;

  /// 탄마다의 경로.
  final List<ShotTrace> traces;

  /// 마지막 탄이 끝나는 틱.
  final int lastTick;

  /// 분열탄이 탭을 기다리는 중(아직 계산 전).
  final bool awaitingTap;

  /// 쏘기 전 양쪽 격자(재질, 내구도). 첫 착탄 전까지 이 모습으로 그린다.
  final List<GridSnapshot> before;

  /// 지금까지 나온 이벤트만큼 피해를 더한 양쪽 격자. 화면은 이것을 그린다.
  final List<GridSnapshot> live;

  final List<(int, SimEvent)> _timed;
  int _released = 0;
  int? _landTick;

  /// 지금 틱(소수, 보간용).
  double get tick => elapsedMs * simTickHz / 1000;

  /// 첫 착탄(또는 물보라)이 지났다.
  bool get landed {
    final land = _landTick;
    return land != null && tick >= land;
  }

  /// 지금 틱까지 온 효과 이벤트를 꺼낸다. [all] 이면 남은 것을 모두.
  List<SimEvent> takeDue({bool all = false}) {
    final out = <SimEvent>[];
    while (_released < _timed.length && (all || _timed[_released].$1 <= tick)) {
      final e = _timed[_released++].$2;
      if (e.side >= 0 && e.side < live.length) live[e.side].apply(e);
      out.add(e);
    }
    return out;
  }
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

  GridSnapshot.copy(GridSnapshot other)
    : materials = List.of(other.materials),
      hp = List.of(other.hp);

  final List<int> materials;
  final List<int> hp;

  /// 내구도 합계 (선체 막대, 설계서 §13.4).
  int get totalHp => hp.fold(0, (a, b) => a + b);

  /// 시뮬레이션 이벤트 [e] 가 이 격자에 남긴 변화를 더한다 (A33). 칸 피해·파괴·
  /// 붕괴·수리만 본다.
  void apply(SimEvent e) {
    final i = e.cell;
    if (i < 0 || i >= hp.length) return;
    switch (e.kind) {
      case SimEventKind.blockHit || SimEventKind.repaired:
        hp[i] = e.y;
      case SimEventKind.blockDestroyed || SimEventKind.blockCollapsed:
        hp[i] = 0;
        materials[i] = ShipGrid.emptyCell;
      case _:
        break;
    }
  }
}
