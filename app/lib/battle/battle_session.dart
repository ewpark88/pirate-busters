import 'package:flutter/foundation.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/battle/playback.dart';
import 'package:pirate_busters/battle/shot_path.dart';
import 'package:pirate_busters/battle/ui_state.dart';

/// 한 판의 진행 (개발 계획서 M4). 판정은 모두 [Match] 가 하고, 여기서는 시각을 세고
/// 입력을 커맨드로 바꾸고 연출 순서를 정한다 (CLAUDE.md 절대 규칙 3).
///
/// - 사람 턴: [move]·[fire]·[endTurn] 이 지금 턴 시각 `t` 로 커맨드를 낸다.
/// - 상대 턴: [opponent] 컨트롤러의 턴 묶음을 `t` 타이밍대로 재생한다.
/// - 연출([playback]) 동안에는 입력을 받지 않는다. 턴 시계는 계속 흐르고, 시뮬레이션이
///   탄 비행 시간만큼 턴 제한 시간을 멈춘다.
class BattleSession extends ChangeNotifier with SessionUiState {
  BattleSession(this.match, {required this.humanSides, this.opponent});

  final Match match;

  /// 사람이 두는 진영. 허수아비전은 {0}, 핫시트는 {0, 1}.
  @override
  final Set<int> humanSides;

  /// 사람이 아닌 진영의 컨트롤러.
  final Controller? opponent;

  MatchState get state => match.state;

  @override
  int get activeSide => state.activeSide;

  /// 지금 턴이 시작된 뒤 흐른 실제 시간(밀리초). 커맨드 `t` 가 된다.
  int turnMs = 0;

  /// 지금 보여주는 연출. 없으면 null.
  Playback? playback;

  /// 착탄 등 효과를 낼 이벤트. 렌더가 [takeCues] 로 가져간다.
  final List<SimEvent> _cues = [];

  TurnBundle? _script;
  int _scriptIndex = 0;
  int _turnOfClock = 1;

  bool get isOver => state.isOver;

  @override
  bool get isHumanTurn => humanSides.contains(state.activeSide);

  /// 사람이 지금 조작할 수 있는가.
  bool get canAct => !isOver && isHumanTurn && playback == null;

  /// 남은 턴 시간(밀리초). 탄 비행 연출 중에는 줄지 않는다.
  int get remainingMs {
    final shot = playback;
    final flightLeft = shot is ShotPlayback
        ? shot.durationMs - shot.elapsedMs
        : 0;
    final paused = state.pausedMs - flightLeft;
    final used = turnMs - paused;
    final left = state.rules.turnTimeFor(state.turn) - used;
    return left < 0 ? 0 : left;
  }

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
    if (left > 1200) return null;
    return (slot: c.slot, progress: (1 - left / 1200).clamp(0.0, 1.0));
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
      if (p is ShotPlayback && !p.landed && p.elapsedMs >= p.flightMs) {
        p.landed = true;
        _cues.addAll(p.landing);
      }
      if (p.isDone) _finishPlayback(p);
    }
    turnMs += dtMs;
    if (!isOver && playback == null) {
      if (isHumanTurn && surrenderQueued) {
        surrenderQueued = false;
        _apply(SurrenderCommand(t: turnMs));
      } else if (isHumanTurn) {
        if (remainingMs <= 0) _apply(EndTurnCommand(t: turnMs));
      } else {
        _playScript();
      }
    }
    notifyListeners();
  }

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

  /// 비행 중 탭 (설계서 §2.2). 내 탄이 날고 있을 때만 `TAP` 을 기록한다.
  /// MVP 에서는 효과가 없다(onTap 은 R1).
  void tap() {
    final shot = playback;
    if (shot is! ShotPlayback || !humanSides.contains(shot.side)) return;
    match.apply(
      TapCommand(t: turnMs, slot: shot.slot, tick: shot.tick.floor()),
    );
    notifyListeners();
  }

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
    final bundle = _script ??= opponent?.turnFor(state);
    if (bundle == null) return;
    while (playback == null && _scriptIndex < bundle.commands.length) {
      final c = bundle.commands[_scriptIndex];
      if (c.t > turnMs) return;
      _scriptIndex++;
      final turn = state.turn;
      _apply(c);
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
    // 고른 진영의 턴이 끝났으면 선택을 푼다(상대 턴에 고른 것은 남는다).
    if (selectedSide != state.activeSide) selected = null;
    _script = null;
    _scriptIndex = 0;
  }

  void _apply(Command c) {
    final side = state.activeSide;
    final turn = state.turn;
    final bowBefore = state.sides[side].bowX;
    ShotPath? path;
    List<GridSnapshot>? before;
    if (c is FireCommand) {
      path = ShotPath.predict(
        state,
        slot: c.slot,
        angle: c.angle,
        power: c.power,
        ms: realMs(state, effectiveMs(state, c.t)),
      );
      before = [for (final s in state.sides) GridSnapshot(s.grid)];
    }
    final start = _eventsStart(turn);
    final firedBefore = state.nextProjectileId;
    match.apply(c);
    // 분열탄 탭 연출은 M5 앱 단계에서 붙인다. 그때까지는 갈라지지 않은 채 바로 계산한다.
    if (match.pendingSlot >= 0) {
      match.apply(TapCommand(t: c.t, slot: match.pendingSlot, tick: 0));
    }
    // 턴이 끝나도 이벤트 목록은 다음 턴 첫 커맨드 때 비워진다.
    final events = state.events.sublist(start.clamp(0, state.events.length));
    if (path != null && state.nextProjectileId > firedBefore) {
      // 발사 이벤트는 바로(공격 동작·포성), 나머지는 착탄 때 낸다.
      _cues.addAll(events.where((e) => e.kind == SimEventKind.fire));
      playback = ShotPlayback.fromEvents(
        side: side,
        slot: (c as FireCommand).slot,
        path: path,
        before: before!,
        events: events,
        breakPauseMs: state.rules.breakPauseMs,
      );
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

  /// 이번 커맨드로 생길 이벤트가 [MatchState.events] 의 어디부터인지. 턴의 첫
  /// 커맨드면 목록이 새로 시작된다.
  int _eventsStart(int turn) {
    final events = state.events;
    final begun =
        events.isNotEmpty &&
        events.first.kind == SimEventKind.turnStart &&
        events.first.value == turn;
    return begun ? events.length : 0;
  }

  void _finishPlayback(Playback p) {
    playback = null;
    if (p is ShotPlayback && !p.landed) _cues.addAll(p.landing);
    if (p is MovePlayback) {
      _cues.add(SimEvent(SimEventKind.move, side: p.side, x: p.toX));
    }
    _syncTurnClock();
  }
}
