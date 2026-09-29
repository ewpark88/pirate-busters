import 'package:pb_sim/src/match/match_state.dart';
import 'package:pb_sim/src/match/rules.dart';
import 'package:pb_sim/src/ship/ship_grid.dart';
import 'package:pb_sim/src/world/world.dart';

/// 흘수선 아래 구멍이 얼마나 잠겼는지 (설계서 §2.5).
enum Submersion {
  /// 물 위.
  dry,

  /// 흘수선이 칸 안을 지난다.
  half,

  /// 칸 전체가 흘수선 아래.
  full,
}

/// 물이 새는 칸인가: ‘구멍’ 단계 블록이거나 부서진 칸 (설계서 §2.5, ADR-025).
bool isLeak(ShipGrid grid, int x, int y) =>
    grid.isBroken(x, y) || grid.stageAt(x, y) == DamageStage.holed;

/// 로컬 줄 [y] 가 잠긴 깊이 [draft](1/1000칸)에 얼마나 잠겼나.
Submersion submersionOf(int y, int draft) {
  final bottom = y * cellUnit;
  if (draft >= bottom + cellUnit) return Submersion.full;
  if (draft > bottom) return Submersion.half;
  return Submersion.dry;
}

/// [side] 배의 이번 턴 끝 침수 증가(0.1%p). 칸 인덱스 순으로 센다.
int floodGain(SideState side, MatchRules rules, int turn) {
  final grid = side.grid;
  final draft = side.draft;
  var gain = 0;
  for (var y = 0; y < grid.height; y++) {
    final sub = submersionOf(y, draft);
    if (sub == Submersion.dry) break;
    for (var x = 0; x < grid.width; x++) {
      if (!isLeak(grid, x, y)) continue;
      gain += sub == Submersion.full
          ? rules.floodFullCell
          : rules.floodHalfCell;
    }
  }
  // 폭풍 배율은 합계에 곱하고 버린다(값이 늘 0 이상이라 기기마다 같다, ADR-025).
  return rules.isStorm(turn) ? gain * rules.stormFloodPercent ~/ 100 : gain;
}

/// 턴 끝 침수 (설계서 §2.5): 침수량을 늘리고 늘어난 양을 돌려준다. 100% 에서 멈춘다.
int applyFlood(SideState side, MatchRules rules, int turn) {
  final before = side.flood;
  final after = before + floodGain(side, rules, turn);
  side.flood = after > fullFlood ? fullFlood : after;
  return side.flood - before;
}

/// 침수 기울기(밀리도, 뱃머리가 들리면 +) (설계서 §2.5, 임시 수치 ADR-025).
///
/// 물에 잠긴 새는 칸이 뱃머리 쪽 절반에 많으면 뱃머리가 내려간다. 차이 1칸당
/// [MatchRules.tiltPerCell], 최대 [MatchRules.maxTilt].
int floodTilt(SideState side, MatchRules rules) {
  final grid = side.grid;
  final draft = side.draft;
  final half = grid.width ~/ 2;
  var diff = 0;
  for (var y = 0; y < grid.height; y++) {
    if (submersionOf(y, draft) == Submersion.dry) break;
    for (var x = 0; x < grid.width; x++) {
      if (!isLeak(grid, x, y)) continue;
      diff += x >= half ? 1 : -1;
    }
  }
  final tilt = -diff * rules.tiltPerCell;
  if (tilt > rules.maxTilt) return rules.maxTilt;
  if (tilt < -rules.maxTilt) return -rules.maxTilt;
  return tilt;
}
