/// 월드 좌표 (개발 계획서 M2). 단위는 1/1000칸, 해수면이 y = 0 이다.
///
/// 왼쪽 배(진영 0)는 +x 쪽을, 오른쪽 배(진영 1)는 −x 쪽을 향한다. 설계도는 뱃머리가
/// +x 쪽인 로컬 격자로 짓고, 진영 1 은 좌우를 뒤집어 놓는다. 용골(y = 0 줄)은 M2 에서
/// 해수면에 닿아 있다. 흘수선은 M3 에서 붙인다.
library;

import 'package:pb_sim/src/match/rules.dart';

/// 1칸의 월드 단위.
const int cellUnit = 1000;

/// 판 시작 때 두 선체 끝(뱃머리) 사이 간격: 16칸 (설계서 §2.6).
const int startGap = 16 * cellUnit;

/// 배마다 시작 위치에서 전진·후퇴할 수 있는 거리: 4칸 (설계서 §2.6, 이동은 M3).
const int moveRange = 4 * cellUnit;

/// 중력: 36칸/초² → 틱당 속도 변화(1/1000칸/틱²). 최대 탄속 40칸/초와 함께, 45° 로
/// 30칸을 쏘면 약 1.3초 날아간다(ADR-010 임시 값).
const int gravityPerTick = 36 * cellUnit ~/ (simTickHz * simTickHz);

/// 투사체가 사라지는 월드 가로 경계(±60칸).
const int worldHalfWidth = 60 * cellUnit;

/// 투사체 최대 수명: 10초.
const int projectileMaxTicks = 10 * simTickHz;

/// 진영이 바라보는 방향: 진영 0 = +1, 진영 1 = −1.
int facingOf(int side) => side == 0 ? 1 : -1;

/// 진영의 시작 뱃머리 x.
int startBowX(int side) => -facingOf(side) * (startGap ~/ 2);

/// 내림 나눗셈 (음수도 −∞ 쪽으로).
int floorDiv(int n, int d) {
  final q = n ~/ d;
  return (n % d != 0 && (n < 0) != (d < 0)) ? q - 1 : q;
}

/// 뱃머리가 [bowX] 이고 폭이 [width] 칸인 [side] 배의 좌표 변환.
///
/// 로컬 좌표는 선미 끝이 x = 0, 뱃머리 끝이 x = width × [cellUnit] 이다.
class ShipFrame {
  const ShipFrame({
    required this.side,
    required this.bowX,
    required this.width,
  });

  final int side;
  final int bowX;
  final int width;

  int get _sternToBow => width * cellUnit;

  /// 월드 x → 로컬 x.
  int toLocalX(int worldX) {
    final facing = facingOf(side);
    return _sternToBow - facing * (bowX - worldX);
  }

  /// 로컬 x → 월드 x.
  int toWorldX(int localX) {
    final facing = facingOf(side);
    return bowX - facing * (_sternToBow - localX);
  }

  /// 로컬 칸 ([cx], [cy]) 중심의 월드 좌표 (x, y).
  (int, int) cellCenter(int cx, int cy) => (
    toWorldX(cx * cellUnit + cellUnit ~/ 2),
    cy * cellUnit + cellUnit ~/ 2,
  );
}
