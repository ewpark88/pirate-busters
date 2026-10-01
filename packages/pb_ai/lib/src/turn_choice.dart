import 'package:pb_ai/src/aim_solver.dart';
import 'package:pb_ai/src/dials.dart';
import 'package:pb_ai/src/planner.dart';
import 'package:pb_sim/pb_sim.dart';

/// 평가가 끝난 후보로 위치·발사 2발·쏘는 순간을 고르고 턴 묶음을 만든다 (설계서 §5.5).
class TurnChooser {
  TurnChooser(this.p, this.positions, this.results);

  final AiPlanner p;
  final List<int> positions;
  final List<Map<int, List<ShotPlan>>> results;

  /// 방어 점수 (BALANCE.md A5.3, 임시값).
  static const int reachPenalty = 15;

  /// 사거리 밖 해적 1명당, 닿는 간격까지 남은 1칸마다 빼는 점수 (A5.3 방어 점수의 연장).
  static const int approachPerCell = 5;

  /// 콤보: 첫 발이 부순 칸 옆에 떨어지는 두 번째 발 보너스.
  static const int comboBonus = 20;

  /// 파도 타이밍 후보: 늦춰 쏘는 시간(밀리초).
  static const List<int> waveDelays = [0, 300, 600];

  MatchState get _state => p.state;
  SideState get _me => _state.sides[p.side];
  SideState get _enemy => _state.sides[1 - p.side];

  TurnBundle choose() {
    var bestScore = -1 << 40;
    var bestPos = 0;
    var bestShots = <ShotPlan>[];
    for (var pi = 0; pi < positions.length; pi++) {
      final shots = _pickShots(results[pi]);
      final score =
          shots.fold(0, (s, x) => s + _total(x)) +
          _positionScore(positions[pi]);
      if (score > bestScore) {
        bestScore = score;
        bestPos = pi;
        bestShots = shots;
      }
    }
    return _commands(bestPos, bestShots);
  }

  Personality get _weights {
    if (!_timeMode) return p.personality;
    // 시간 판정 모드에서 뒤지면 상대 흘수선만 노린다 (§5.5).
    return _leading ? p.personality : Personality.sinker;
  }

  bool get _timeMode => p.dials.timeMode && _state.turn >= AiDials.timeModeTurn;

  bool get _leading => _me.flood < _enemy.flood;

  int _total(ShotPlan s) {
    final t = s.value.total(_weights);
    // 앞서면 수리(지원탄)를 두 배로 친다.
    if (_timeMode && _leading && _isSupport(s.slot)) return t * 2;
    return t;
  }

  bool _isSupport(int slot) =>
      _me.crew.pirates[slot].spec.ammo == AmmoType.support;

  /// 해적마다 난이도 규칙으로 한 발을 고르고 점수 높은 두 해적을 쏜다.
  List<ShotPlan> _pickShots(Map<int, List<ShotPlan>> bySlot) {
    final picks = <ShotPlan>[];
    for (final slot in bySlot.keys.toList()..sort()) {
      final pick = _pick(bySlot[slot]!);
      if (pick != null) picks.add(pick);
    }
    picks.sort(
      (a, b) =>
          _total(b) != _total(a) ? _total(b) - _total(a) : a.slot - b.slot,
    );
    final fires = _state.rules.firesPerTurn - _state.firesThisTurn;
    final chosen = picks.take(fires < 0 ? 0 : fires).toList();
    if (chosen.length == 2) {
      final second = p.dials.combo
          ? _comboFor(chosen.first, bySlot[chosen[1].slot]!)
          : _apartFrom(chosen.first, chosen[1], bySlot[chosen[1].slot]!);
      if (second != null) chosen[1] = second;
    }
    return chosen;
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

  /// 두 번째 발이 첫 발이 부술 칸에 떨어지면(겹쳐서 낭비) 같은 해적의 다른 후보를
  /// 난이도 규칙으로 다시 고른다. 겹치지 않으면 그대로.
  ShotPlan? _apartFrom(ShotPlan first, ShotPlan second, List<ShotPlan> plans) {
    final holes = first.value.destroyed.toSet();
    final w = _enemy.grid.width;
    bool overlaps(ShotPlan s) => s.landings.any(
      (l) => l.hitShip && l.side != p.side && holes.contains(l.cy * w + l.cx),
    );
    if (holes.isEmpty || !overlaps(second)) return null;
    return _pick([
      for (final s in plans)
        if (!overlaps(s)) s,
    ]);
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

  /// 콤보: 첫 발이 부술 칸 바로 옆(안쪽)에 떨어지는 두 번째 발을 더 친다.
  ShotPlan? _comboFor(ShotPlan first, List<ShotPlan> plans) {
    final holes = first.value.destroyed.toSet();
    if (holes.isEmpty) return null;
    final w = _enemy.grid.width;
    ShotPlan? best;
    var bestScore = 0;
    for (final s in plans) {
      var score = _total(s);
      for (final l in s.landings) {
        if (!l.hitShip || l.side == p.side) continue;
        for (final h in holes) {
          if ((h % w - l.cx).abs() + (h ~/ w - l.cy).abs() == 1) {
            score += comboBonus;
            break;
          }
        }
      }
      if (score > bestScore) {
        bestScore = score;
        best = s;
      }
    }
    return best;
  }

  /// 방어 점수와 돌격형·시간 판정 모드 위치 선호 (A5.3, A5.5).
  int _positionScore(int offset) {
    final now = _me.offset;
    _me.offset = offset;
    final gap = (_state.sides[0].bowX - _state.sides[1].bowX).abs();
    _me.offset = now;
    var score = 0;
    for (final pirate in _enemy.crew.pirates) {
      if (pirate.status != PirateStatus.down &&
          pirate.spec.range.hitGap >= gap) {
        score -= reachPenalty;
      }
    }
    for (var slot = 0; slot < _me.crew.size; slot++) {
      final spec = _me.crew.pirates[slot].spec;
      if (_me.crew.pirates[slot].status == PirateStatus.down) continue;
      if (spec.ammo == AmmoType.support) continue;
      if (spec.range.hitGap < gap) {
        // 사거리 밖 해적이 있으면 다가갈수록 좋다: 여러 턴에 걸쳐 사거리 안으로 (§5.5).
        score -= (gap - spec.range.hitGap) ~/ cellUnit * approachPerCell;
        continue;
      }
      score += reachPenalty;
      if (spec.range == RangeGrade.short) score += p.personality.rush;
    }
    // 앞서는 시간 판정 모드는 멀리 물러난다.
    if (_timeMode && _leading) score += (now - offset) ~/ 100;
    return score;
  }

  TurnBundle _commands(int pi, List<ShotPlan> shots) {
    final dials = p.dials;
    final commands = <Command>[];
    final dx = (positions[pi] - _me.offset) ~/ moveStep;
    var t = dials.thinkMs;
    if (dx != 0) {
      commands.add(MoveCommand(t: t, dx: dx));
      t = p.fireT(pi);
    }
    final err = dials.angleErrorMdeg + AiDials.streakBonusMdeg(p.losses);
    final home = _me.offset;
    for (final s in shots) {
      // 파도 타이밍은 옮긴 자리에서 계산한다.
      _me.offset = positions[pi];
      final delay = dials.waveTiming ? _bestDelay(s, t) : 0;
      _me.offset = home;
      final fireT = t + delay;
      final angle = s.angle + (err == 0 ? 0 : p.rng.nextRange(-err, err + 1));
      commands.add(
        FireCommand(t: fireT, slot: s.slot, angle: angle, power: s.power),
      );
      if (s.tapTick > 0) {
        commands.add(TapCommand(t: fireT, slot: s.slot, ticks: s.tapTick));
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
      ).value.total(_weights);
      if (v > bestScore) {
        bestScore = v;
        best = d;
      }
    }
    return best;
  }
}
