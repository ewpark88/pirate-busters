import 'package:flutter/foundation.dart';
import 'package:pb_ai/pb_ai.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/battle/auto_end.dart';
import 'package:pirate_busters/battle/playback.dart';
import 'package:pirate_busters/battle/session_views.dart';
import 'package:pirate_busters/battle/shot_flow.dart';
import 'package:pirate_busters/battle/ui_state.dart';

/// 한 판의 진행 (개발 계획서 M4). 판정은 모두 [Match] 가 하고, 여기서는 시각을 세고
/// 입력을 커맨드로 바꾸고 연출 순서를 정한다 (CLAUDE.md 절대 규칙 3).
///
/// - 사람 턴: [move]·[fire]·[endTurn] 이 지금 턴 시각 `t` 로 커맨드를 낸다.
/// - 상대 턴: [opponent] 컨트롤러의 턴 묶음을 `t` 타이밍대로 재생한다.
/// - 연출([playback]) 동안에는 입력을 받지 않는다. 턴 시계는 계속 흐르고, 시뮬레이션이
///   탄 비행 시간만큼 턴 제한 시간을 멈춘다.
class BattleSession extends ChangeNotifier with SessionUiState {
  BattleSession(
    this.match, {
    required this.humanSides,
    required this.speciesOf,
    this.opponent,
  });

  final Match match;

  /// 사람이 두는 진영. AI 전은 {0}, 핫시트는 {0, 1}.
  @override
  final Set<int> humanSides;

  /// 사람이 아닌 진영의 컨트롤러.
  final Controller? opponent;

  /// 해적 id → 그림 종족 id (게임 데이터 `render.species`).
  final String Function(String pirateId) speciesOf;

  MatchState get state => match.state;

  @override
  int get activeSide => state.activeSide;

  /// 지금 턴이 시작된 뒤 흐른 실제 시간(밀리초). 커맨드 `t` 가 된다.
  int turnMs = 0;

  /// 2발 뒤 자동 턴 종료 유예 (설계서 §2.2). 설정에서 끈다.
  final AutoEndClock autoEnd = AutoEndClock();

  /// 지금 보여주는 연출. 없으면 null.
  Playback? playback;

  /// 착탄 등 효과를 낼 이벤트. 렌더가 [takeCues] 로 가져간다.
  final List<SimEvent> _cues = [];

  TurnBundle? _script;

  /// AI 상대의 이번 턴 계획기. 프레임마다 후보를 나눠 평가한다 (BALANCE.md A5.1).
  AiPlanner? _planner;
  int _scriptIndex = 0;
  int _turnOfClock = 1;

  bool get isOver => state.isOver;

  @override
  bool get isHumanTurn => humanSides.contains(state.activeSide);

  /// 사람이 지금 조작할 수 있는가.
  bool get canAct => !isOver && isHumanTurn && playback == null;

  /// [slot] 해적을 지금 쏠 수 있는가.
  @override
  bool canFire(int slot) =>
      canAct &&
      !moveHeld &&
      state.firesThisTurn < state.rules.firesPerTurn &&
      state.sides[state.activeSide].canFire(slot);

  /// 상대가 곧 쏠 해적과 조준 진행(0~1). 상대 턴 재생에서 발사 1.2초 전부터
  /// 조준 자세를 보여준다. 궤적 점선은 숨긴다 (설계서 §2.3).
  ({int slot, double progress})? get opponentAim {
    final bundle = _script;
    if (isHumanTurn || bundle == null || playback != null) return null;
    if (_scriptIndex >= bundle.commands.length) return null;
    final c = bundle.commands[_scriptIndex];
    if (c is! FireCommand) return null;
    final left = c.t - turnMs;
    final window = aimShowMs;
    if (left > window) return null;
    return (slot: c.slot, progress: (1 - left / window).clamp(0.0, 1.0));
  }

  /// 쌓인 효과 이벤트를 꺼낸다.
  List<SimEvent> takeCues() {
    final out = List.of(_cues);
    _cues.clear();
    return out;
  }

  /// 매 프레임 [dtMs] 만큼 진행한다.
  void update(int dtMs) {
    if (isOver && playback == null) return;
    final p = playback;
    if (p != null) {
      p.elapsedMs += dtMs;
      if (p is ShotPlayback) _advanceShot(p);
      final now = playback;
      if (now != null && now.isDone) _finishPlayback(now);
    }
    turnMs += dtMs;
    if (!isOver && playback == null) {
      if (isHumanTurn && surrenderQueued) {
        surrenderQueued = false;
        _apply(SurrenderCommand(t: turnMs));
      } else if (isHumanTurn) {
        if (remainingMs <= 0) {
          _apply(EndTurnCommand(t: turnMs));
        } else if (_autoEndDue(dtMs)) {
          _apply(EndTurnCommand(t: turnMs));
        }
      } else {
        _playScript();
      }
    }
    notifyListeners();
  }

  bool _autoEndDue(int dtMs) => autoEnd.tick(
    dtMs,
    done: state.firesThisTurn >= state.rules.firesPerTurn,
    held: moveHeld,
  );

  /// 배를 [dx](1/10칸, 전진 +)만큼 움직인다.
  void move(int dx) {
    if (!canAct || dx == 0) return;
    _apply(MoveCommand(t: turnMs, dx: dx));
  }

  /// [slot] 해적을 쏜다.
  void fire(int slot, int angle, int power) {
    aim = null;
    if (selected == slot) selected = null;
    if (!canFire(slot)) return;
    _apply(FireCommand(t: turnMs, slot: slot, angle: angle, power: power));
  }

  /// 비행 중 탭 (설계서 §2.2). 내 탄이 날고 있을 때만 `TAP` 을 낸다. 분열탄이면
  /// 지금 틱에 갈라지고, 방향 전환 탄(알바)은 [dir] 쪽(+1 위, −1 아래)으로 꺾인다
  /// (설계서 §4.8). 다른 탄종에서는 효과가 없다.
  void tap({int dir = 0}) {
    final shot = playback;
    if (shot is! ShotPlayback || !humanSides.contains(shot.side)) return;
    final tick = shot.tick.floor();
    if (shot.awaitingTap) {
      if (tick >= 1 && tick < shot.lastTick) {
        playback = resolveSplit(match, shot, tick, dir: dir);
      }
    } else {
      match.apply(TapCommand(t: turnMs, slot: shot.slot, ticks: tick));
    }
    notifyListeners();
  }

  /// 탄 연출 한 프레임: 틱이 온 효과를 내고, 탭 없이 떨어지는 분열탄을 계산한다.
  void _advanceShot(ShotPlayback p) {
    if (p.awaitingTap) {
      if (p.tick >= p.lastTick) _resolveSplit(p, null);
      return;
    }
    _cues.addAll(p.takeDue());
  }

  void _resolveSplit(ShotPlayback p, int? tick) =>
      playback = resolveSplit(match, p, tick);

  void endTurn() {
    if (canAct) _apply(EndTurnCommand(t: turnMs));
  }

  /// 상대 턴에 누른 항복. 내 턴이 오면 바로 낸다 (설계서 §13.4 항복은 설정 안).
  bool surrenderQueued = false;

  void surrender() {
    if (isOver) return;
    if (isHumanTurn && playback == null) {
      _apply(SurrenderCommand(t: turnMs));
    } else {
      surrenderQueued = true;
      notifyListeners();
    }
  }

  void _playScript() {
    final ai = opponent;
    if (_script == null && ai is AiController) {
      final planner = _planner ??= ai.planner(state);
      if (!planner.step()) return;
      _script = planner.bundle;
    }
    final bundle = _script ??= opponent?.turnFor(state);
    if (bundle == null) return;
    while (playback == null && _scriptIndex < bundle.commands.length) {
      final c = bundle.commands[_scriptIndex];
      if (c.t > turnMs) return;
      // 발사 바로 뒤 같은 해적의 TAP 은 그 발사를 계산할 때 함께 넣는다.
      final tap = followingTap(bundle, _scriptIndex);
      _scriptIndex += tap == null ? 1 : 2;
      final turn = state.turn;
      _apply(c, followTap: tap);
      if (state.turn != turn || isOver) return;
    }
    if (playback == null && _scriptIndex >= bundle.commands.length) {
      _apply(EndTurnCommand(t: turnMs));
    }
  }

  /// 턴이 바뀌었고 연출이 끝났으면 턴 시계를 새로 시작한다.
  void _syncTurnClock() {
    if (playback != null || state.turn == _turnOfClock) return;
    _turnOfClock = state.turn;
    turnMs = 0;
    autoEnd.reset();
    // 고른 진영의 턴이 끝났으면 선택을 푼다(상대 턴에 고른 것은 남는다).
    if (selectedSide != state.activeSide) selected = null;
    _script = null;
    _planner = null;
    _scriptIndex = 0;
  }

  /// [followTap] 은 컴퓨터 발사 바로 뒤의 같은 해적 `TAP`: 기다리는 탄을 그 탭으로
  /// 계산해 재생(턴 묶음)과 같은 결과를 낸다.
  void _apply(Command c, {TapCommand? followTap}) {
    final side = state.activeSide;
    final turn = state.turn;
    final bowBefore = state.sides[side].bowX;
    // 분열탄은 탭 전까지 계산하지 않으므로 떨어질 곳을 미리 예측해 둔다.
    final split = c is FireCommand ? splitPathFor(state, c) : null;
    final before = [for (final s in state.sides) GridSnapshot(s.grid)];
    final start = eventsStartFor(state, turn);
    final firedBefore = state.nextProjectileId;
    match.apply(c);
    // 턴이 끝나도 이벤트 목록은 다음 턴 첫 커맨드 때 비워진다.
    final events = state.events.sublist(start.clamp(0, state.events.length));
    if (c is FireCommand && state.nextProjectileId > firedBefore) {
      // 발사 이벤트는 바로(공격 동작·포성), 나머지는 착탄 틱에 낸다.
      _cues.addAll(events.where((e) => e.kind == SimEventKind.fire));
      final pending = match.pendingSlot >= 0;
      if (pending && split != null && humanSides.contains(side)) {
        playback = ShotPlayback.awaitingTap(
          side: side,
          slot: c.slot,
          fireT: c.t,
          path: split,
          before: before,
        );
      } else {
        // 컴퓨터는 묶음에 든 TAP 으로, 없으면 탭 없이 계산한다.
        if (pending) {
          if (followTap != null) {
            match.apply(followTap);
          } else {
            match.settlePending();
          }
        }
        playback = resolvedShot(
          state,
          side: side,
          slot: c.slot,
          fireT: c.t,
          before: before,
          start: start,
        );
      }
    } else if (c is MoveCommand) {
      final move = events.where((e) => e.kind == SimEventKind.move);
      if (move.isNotEmpty) {
        playback = MovePlayback(
          side: side,
          fromX: bowBefore,
          toX: move.last.x,
          durationMs: move.last.y,
        );
      }
    } else {
      _cues.addAll(events);
    }
    _syncTurnClock();
    notifyListeners();
  }

  void _finishPlayback(Playback p) {
    playback = null;
    if (p is ShotPlayback) _cues.addAll(p.takeDue(all: true));
    if (p is MovePlayback) {
      _cues.add(SimEvent(SimEventKind.move, side: p.side, x: p.toX));
    }
    _syncTurnClock();
  }
}
