import 'package:pb_sim/src/match/match_state.dart';
import 'package:pb_sim/src/match/rules.dart';
import 'package:pb_sim/src/ship/module_state.dart';
import 'package:pb_sim/src/world/world.dart';

/// 이동 단위: 1/10칸 (설계서 §7.2 MOVE 커맨드의 dx).
const int moveStep = cellUnit ~/ 10;

/// 배가 [turn] 에 갈 수 있는 위치 범위(시작 위치 기준, 1/1000칸).
/// 폭풍 타임에는 후퇴 한계가 당겨진다 (설계서 §2.6).
(int, int) moveLimits(MatchRules rules, int turn) {
  final pull = rules.isStorm(turn) ? rules.stormRetreatPull : 0;
  return (-moveRange + pull, moveRange);
}

/// 이동 속도(1/1000칸/초): 선형 속도 × (1 − 침수량 × 0.6), 돛대가 부러지면 절반
/// (설계서 §2.6).
int moveSpeedOf(SideState side) {
  final factor = 1000 - side.flood * 600 ~/ fullFlood;
  final speed = side.grid.hull.moveSpeed * factor ~/ 1000;
  return side.mastBroken
      ? speed * ModuleNumbers.mastSpeedPercent ~/ 100
      : speed;
}

/// 이동 한 번의 결과.
class MoveResult {
  const MoveResult(this.distance, this.durationMs);

  /// 실제로 움직인 거리(1/1000칸, 전진 +).
  final int distance;

  /// 걸린 턴 시간(밀리초).
  final int durationMs;
}

/// [side] 배가 [dx](1/10칸, 전진 +)를 누르면 실제로 갈 거리(1/1000칸, 전진 +).
///
/// 한계선, 연료, 남은 턴 시간 [timeLeftMs] 중 먼저 닿는 곳까지다 (설계서 §2.6, §2.7).
/// 이동 불가 상태면 0 이다.
/// 상태는 바꾸지 않는다. 이동 버튼의 끝 지점 점선도 이 값을 쓴다.
int moveReach(
  SideState side,
  MatchRules rules,
  int turn,
  int dx,
  int timeLeftMs,
) {
  final speed = moveSpeedOf(side);
  // 끌려온 배는 다음 턴에 움직이지 못한다(모비, 설계서 §4.8).
  if (side.moveLocked) return 0;
  if (dx == 0 || speed <= 0 || timeLeftMs <= 0) return 0;
  final (lo, hi) = moveLimits(rules, turn);
  final want = dx * moveStep;
  final target = (side.offset + want).clamp(lo, hi);
  var dist = (target - side.offset).abs();
  final byFuel = side.fuel * cellUnit ~/ side.fuelPerCell;
  final byTime = timeLeftMs * speed ~/ 1000;
  if (byFuel < dist) dist = byFuel;
  if (byTime < dist) dist = byTime;
  dist -= dist % moveStep;
  if (dist <= 0) return 0;
  return want > 0 ? dist : -dist;
}

/// [side] 배를 [dx](1/10칸, 전진 +)만큼 움직인다 (설계서 §2.6, §2.7).
///
/// [moveReach] 만큼만 가고, 간 거리만큼 연료를 쓴다. 한계선에 막혀 못 간 거리는
/// 연료를 쓰지 않는다.
MoveResult applyMove(
  SideState side,
  MatchRules rules,
  int turn,
  int dx,
  int timeLeftMs,
) {
  final signed = moveReach(side, rules, turn, dx, timeLeftMs);
  if (signed == 0) return const MoveResult(0, 0);
  final dist = signed.abs();
  final speed = moveSpeedOf(side);
  side
    ..offset += signed
    ..fuel -= dist * side.fuelPerCell ~/ cellUnit;
  // 한계선 앞 감속 구간은 절반 속도: 그 구간을 지난 거리만큼 시간을 한 번 더 센다.
  final (lo, hi) = moveLimits(rules, turn);
  final limit = signed > 0 ? hi : lo;
  final zoneStart = signed > 0
      ? limit - rules.limitSlowZone
      : limit + rules.limitSlowZone;
  final from = side.offset - signed;
  final inZone = signed > 0
      ? _overlap(from, side.offset, zoneStart, limit)
      : _overlap(side.offset, from, limit, zoneStart);
  final ms = ((dist + inZone) * 1000 + speed - 1) ~/ speed;
  return MoveResult(signed, ms);
}

/// 연료를 [amount] 채운다(탱크 상한까지).
void refuel(SideState side, int amount) {
  final tank = side.tank;
  final next = side.fuel + amount * SideState.fuelUnit;
  side.fuel = next > tank ? tank : next;
}

/// 폭풍 타임 시작 (설계서 §2.4, §2.6, §2.7): 연료를 채우고, 당겨진 후퇴 한계 밖에
/// 있는 배는 한계선으로 옮긴다(연료·시간 없이). 옮긴 거리(전진 +)를 돌려준다.
int startStorm(SideState side, MatchRules rules, int turn) {
  refuel(side, rules.stormFuel);
  final (lo, _) = moveLimits(rules, turn);
  if (side.offset >= lo) return 0;
  final moved = lo - side.offset;
  side.offset = lo;
  return moved;
}

/// 구간 [a1, a2] 와 [b1, b2] 가 겹치는 길이.
int _overlap(int a1, int a2, int b1, int b2) {
  final lo = a1 > b1 ? a1 : b1;
  final hi = a2 < b2 ? a2 : b2;
  return hi > lo ? hi - lo : 0;
}
