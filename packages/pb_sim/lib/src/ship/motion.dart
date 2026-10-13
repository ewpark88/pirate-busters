import 'package:pb_sim/src/match/match_state.dart';
import 'package:pb_sim/src/match/rules.dart';
import 'package:pb_sim/src/world/world.dart';

/// 이동 단위: 1/10칸 (설계서 §7.2 MOVE 커맨드의 dx).
const int moveStep = cellUnit ~/ 10;

/// [me] 배가 지금 갈 수 있는 위치 범위(시작 위치 기준 전진 거리, 1/1000칸).
///
/// 바다 전체를 움직이고 가운데 선은 없다(설계서 §2.5). 뒤로는 바다 끝(시작 위치에서
/// [MatchRules.backRoom])까지, 앞으로는 상대 뱃머리와 [MatchRules.minGap] 간격까지다.
(int, int) moveLimits(SideState me, SideState other, MatchRules rules) {
  final gap = (me.bowX - other.bowX).abs();
  final forward = me.offset + gap - rules.minGap;
  return (-rules.backRoom, forward);
}

/// 이동 속도(1/1000칸/초): 선형 속도 (설계서 §2.5, 연출과 턴 시간에만 영향).
int moveSpeedOf(SideState side) => side.grid.hull.moveSpeed;

/// 이동 한 번의 결과.
class MoveResult {
  const MoveResult(this.distance, this.durationMs);

  /// 실제로 움직인 거리(1/1000칸, 전진 +).
  final int distance;

  /// 걸린 턴 시간(밀리초).
  final int durationMs;
}

/// [me] 배가 [dx](1/10칸, 전진 +)를 누르면 실제로 갈 거리(1/1000칸, 전진 +).
///
/// 한계, 연료, 남은 턴 시간 [timeLeftMs] 중 먼저 닿는 곳까지다 (설계서 §2.5).
/// 상태는 바꾸지 않는다. 이동 버튼의 끝 지점 점선도 이 값을 쓴다.
int moveReach(
  SideState me,
  SideState other,
  MatchRules rules,
  int dx,
  int timeLeftMs,
) {
  final speed = moveSpeedOf(me);
  if (dx == 0 || speed <= 0 || timeLeftMs <= 0) return 0;
  final (lo, hi) = moveLimits(me, other, rules);
  final want = dx * moveStep;
  final target = (me.offset + want).clamp(lo, hi < lo ? lo : hi);
  var dist = (target - me.offset).abs();
  final byFuel = me.fuel * cellUnit ~/ me.fuelPerCell;
  final byTime = timeLeftMs * speed ~/ 1000;
  if (byFuel < dist) dist = byFuel;
  if (byTime < dist) dist = byTime;
  dist -= dist % moveStep;
  if (dist <= 0) return 0;
  return want > 0 ? dist : -dist;
}

/// [me] 배를 [dx](1/10칸, 전진 +)만큼 움직인다 (설계서 §2.5).
///
/// [moveReach] 만큼만 가고, 간 거리만큼 연료를 쓴다. 막혀서 못 간 거리는 연료를 쓰지
/// 않는다. 한계 앞 감속 구간은 절반 속도라 그만큼 턴 시간을 더 쓴다.
MoveResult applyMove(
  SideState me,
  SideState other,
  MatchRules rules,
  int dx,
  int timeLeftMs,
) {
  final signed = moveReach(me, other, rules, dx, timeLeftMs);
  if (signed == 0) return const MoveResult(0, 0);
  final (lo, hi) = moveLimits(me, other, rules);
  final dist = signed.abs();
  final speed = moveSpeedOf(me);
  me
    ..offset += signed
    ..fuel -= fuelFor(me, dist);
  final limit = signed > 0 ? hi : lo;
  final zoneStart = signed > 0
      ? limit - rules.limitSlowZone
      : limit + rules.limitSlowZone;
  final from = me.offset - signed;
  final inZone = signed > 0
      ? _overlap(from, me.offset, zoneStart, limit)
      : _overlap(me.offset, from, limit, zoneStart);
  final ms = ((dist + inZone) * 1000 + speed - 1) ~/ speed;
  return MoveResult(signed, ms);
}

/// [side] 배가 [dist](1/1000칸)를 갈 때 쓰는 연료(×[SideState.fuelUnit]).
/// 이동 버튼의 남을 연료 미리보기도 이 값을 쓴다.
int fuelFor(SideState side, int dist) =>
    dist.abs() * side.fuelPerCell ~/ cellUnit;

/// [ship] 을 연료 없이 [dist](1/1000칸, 그 배 기준 전진 +)만큼 옮긴다: 충격탄·오르카가
/// 밀고 모비가 끈다 (설계서 §4.8). 바다 끝과 최소 간격에서 멈춘다. 실제로 움직인
/// 거리를 돌려준다.
int shoveShip(SideState ship, SideState other, MatchRules rules, int dist) {
  final (lo, hi) = moveLimits(ship, other, rules);
  final to = (ship.offset + dist).clamp(lo, hi < lo ? lo : hi);
  final moved = to - ship.offset;
  ship.offset = to;
  return moved;
}

/// 연료를 가득 채운다 (설계서 §2.5: 내 턴이 시작될 때).
void refillFuel(SideState side) => side.fuel = side.tank;

/// 구간 [a1, a2] 와 [b1, b2] 가 겹치는 길이.
int _overlap(int a1, int a2, int b1, int b2) {
  final lo = a1 > b1 ? a1 : b1;
  final hi = a2 < b2 ? a2 : b2;
  return hi > lo ? hi - lo : 0;
}
