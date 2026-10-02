import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/battle/playback.dart';
import 'package:pirate_busters/battle/shot_path.dart';

/// 발사 연출을 만드는 계산 (판정은 모두 [Match] 가 한다).

/// [c] 가 비행 중 탭을 기다리는 발사(분열탄·방향 전환 탄, 설계서 §4.8)면 탭 없이
/// 떨어질 때까지의 예측 경로, 아니면 null. 발사 커맨드를 넣기 전 상태로 부른다.
ShotPath? splitPathFor(MatchState state, FireCommand c) {
  final pirate = state.sides[state.activeSide].crew.pirateAt(c.slot);
  if (pirate == null) return null;
  final spec = pirate.spec;
  if (spec.ammo != AmmoType.split && spec.ability != Ability.steer) {
    return null;
  }
  return ShotPath.predictToHit(
    state,
    slot: c.slot,
    angle: c.angle,
    power: c.power,
    ms: realMs(state, effectiveMs(state, c.t)),
  );
}

/// 이번 커맨드로 생길 이벤트가 [MatchState.events] 의 어디부터인지. 턴의 첫
/// 커맨드면 목록이 새로 시작된다.
int eventsStartFor(MatchState state, int turn) {
  final events = state.events;
  final begun =
      events.isNotEmpty &&
      events.first.kind == SimEventKind.turnStart &&
      events.first.value == turn;
  return begun ? events.length : 0;
}

/// 컴퓨터 턴 묶음에서 [index] 의 발사 바로 뒤가 같은 해적의 `TAP` 이면 그 탭.
TapCommand? followingTap(TurnBundle bundle, int index) {
  final c = bundle.commands[index];
  if (c is! FireCommand || index + 1 >= bundle.commands.length) return null;
  final next = bundle.commands[index + 1];
  return next is TapCommand && next.slot == c.slot ? next : null;
}

/// 계산이 끝난 발사 연출: 이벤트 [start] 번째부터가 이번 발사의 결과다.
ShotPlayback resolvedShot(
  MatchState state, {
  required int side,
  required int slot,
  required int fireT,
  required List<GridSnapshot> before,
  required int start,
  int elapsedMs = 0,
}) => ShotPlayback.resolved(
  side: side,
  slot: slot,
  fireT: fireT,
  traces: state.lastTraces,
  before: before,
  events: state.events.sublist(start.clamp(0, state.events.length)),
  breakPauseMs: state.rules.breakPauseMs,
  elapsedMs: elapsedMs,
);

/// 기다리던 탄 [p] 를 [tick] 틱에 `TAP`([dir] 은 방향 전환 쪽)으로 계산하고(null
/// 이면 탭 없이), 같은 시각에서 계산된 경로로 잇는 연출을 돌려준다.
ShotPlayback resolveSplit(
  Match match,
  ShotPlayback p,
  int? tick, {
  int dir = 0,
}) {
  final state = match.state;
  final start = state.events.length;
  if (tick == null) {
    match.settlePending();
  } else {
    match.apply(TapCommand(t: p.fireT, slot: p.slot, ticks: tick, dir: dir));
  }
  return resolvedShot(
    state,
    side: p.side,
    slot: p.slot,
    fireT: p.fireT,
    before: p.before,
    start: start,
    elapsedMs: p.elapsedMs,
  );
}
