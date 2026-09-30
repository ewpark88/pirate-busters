import 'package:flutter/foundation.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/battle/playback.dart';
import 'package:pirate_busters/battle/shot_path.dart';
import 'package:pirate_busters/input/pull_aim.dart';

/// 한 판의 진행 (개발 계획서 M4). 판정은 모두 [Match] 가 하고, 여기서는 시각을 세고
/// 입력을 커맨드로 바꾸고 연출 순서를 정한다 (CLAUDE.md 절대 규칙 3).
///
/// - 사람 턴: [move]·[fire]·[endTurn] 이 지금 턴 시각 `t` 로 커맨드를 낸다.
/// - 상대 턴: [opponent] 컨트롤러의 턴 묶음을 `t` 타이밍대로 재생한다.
/// - 연출([playback]) 동안에는 입력을 받지 않는다. 턴 시계는 계속 흐르고, 시뮬레이션이
///   탄 비행 시간만큼 턴 제한 시간을 멈춘다.
class BattleSession extends ChangeNotifier {
  BattleSession(this.match, {required this.humanSides, this.opponent});

  final Match match;

  /// 사람이 두는 진영. 허수아비전은 {0}, 핫시트는 {0, 1}.
  final Set<int> humanSides;

  /// 사람이 아닌 진영의 컨트롤러.
  final Controller? opponent;

  MatchState get state => match.state;

  /// 지금 턴이 시작된 뒤 흐른 실제 시간(밀리초). 커맨드 `t` 가 된다.
  int turnMs = 0;

  /// 지금 보여주는 연출. 없으면 null.
  Playback? playback;

  /// 조준 중인 해적 슬롯과 값. 궤적 미리보기·자동 줌아웃에 쓴다.
  ({int slot, AimShot shot, double stretch})? aim;

  /// 이동 버튼을 누르고 있다. 그동안은 쏠 수 없다 (ADR-027).
  bool moveHeld = false;

  /// 이동 버튼을 누르고 있는 동안 갈 수 있는 끝(1/10칸, 전진 +). 끝 지점 점선용.
  int movePreviewDx = 0;

  /// 착탄 등 효과를 낼 이벤트. 렌더가 [takeCues] 로 가져간다.
  final List<SimEvent> _cues = [];

  TurnBundle? _script;
  int _scriptIndex = 0;
  int _turnOfClock = 1;

  bool get isOver => state.isOver;

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
  bool canFire(int slot) =>
      canAct &&
      !moveHeld &&
      state.firesThisTurn < state.rules.firesPerTurn &&
      state.sides[state.activeSide].canFire(slot);

  /// 지금 쏘면 날아갈 궤적(미리보기).
  ShotPath previewShot(int slot, int angle, int power) => ShotPath.predict(
    state,
    slot: slot,
    angle: angle,
    power: power,
    ms: realMs(state, effectiveMs(state, turnMs)),
  );

  void setAim(int slot, AimShot shot, double stretch) {
    if (!canFire(slot)) return;
    aim = (slot: slot, shot: shot, stretch: stretch);
    notifyListeners();
  }

  void clearAim() {
    aim = null;
    notifyListeners();
  }

  void setMovePreview(int dx) {
    movePreviewDx = dx;
    notifyListeners();
  }

  /// 지금 [dx](1/10칸)를 누르면 실제로 갈 거리(1/1000칸). 시뮬레이션의 [moveReach].
  int reach(int dx) {
    final at = effectiveMs(state, turnMs);
    return moveReach(
      state.sides[state.activeSide],
      state.rules,
      state.turn,
      dx,
      state.rules.turnTimeFor(state.turn) - at,
    );
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
      if (p.isDone) _finishPlayback(p);
    }
    turnMs += dtMs;
    if (!isOver && playback == null) {
      if (isHumanTurn) {
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
    if (!canFire(slot)) return;
    _apply(FireCommand(t: turnMs, slot: slot, angle: angle, power: power));
  }

  void endTurn() {
    if (canAct) _apply(EndTurnCommand(t: turnMs));
  }

  void surrender() {
    if (!isOver && isHumanTurn) _apply(SurrenderCommand(t: turnMs));
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
    // 턴이 끝나도 이벤트 목록은 다음 턴 첫 커맨드 때 비워진다.
    final events = state.events.sublist(start.clamp(0, state.events.length));
    if (path != null && state.nextProjectileId > firedBefore) {
      playback = _shotPlayback(side, c as FireCommand, path, before!, events);
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

  ShotPlayback _shotPlayback(
    int side,
    FireCommand c,
    ShotPath path,
    List<GridSnapshot> before,
    List<SimEvent> events,
  ) {
    var shotPath = path;
    for (final e in events) {
      if (e.kind == SimEventKind.impact || e.kind == SimEventKind.splash) {
        shotPath = path.truncated(e.value, e.x, e.y);
        break;
      }
    }
    // 발사 이벤트는 바로(공격 동작·포성), 나머지는 착탄 때 낸다.
    _cues.addAll(events.where((e) => e.kind == SimEventKind.fire));
    return ShotPlayback(
      side: side,
      slot: c.slot,
      path: shotPath,
      before: before,
      landing: [
        for (final e in events)
          if (e.kind != SimEventKind.fire) e,
      ],
    );
  }

  void _finishPlayback(Playback p) {
    playback = null;
    if (p is ShotPlayback) _cues.addAll(p.landing);
    _syncTurnClock();
  }
}
