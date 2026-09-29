import 'package:pb_sim/src/combat/flight.dart';
import 'package:pb_sim/src/combat/launch.dart';
import 'package:pb_sim/src/command/command.dart';
import 'package:pb_sim/src/hash/state_hasher.dart';
import 'package:pb_sim/src/match/judge.dart';
import 'package:pb_sim/src/match/match_state.dart';
import 'package:pb_sim/src/match/rules.dart';
import 'package:pb_sim/src/match/sim_event.dart';
import 'package:pb_sim/src/math/fx.dart';
import 'package:pb_sim/src/math/trig.dart';
import 'package:pb_sim/src/pirate/pirate_spec.dart';
import 'package:pb_sim/src/projectile/projectile.dart';
import 'package:pb_sim/src/ship/blueprint.dart';
import 'package:pb_sim/src/ship/flooding.dart';
import 'package:pb_sim/src/ship/motion.dart';

/// 턴 묶음 해시가 재생 결과와 다르다(부정 또는 버그, 설계서 §7.2).
class TurnHashMismatch implements Exception {
  const TurnHashMismatch(this.turn, this.expected, this.actual);

  final int turn;
  final int expected;
  final int actual;

  @override
  String toString() => 'TurnHashMismatch(turn $turn: $expected != $actual)';
}

/// 결정론 턴제 전투 엔진 (설계서 §2.3, §7). 같은 입력이면 같은 결과를 낸다.
///
/// 커맨드는 [apply] 로 하나씩(사람 조작) 넣거나 [playTurn] 으로 턴 묶음째(AI·재생)
/// 넣는다. 탄은 발사 커맨드 안에서 떨어질 때까지 한 번에 계산한다.
class Match {
  Match._(this.state);

  /// [blueprints]·[decks]·[costLimits] 는 [0] = 왼쪽, [1] = 오른쪽. 덱은 선실
  /// 슬롯 순서의 출전 해적 id 이고 [pirates] 에서 찾는다. [costLimits] 는 플레이어
  /// 레벨로 정해지는 출전 코스트 한도(설계서 §4.5). 명단 규칙 위반은 [ArgumentError].
  factory Match.start({
    required int seed,
    required List<Blueprint> blueprints,
    required List<List<String>> decks,
    required List<int> costLimits,
    required PirateCatalog pirates,
    MatchRules rules = const MatchRules(),
  }) {
    if (blueprints.length != 2 || decks.length != 2 || costLimits.length != 2) {
      throw ArgumentError('설계도·덱·코스트 한도는 진영마다 하나씩 2개여야 한다');
    }
    final sides = <SideState>[];
    for (var i = 0; i < 2; i++) {
      final lineup = [for (final id in decks[i]) pirates.byId(id)];
      checkLineup(blueprints[i].hull, lineup, costLimits[i]);
      sides.add(
        SideState(
          side: i,
          blueprint: blueprints[i],
          lineup: lineup,
          rules: rules,
        ),
      );
    }
    return Match._(MatchState(seed: seed, rules: rules, sides: sides));
  }

  final MatchState state;

  final List<TurnBundle> _log = [];
  final List<Command> _current = [];
  bool _turnOpen = false;

  /// 끝난 턴 묶음(턴 끝 해시 포함). 리플레이 저장·네트워크 전송용.
  List<TurnBundle> get turnLog => List.unmodifiable(_log);

  bool get isOver => state.isOver;

  /// 지금 턴의 커맨드 하나를 적용한다. 판이 끝났으면 무시한다.
  ///
  /// 턴 제한 시간이 지난 커맨드는 버리고 턴을 넘긴다. 발사는 탄이 떨어질 때까지
  /// 계산하고, 그 시간만큼 턴 타이머를 멈춘다. 이동은 거리 ÷ 속도만큼 턴 시간을
  /// 쓰고, 그동안 들어온 커맨드는 이동이 끝난 시각에 처리한다 (ADR-025).
  void apply(Command c) {
    if (state.isOver) return;
    if (!_turnOpen) _beginTurn();
    _current.add(c);
    final at = effectiveMs(state, c.t);
    if (at > state.rules.turnTimeFor(state.turn)) {
      _endTurn(TurnEndReason.timeout);
      return;
    }
    state.busyUntilMs = at;
    switch (c) {
      case MoveCommand():
        _move(c, at);
      case FireCommand():
        _fire(c, at);
      case TapCommand():
        // 비행 중 2단 동작(onTap)은 MVP 에서 쓰지 않는다 (개발 계획서 M5, R1).
        break;
      case EndTurnCommand():
        _endTurn(TurnEndReason.endTurn);
      case SurrenderCommand():
        state
          ..outcome = MatchOutcome.surrender
          ..winner = 1 - state.activeSide;
        _endTurn(TurnEndReason.matchOver);
    }
  }

  /// 턴 묶음 하나를 재생한다. 묶음이 `END_TURN` 없이 끝나면 시간 초과로 넘긴다.
  /// 묶음에 해시가 있으면 결과와 비교해 다르면 [TurnHashMismatch].
  void playTurn(TurnBundle bundle) {
    if (state.isOver) return;
    if (bundle.turn != state.turn || bundle.side != state.activeSide) {
      throw ArgumentError(
        '턴 순서가 다르다: ${bundle.turn}/${bundle.side}, '
        '지금 ${state.turn}/${state.activeSide}',
      );
    }
    final turn = state.turn;
    for (final c in bundle.commands) {
      if (state.turn != turn || state.isOver) break;
      apply(c);
    }
    if (state.turn == turn && !state.isOver) {
      if (!_turnOpen) _beginTurn();
      _endTurn(TurnEndReason.timeout);
    }
    final expected = bundle.hash;
    final actual = _log.last.hash!;
    if (expected != null && expected != actual) {
      throw TurnHashMismatch(turn, expected, actual);
    }
  }

  /// 턴 시작: 폭풍 타임 시작(양쪽 연료·후퇴 한계) → 내 연료 회복 → 해적 복귀.
  void _beginTurn() {
    _turnOpen = true;
    final side = state.activeSide;
    final turn = state.turn;
    final rules = state.rules;
    state.events
      ..clear()
      ..add(SimEvent(SimEventKind.turnStart, side: side, value: turn));
    if (turn == rules.stormStartTurn) {
      for (final s in state.sides) {
        startStorm(s, rules, turn);
      }
      state.events.add(
        SimEvent(SimEventKind.stormStart, side: side, value: turn),
      );
    }
    refuel(state.sides[side], rules.fuelPerTurn);
    state.sides[side].crew.startOwnTurn(side, state.events);
  }

  void _move(MoveCommand c, int at) {
    final side = state.sides[state.activeSide];
    final left = state.rules.turnTimeFor(state.turn) - at;
    final r = applyMove(side, state.rules, state.turn, c.dx, left);
    if (r.distance == 0) return;
    state.busyUntilMs = at + r.durationMs;
    state.events.add(
      SimEvent(
        SimEventKind.move,
        side: side.side,
        x: side.bowX,
        y: r.durationMs,
        value: r.distance,
      ),
    );
  }

  void _fire(FireCommand c, int at) {
    final active = state.activeSide;
    final side = state.sides[active];
    if (state.firesThisTurn >= state.rules.firesPerTurn) return;
    if (!side.crew.canFire(c.slot)) return;
    if (c.angle < 0 || c.angle >= fullTurnMdeg) return;
    if (c.power < 0 || c.power > maxFirePower) return;
    final ms = realMs(state, at);
    final id = state.nextProjectileId++;
    final shot = launchShot(
      state,
      slot: c.slot,
      angle: c.angle,
      power: c.power,
      ms: ms,
      id: id,
    );
    final x = shot.x;
    final y = shot.y;
    side.crew.markFired(c.slot);
    side.shotsFired++;
    state
      ..firesThisTurn += 1
      ..events.add(
        SimEvent(
          SimEventKind.fire,
          side: active,
          slot: c.slot,
          x: x,
          y: y,
          value: id,
        ),
      );
    final ticks = resolveShot(state, shot, ms);
    state.pausedMs += roundDiv(ticks * 1000, simTickHz);
    judgeInstant(state);
    if (state.isOver) {
      _endTurn(TurnEndReason.matchOver);
    } else if (state.firesThisTurn >= state.rules.firesPerTurn) {
      _endTurn(TurnEndReason.firesUsed);
    }
  }

  /// 턴 끝 처리 (설계서 §2.3): 화재(M5) → 침수 → 수리·펌프(M5) → 쿨다운 → 바람.
  /// 30턴이 끝나면 시간 판정 (설계서 §2.4).
  void _endTurn(TurnEndReason reason) {
    final side = state.activeSide;
    final turn = state.turn;
    if (!state.isOver) {
      final gain = applyFlood(state.sides[side], state.rules, turn);
      if (gain > 0) {
        state.events.add(SimEvent(SimEventKind.flood, side: side, value: gain));
      }
      judgeInstant(state);
    }
    state.sides[side].crew.endOwnTurn();
    state.events.add(
      SimEvent(
        SimEventKind.turnEnd,
        side: side,
        cell: reason.index,
        value: turn,
      ),
    );
    if (!state.isOver && turn >= state.rules.maxTurns) judgeTime(state);
    state
      ..turn = turn + 1
      ..wind = state.rules.windForTurn(state.seed, turn + 1)
      ..firesThisTurn = 0
      ..pausedMs = 0
      ..busyUntilMs = 0;
    _log.add(
      TurnBundle(
        turn: turn,
        side: side,
        commands: List.of(_current),
        hash: hashMatchState(state),
      ),
    );
    _current.clear();
    _turnOpen = false;
  }
}
