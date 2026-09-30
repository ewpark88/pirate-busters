import 'package:pb_sim/src/combat/ammo_rules.dart';
import 'package:pb_sim/src/combat/effect_runner.dart';
import 'package:pb_sim/src/combat/flight.dart';
import 'package:pb_sim/src/combat/launch.dart';
import 'package:pb_sim/src/combat/module_effects.dart';
import 'package:pb_sim/src/combat/volley.dart';
import 'package:pb_sim/src/command/command.dart';
import 'package:pb_sim/src/hash/state_hasher.dart';
import 'package:pb_sim/src/match/judge.dart';
import 'package:pb_sim/src/match/match_state.dart';
import 'package:pb_sim/src/match/rules.dart';
import 'package:pb_sim/src/match/sim_event.dart';
import 'package:pb_sim/src/math/fx.dart';
import 'package:pb_sim/src/math/trig.dart';
import 'package:pb_sim/src/pirate/ammo.dart';
import 'package:pb_sim/src/pirate/pirate_spec.dart';
import 'package:pb_sim/src/projectile/projectile.dart';
import 'package:pb_sim/src/ship/blueprint.dart';
import 'package:pb_sim/src/ship/motion.dart';

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

  /// 탭을 기다리는 분열탄 발사 (설계서 §4.8). 다음 커맨드에서 계산한다.
  Volley? _pending;

  /// 끝난 턴 묶음(턴 끝 해시 포함). 리플레이 저장·네트워크 전송용.
  List<TurnBundle> get turnLog => List.unmodifiable(_log);

  bool get isOver => state.isOver;

  /// 분열탄이 날아가며 TAP 을 기다리는 중이면 그 해적 슬롯, 아니면 −1.
  int get pendingSlot => _pending?.shots.first.slot ?? -1;

  /// 지금 턴의 커맨드 하나를 적용한다. 판이 끝났으면 무시한다.
  ///
  /// 턴 제한 시간이 지난 커맨드는 버리고 턴을 넘긴다. 발사는 탄이 떨어질 때까지
  /// 계산하고, 그 시간만큼 턴 타이머를 멈춘다. 이동은 거리 ÷ 속도만큼 턴 시간을
  /// 쓰고, 그동안 들어온 커맨드는 이동이 끝난 시각에 처리한다 (ADR-025).
  ///
  /// 분열탄을 쏘면 바로 계산하지 않고 다음 커맨드를 기다린다. 같은 해적의 `TAP` 이면
  /// 그 `tick` 에 갈라지고(시각 `t` 는 보지 않는다), 다른 커맨드면 갈라지지 않은 채
  /// 계산한 뒤 그 커맨드를 이어서 처리한다. 계산으로 턴이 끝나면 그 커맨드는 버린다.
  void apply(Command c) {
    if (state.isOver) return;
    final pending = _pending;
    if (pending != null) {
      final turn = state.turn;
      if (c is TapCommand && c.slot == pendingSlot) {
        _current.add(c);
        _resolve(pending, c.tick);
        return;
      }
      _resolve(pending, -1);
      if (state.turn != turn || state.isOver) return;
    }
    if (!_turnOpen && !_openTurn()) return;
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
        // 탭을 기다리는 분열탄이 없으면 아무 일도 없다.
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
      if (_turnOpen || _openTurn()) _endTurn(TurnEndReason.timeout);
    }
    final expected = bundle.hash;
    final actual = _log.last.hash!;
    if (expected != null && expected != actual) {
      throw TurnHashMismatch(turn, expected, actual);
    }
  }

  /// 턴을 연다. 턴 시작 효과로 판이 끝나면 턴을 닫고 false.
  bool _openTurn() {
    _beginTurn();
    if (!state.isOver) return true;
    _endTurn(TurnEndReason.matchOver);
    return false;
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
        final moved = startStorm(s, rules, turn);
        if (moved != 0) {
          state.events.add(
            SimEvent(SimEventKind.move, side: s.side, x: s.bowX, value: moved),
          );
        }
      }
      state.events.add(
        SimEvent(SimEventKind.stormStart, side: side, value: turn),
      );
    }
    refuel(state.sides[side], rules.fuelPerTurn);
    state.sides[side].crew.startOwnTurn(side, state.events);
    runTurnEffects(state);
    judgeInstant(state);
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
    if (!side.canFire(c.slot)) return;
    if (c.angle < 0 || c.angle >= fullTurnMdeg) return;
    if (c.power < 0 || c.power > maxFirePower) return;
    final ms = realMs(state, at);
    final shots = launchVolley(
      state,
      slot: c.slot,
      angle: c.angle,
      power: c.power,
      ms: ms,
    );
    markFiredWithModules(side, c.slot);
    side.shotsFired++;
    state
      ..firesThisTurn += 1
      ..lastTraces = const []
      ..events.add(
        SimEvent(
          SimEventKind.fire,
          side: active,
          slot: c.slot,
          x: shots.first.x,
          y: shots.first.y,
          value: shots.first.id,
        ),
      );
    final pending = Volley(shots, ms);
    if (shots.first.spec.ammo == AmmoType.split) {
      _pending = pending;
    } else {
      _resolve(pending, -1);
    }
  }

  /// 발사한 탄을 떨어질 때까지 계산하고 그만큼 턴 타이머를 멈춘다. [closeTurn] 이면
  /// 판이 끝나거나 발사를 다 썼을 때 턴을 닫는다.
  void _resolve(Volley shot, int tapTick, {bool closeTurn = true}) {
    _pending = null;
    final before = state.events.length;
    final ticks = runVolley(state, shot.shots, shot.ms, tapTick: tapTick);
    state.pausedMs +=
        roundDiv(ticks * 1000, simTickHz) + breakPauseOf(state, from: before);
    judgeInstant(state);
    if (!closeTurn) return;
    if (state.isOver) {
      _endTurn(TurnEndReason.matchOver);
    } else if (state.firesThisTurn >= state.rules.firesPerTurn) {
      _endTurn(TurnEndReason.firesUsed);
    }
  }

  /// 턴 끝 처리 (설계서 §2.3): 화재(M5) → 침수 → 수리·펌프(M5) → 쿨다운 → 바람.
  /// 30턴이 끝나면 시간 판정 (설계서 §2.4).
  void _endTurn(TurnEndReason reason) {
    final pending = _pending;
    if (pending != null) _resolve(pending, -1, closeTurn: false);
    final side = state.activeSide;
    final turn = state.turn;
    if (!state.isOver) {
      endTurnWater(state.sides[side], state.rules, turn, state.events);
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
