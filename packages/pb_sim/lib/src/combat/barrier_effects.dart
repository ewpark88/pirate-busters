import 'package:pb_sim/src/match/barrier.dart';
import 'package:pb_sim/src/match/match_state.dart';
import 'package:pb_sim/src/match/sim_event.dart';
import 'package:pb_sim/src/projectile/projectile.dart';
import 'package:pb_sim/src/world/world.dart';

/// 산호 방벽 높이: 해수면에서 4칸 (BALANCE.md A4.2 코리, 임시값 ADR-078).
const int coralHeight = 4 * cellUnit;

/// 산호 방벽 기본 내구도 (지원 배율을 곱한다, BALANCE.md A4.2, 임시값 ADR-078).
const int coralBaseHp = 120;

/// 코리: 지원탄이 닿은 월드 [x] 에 산호 방벽을 세운다 (설계서 §4.2, ADR-078).
void placeCoral(MatchState state, Projectile p, int x) {
  final spec = p.spec;
  final hp = coralBaseHp * spec.ammoValue ~/ 100;
  state.barriers.add(
    Barrier(
      owner: p.side,
      x: x,
      top: coralHeight,
      hp: hp,
      turnsLeft: spec.abilityValue,
    ),
  );
  state.events.add(
    SimEvent(SimEventKind.barrierPlaced, side: p.side, x: x, value: hp),
  );
}

/// 탄 [p] 가 ([x0], [y0]) → ([x1], [y1]) 로 가며 처음 지나는 상대 방벽. 없으면 null.
/// 방벽 x 를 지날 때의 높이가 해수면(0)~꼭대기 안이어야 한다. 가까운 것부터.
Barrier? barrierCrossed(
  MatchState state,
  Projectile p,
  int x0,
  int y0,
  int x1,
  int y1,
) {
  Barrier? best;
  var bestD = 0;
  for (final b in state.barriers) {
    if (b.owner == p.side || x1 == x0) continue;
    final before = x0 - b.x;
    final after = x1 - b.x;
    if (before != 0 && (before > 0) == (after > 0) && after != 0) continue;
    final y = y0 + (y1 - y0) * (b.x - x0) ~/ (x1 - x0);
    if (y < 0 || y > b.top) continue;
    final d = before.abs();
    if (best == null || d < bestD) {
      best = b;
      bestD = d;
    }
  }
  return best;
}

/// 방벽 [b] 가 탄 [p] 를 발사 뒤 [tick] 틱에 막는다: 탄의 블록 피해만큼 깎이고
/// 0 이하면 무너진다.
void hitBarrier(MatchState state, Projectile p, Barrier b, {int tick = 0}) {
  b.hp -= p.spec.blockDamage;
  state.events.add(
    SimEvent(
      SimEventKind.barrierHit,
      side: b.owner,
      x: b.x,
      y: b.hp < 0 ? 0 : b.hp,
      value: tick,
    ),
  );
  if (b.hp <= 0) state.barriers.remove(b);
}

/// 지금 턴 진영이 세운 방벽의 남은 턴을 1 줄이고 0 이 된 것을 없앤다(턴 시작).
void expireBarriers(MatchState state) {
  final side = state.activeSide;
  for (final b in state.barriers) {
    if (b.owner == side) b.turnsLeft--;
  }
  state.barriers.removeWhere((b) => b.turnsLeft <= 0);
}
