import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/battle/playback.dart';
import 'package:pirate_busters/battle/shot_path.dart';

/// 발사 연출을 만드는 계산 (판정은 모두 [Match] 가 한다).

/// [c] 가 분열탄 발사면 탭 없이 떨어질 때까지의 예측 경로, 아니면 null.
/// 발사 커맨드를 넣기 전 상태로 부른다.
ShotPath? splitPathFor(MatchState state, FireCommand c) {
  final pirate = state.sides[state.activeSide].crew.pirateAt(c.slot);
  if (pirate == null || pirate.spec.ammo != AmmoType.split) return null;
  return ShotPath.predictToHit(
    state,
    slot: c.slot,
    angle: c.angle,
    power: c.power,
    ms: realMs(state, effectiveMs(state, c.t)),
  );
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

/// 기다리던 분열탄 [p] 를 [tick] 틱에 갈라지게 `TAP` 으로 계산하고(null 이면
/// 탭 없이 안 갈라진 채), 같은 시각에서 계산된 경로로 잇는 연출을 돌려준다.
ShotPlayback resolveSplit(Match match, ShotPlayback p, int? tick) {
  final state = match.state;
  final start = state.events.length;
  if (tick == null) {
    match.settlePending();
  } else {
    match.apply(TapCommand(t: p.fireT, slot: p.slot, ticks: tick));
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
