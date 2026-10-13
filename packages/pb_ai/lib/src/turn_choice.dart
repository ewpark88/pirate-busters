import 'package:pb_ai/src/aim_solver.dart';
import 'package:pb_ai/src/dials.dart';
import 'package:pb_ai/src/move_goal.dart';
import 'package:pb_ai/src/planner.dart';
import 'package:pb_sim/pb_sim.dart';

/// 평가가 끝난 후보로 위치·한 발·쏘는 순간을 고르고 턴 묶음을 만든다 (설계서 §5.5).
class TurnChooser {
  TurnChooser(this.p, this.positions, this.results);

  final AiPlanner p;
  final List<int> positions;
  final List<Map<int, List<ShotPlan>>> results;

  /// 내 배에 선 상대 강습 해적을 흔들어 떨어뜨리는 이동의 가점 (설계서 §2.3, ADR-110).
  static const int shakeOffBonus = 120;

  /// 파도 타이밍 후보: 늦춰 쏘는 시간(밀리초) (BALANCE.md A5.5).
  static const List<int> waveDelays = [0, 300, 600];

  MatchState get _state => p.state;
  SideState get _me => _state.sides[p.side];
  SideState get _enemy => _state.sides[1 - p.side];
  Personality get _w => p.personality;

  TurnBundle choose() {
    var bestScore = -1 << 40;
    var bestPos = 0;
    ShotPlan? bestShot;
    for (var pi = 0; pi < positions.length; pi++) {
      final shot = _pickShot(results[pi]);
      final score =
          (shot == null ? 0 : _total(shot) + _pushScore(pi, shot)) +
          _positionScore(positions[pi]);
      if (score > bestScore) {
        bestScore = score;
        bestPos = pi;
        bestShot = shot;
      }
    }
    return _commands(bestPos, bestShot);
  }

  int _total(ShotPlan s) => s.value.total(_w);

  /// 해적마다 난이도 규칙으로 한 발을 고르고 점수 가장 높은 한 발을 쏜다 (§2.3).
  ShotPlan? _pickShot(Map<int, List<ShotPlan>> bySlot) {
    if (_state.firesThisTurn > 0) return null;
    ShotPlan? best;
    for (final slot in bySlot.keys.toList()..sort()) {
      final pick = _pick(bySlot[slot]!);
      if (pick != null && (best == null || _total(pick) > _total(best))) {
        best = pick;
      }
    }
    return best;
  }

  /// 점수 상위 [AiDials.pickTopPercent]% 안에서 무작위(0 이면 최상). 점수 0 이하는 쏘지 않는다.
  ShotPlan? _pick(List<ShotPlan> plans) {
    final good = [
      for (final s in plans)
        if (_total(s) > 0) s,
    ]..sort(_byScore);
    if (good.isEmpty) return null;
    final pct = p.dials.pickTopPercent;
    final pool = pct == 0
        ? 1
        : (good.length * pct ~/ 100).clamp(1, good.length);
    return good[p.rng.nextInt(pool)];
  }

  /// 점수 높은 순. 같으면 각도 → 힘 → 탭 틱 순으로 정해 결과가 정렬 구현에
  /// 기대지 않게 한다 (ADR-050).
  int _byScore(ShotPlan a, ShotPlan b) {
    final d = _total(b) - _total(a);
    if (d != 0) return d;
    if (a.angle != b.angle) return a.angle - b.angle;
    if (a.power != b.power) return a.power - b.power;
    return a.tapTick - b.tapTick;
  }

  /// [pi] 위치에서 [shot] 이 상대를 거친 구간으로 밀면 밀치기형 점수 (BALANCE.md A5.3).
  int _pushScore(int pi, ShotPlan shot) {
    if (_w.pushRough == 0 || shot.value.push == 0) return 0;
    final mine = _me.offset;
    final theirs = _enemy.offset;
    _me.offset = positions[pi];
    shoveShip(_enemy, _me, _state.rules, -shot.value.push * cellUnit);
    final rough = waveLevelOf(_state, _enemy.side) >= 3;
    _enemy.offset = theirs;
    _me.offset = mine;
    return rough ? _w.pushRough : 0;
  }

  /// 위치 점수: 파도 구간·돌격형·밀치기형·흔들기 (BALANCE.md A5.3·A5.5).
  int _positionScore(int offset) {
    final now = _me.offset;
    _me.offset = offset;
    final gap = (_state.sides[0].bowX - _state.sides[1].bowX).abs();
    final level = waveLevelOf(_state, p.side);
    _me.offset = now;
    var score = 0;
    if (p.dials.waveZones) {
      score -= level * AiDials.wavePenaltyPerLevel;
      // 지금 후보 밖의 잔잔한 구간도 턴마다 그쪽으로 다가간다 (S5, [MoveGoal]).
      score += MoveGoal.progressScore(now, offset, p.goal);
    }
    if (level == 0) score += _w.calmStand;
    if (gap <= Personality.rushGapCells * cellUnit) score += _w.rush;
    if (hasBoarders(_me) && (offset - now).abs() >= shakeOffDistance) {
      score += shakeOffBonus;
    }
    return score;
  }

  TurnBundle _commands(int pi, ShotPlan? shot) {
    final dials = p.dials;
    final commands = <Command>[];
    final dx = (positions[pi] - _me.offset) ~/ moveStep;
    var t = dials.thinkMs;
    if (dx != 0) {
      commands.add(MoveCommand(t: t, dx: dx));
      t = p.fireT(pi);
    }
    if (shot != null) {
      final err = dials.angleErrorMdeg + AiDials.streakBonusMdeg(p.losses);
      final home = _me.offset;
      // 파도 타이밍은 옮긴 자리에서 계산한다.
      _me.offset = positions[pi];
      final delay = dials.waveTiming ? _bestDelay(shot, t) : 0;
      _me.offset = home;
      final fireT = t + delay;
      final angle =
          shot.angle + (err == 0 ? 0 : p.rng.nextRange(-err, err + 1));
      commands.add(
        FireCommand(t: fireT, slot: shot.slot, angle: angle, power: shot.power),
      );
      if (shot.tapTick > 0) {
        commands.add(
          TapCommand(t: fireT, slot: shot.slot, ticks: shot.tapTick),
        );
      }
      t = fireT + dials.thinkMs;
    }
    commands.add(EndTurnCommand(t: t + 300));
    return TurnBundle(turn: _state.turn, side: p.side, commands: commands);
  }

  /// 파도 타이밍: 늦춰 쏘는 후보 중 점수가 가장 높은 지연 (A5.2 파도 타이밍 계산).
  int _bestDelay(ShotPlan s, int t) {
    var best = 0;
    var bestScore = -1 << 40;
    for (final d in waveDelays) {
      final ms = realMs(_state, effectiveMs(_state, t + d));
      final v = evaluateShot(
        _state,
        slot: s.slot,
        angle: s.angle,
        power: s.power,
        ms: ms,
        windPercent: p.dials.windCorrectionPercent,
      ).value.total(_w);
      if (v > bestScore) {
        bestScore = v;
        best = d;
      }
    }
    return best;
  }
}
