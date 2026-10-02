import 'package:pb_sim/src/combat/ability_effects.dart';
import 'package:pb_sim/src/combat/ammo_rules.dart';
import 'package:pb_sim/src/combat/flight.dart';
import 'package:pb_sim/src/combat/hit_effects.dart';
import 'package:pb_sim/src/combat/launch.dart';
import 'package:pb_sim/src/match/match_state.dart';
import 'package:pb_sim/src/match/sim_event.dart';
import 'package:pb_sim/src/pirate/ammo.dart';
import 'package:pb_sim/src/projectile/projectile.dart';
import 'package:pb_sim/src/projectile/shot_trace.dart';

/// 한 번의 발사(또는 턴 효과)로 난 탄들을 모두 떨어질 때까지 진행하고 마지막 틱을
/// 돌려준다 (설계서 §7.1: 엔티티는 id 순으로 갱신).
///
/// 틱마다 id 순으로 탄을 한 틱씩 옮긴다. 연사탄 뒤 발은 [Projectile.startTick] 이
/// 지나야 난다. 분열탄은 [tapTick] 틱에 조각으로 갈라지고(TAP, 설계서 §4.8),
/// 다중투하는 꼭대기에서 폭탄으로 갈라진다. 방향 전환 탄은 [tapTick] 틱에 [tapDir]
/// 쪽으로 꺾인다(ADR-075). 경로는 [MatchState.lastTraces] 에 남긴다
/// (렌더 전용, 해시 밖).
///
/// [dry] 가 있으면 미리 계산만 한다: 효과·이벤트·경로 기록 없이 탄마다 처음 닿는
/// 곳을 [dry] 로 알리고 그 탄을 끝낸다(물수제비 튕김·갈라짐·유도는 그대로 따른다).
int runVolley(
  MatchState state,
  List<Projectile> shots,
  int ms, {
  int tapTick = -1,
  int tapDir = 0,
  void Function(Projectile p, TraceStep step, int tick)? dry,
}) {
  final wind = state.wind * state.rules.windAccel;
  final live = <Projectile>[...shots];
  final done = <bool>[for (final _ in shots) false];
  final traces = <ShotTrace>[
    for (final p in shots)
      ShotTrace(id: p.id, startTick: p.startTick)..add(p.x, p.y),
  ];
  var last = 0;
  for (var tick = 1; ; tick++) {
    var flying = false;
    // 이번 틱에 새로 생긴 탄은 다음 틱부터 난다.
    final n = live.length;
    for (var i = 0; i < n; i++) {
      if (done[i]) continue;
      final p = live[i];
      flying = true;
      if (tick <= p.startTick) continue;
      // 방향 전환 탭(알바, §4.8): 이 틱을 날기 전에 꺾는다.
      if (tick == tapTick && dry == null) steerOnTap(state, p, tapDir, tick);
      final at = msAfterTicks(ms, tick);
      if (p.spec.ammo == AmmoType.homing) steerHoming(state, p, at);
      final vyBefore = p.vy;
      if (dry != null) {
        final step = traceStep(state, p, wind, ms, tick);
        final net = step.hit;
        if (net != null && passNet(p, step.target, net.cx, net.cy)) continue;
        final bounced = step.hit == null && step.sea && bounceOffSea(p, step.x);
        if (step.hit != null || (step.sea && !bounced) || p.isExpired) {
          if (step.hit != null || step.sea) dry(p, step, tick);
          done[i] = true;
          continue;
        }
        final kids = _divideAt(state, p, tick, vyBefore, tapTick);
        if (kids.isNotEmpty) _replace(state, live, done, traces, i, kids);
        continue;
      }
      if (stepShot(state, p, wind, ms, tick)) {
        done[i] = true;
        traces[i].add(p.x, p.y < 0 ? 0 : p.y);
        last = tick;
        continue;
      }
      traces[i].add(p.x, p.y);
      final children = _divideAt(state, p, tick, vyBefore, tapTick);
      if (children.isNotEmpty) {
        _replace(state, live, done, traces, i, children);
        state.events.add(
          SimEvent(
            SimEventKind.divide,
            side: p.side,
            slot: p.slot,
            x: p.x,
            y: p.y,
            value: tick,
          ),
        );
      }
    }
    if (!flying) break;
  }
  if (dry == null) state.lastTraces = [...state.lastTraces, ...traces];
  return last;
}

/// 이번 틱에 갈라지면 조각들, 아니면 빈 목록. 분열탄은 [tapTick] 에, 다중투하는
/// 올라가다 내려가기 시작할 때(꼭대기) 한 번만 갈라진다.
List<Projectile> _divideAt(
  MatchState state,
  Projectile p,
  int tick,
  int vyBefore,
  int tapTick,
) {
  if (p.divided) return const [];
  return switch (p.spec.ammo) {
    AmmoType.split when tick == tapTick => splitFragments(state, p, tick),
    AmmoType.flock when p.spec.ammoParam == 0 && vyBefore > 0 && p.vy <= 0 =>
      flockBombs(state, p, tick),
    _ => const [],
  };
}

/// [i] 번째 탄을 끝내고 [children] 을 뒤에 붙인다(더 큰 id 라 순서가 유지된다).
void _replace(
  MatchState state,
  List<Projectile> live,
  List<bool> done,
  List<ShotTrace> traces,
  int i,
  List<Projectile> children,
) {
  done[i] = true;
  for (final c in children) {
    live.add(c);
    done.add(false);
    traces.add(ShotTrace(id: c.id, startTick: c.startTick)..add(c.x, c.y));
  }
}

/// 한 번의 발사로 난 탄들과 발사 시각(실제 시각). 분열탄은 TAP 을 기다리는 동안
/// 이 상태로 남는다.
class Volley {
  Volley(this.shots, this.ms);

  final List<Projectile> shots;
  final int ms;
}
