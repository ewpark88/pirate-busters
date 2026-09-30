import 'package:pb_ai/src/aim_solver.dart';
import 'package:pb_ai/src/dials.dart';
import 'package:pb_ai/src/turn_choice.dart';
import 'package:pb_sim/pb_sim.dart';

/// 한 턴 전체를 미리 평가하는 AI 계획기 (설계서 §5.5).
///
/// 위치 후보 × 쏠 수 있는 해적 × 후보 샷(96개)을 차례로 평가한다. 앱은 [step] 으로
/// 프레임마다 [perFrame] 개씩 나눠 계산하고(A5.1), 헤드리스·`sim_runner` 는 [plan]
/// 으로 한 번에 끝낸다. 평가 중에 배 위치·바람을 잠시 바꿨다가 되돌리므로 매치
/// 상태는 바뀌지 않는다. 오차·후보 선택 난수는 매치 시드·턴·진영에서 따로 만든다.
class AiPlanner {
  AiPlanner(
    this.state, {
    required this.level,
    this.personality = Personality.bombard,
    this.losses = 0,
  }) : dials = AiDials.of(level),
       side = state.activeSide,
       rng = XorShift32(
         state.seed * 31 + state.turn * 1009 + state.activeSide * 7919 + 17,
       ) {
    _positions = _positionCandidates();
    _jobs = [
      for (var pi = 0; pi < _positions.length; pi++)
        for (final slot in _shooters())
          for (final (angle, power) in candidateGrid(_spec(slot)))
            (pi, slot, angle, power),
    ];
    _results = [for (final _ in _positions) <int, List<ShotPlan>>{}];
  }

  /// 프레임당 계산 후보 수 (BALANCE.md A5.1).
  static const int perFrame = 8;

  final MatchState state;
  final AiLevel level;
  final Personality personality;

  /// 연패 수(연패 보정, A5.2).
  final int losses;
  final AiDials dials;
  final int side;
  final XorShift32 rng;

  late final List<int> _positions;
  late final List<(int, int, int, int)> _jobs;
  late final List<Map<int, List<ShotPlan>>> _results;
  int _next = 0;
  TurnBundle? _bundle;

  SideState get _me => state.sides[side];

  PirateSpec _spec(int slot) => _me.crew.pirates[slot].spec;

  /// 끝났으면 계획한 턴 묶음, 아니면 null.
  TurnBundle? get bundle => _bundle;

  /// 후보를 [budget] 개 평가한다. 다 끝나면 true.
  bool step([int budget = perFrame]) {
    if (_bundle != null) return true;
    final offset = _me.offset;
    try {
      for (var n = 0; n < budget && _next < _jobs.length; n++, _next++) {
        final (pi, slot, angle, power) = _jobs[_next];
        _me.offset = _positions[pi];
        final plan = evaluateShot(
          state,
          slot: slot,
          angle: angle,
          power: power,
          ms: _fireMs(pi),
          windPercent: dials.windCorrectionPercent,
        );
        (_results[pi][slot] ??= []).add(plan);
      }
    } finally {
      _me.offset = offset;
    }
    if (_next < _jobs.length) return false;
    _bundle = TurnChooser(this, _positions, _results).choose();
    return true;
  }

  /// 한 번에 끝까지 계획한다.
  TurnBundle plan() {
    while (!step(1 << 30)) {}
    return _bundle!;
  }

  /// 쏠 수 있는 해적. 지원 해적은 난이도 규칙을 따른다 (A5.2).
  List<int> _shooters() => [
    for (var slot = 0; slot < _me.crew.size; slot++)
      if (_me.canFire(slot) && _supportAllowed(slot)) slot,
  ];

  bool _supportAllowed(int slot) {
    if (_spec(slot).ammo != AmmoType.support) return true;
    return switch (dials.support) {
      SupportUse.never => false,
      SupportUse.fromHalfFlood => _me.flood * 2 >= fullFlood,
      SupportUse.timely => true,
    };
  }

  /// 위치 후보(시작 위치 기준 오프셋): 지금 자리 + 2칸 간격 앞뒤. 연료·한계선 안,
  /// 어려움 이상은 연료 비축량을 남긴다 (A5.5).
  List<int> _positionCandidates() {
    final now = _me.offset;
    final out = [now];
    final n = dials.positions;
    for (var k = 1; out.length < n && k <= n; k++) {
      for (final sign in const [1, -1]) {
        if (out.length >= n) break;
        final dx = sign * k * AiDials.positionStepCells * 10;
        final reach = moveReach(_me, state.rules, state.turn, dx, 20000);
        if (reach != dx * moveStep) continue;
        if (level.index >= AiLevel.hard.index) {
          final cost = reach.abs() * _me.fuelPerCell ~/ cellUnit;
          if (_me.fuel - cost < AiDials.fuelReserve * SideState.fuelUnit) {
            continue;
          }
        }
        out.add(now + reach);
      }
    }
    return out;
  }

  /// 위치 [pi] 로 옮긴 뒤 첫 발의 발사 시각(커맨드 t, 효과 시각이 아닌 턴 시각).
  int fireT(int pi) => dials.thinkMs + moveMs(pi);

  /// 위치 [pi] 까지 이동하는 시간(밀리초). 이동이 없으면 0.
  int moveMs(int pi) {
    final dist = (_positions[pi] - _me.offset).abs();
    if (dist == 0) return 0;
    return dist * 1000 ~/ moveSpeedOf(_me) + 200;
  }

  int _fireMs(int pi) => realMs(state, effectiveMs(state, fireT(pi)));
}
