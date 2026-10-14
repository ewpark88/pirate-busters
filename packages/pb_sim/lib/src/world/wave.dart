import 'package:pb_sim/src/match/match_state.dart';
import 'package:pb_sim/src/math/fx.dart';
import 'package:pb_sim/src/math/trig.dart';
import 'package:pb_sim/src/world/world.dart';

/// 월드 x [x](1/1000칸)가 속한 파도 구간 번호: 가운데에서 떨어진 정도 (설계서 §2.6).
/// 좌우 대칭이다. 바깥 구간 너머는 마지막 구간으로 본다.
int waveZoneIndex(MatchState state, int x) => zoneIndexAt(
  x,
  width: state.rules.waveZoneWidth,
  zones: state.waveZones.length,
);

/// 폭 [width] 인 구간 [zones] 개에서 x [x] 가 속한 구간 번호(가운데에서 떨어진 정도).
/// 화면도 같은 나눔을 쓴다.
int zoneIndexAt(int x, {required int width, required int zones}) {
  final i = x.abs() ~/ width;
  return i >= zones ? zones - 1 : i;
}

/// [side] 배가 선 자리의 파도 세기(0~3): 뱃머리 칸이 선 구간의 세기 (BALANCE.md A2.5).
int waveLevelOf(MatchState state, int side) {
  final s = state.sides[side];
  final bowCell = s.bowX - facingOf(side) * (cellUnit ~/ 2);
  return state.waveZones[waveZoneIndex(state, bowCell)];
}

/// 파도 흔들림 (설계서 §2.6).
///
/// 배는 자기가 선 파도 구간의 세기만큼 계속 흔들린다. 주기는 고정이라 놓는 순간을
/// 고르는 것이 조준 실력이 된다. 위상은 턴 시작 기준 실제 시각(밀리초, 비행 정지
/// 포함)으로 정하고, 오른쪽 배는 반주기 어긋난다. 정수 사인 테이블만 쓴다.
class Wave {
  const Wave(this.state);

  final MatchState state;

  int _phase(int side, int ms) {
    final period = state.rules.wavePeriodMs;
    final t = (ms + side * (period ~/ 2)) % period;
    return t * fullTurnMdeg ~/ period;
  }

  /// [side] 배의 위아래 흔들림(1/1000칸, 위가 +) — 턴 시작 후 [ms] 밀리초.
  int heave(int side, int ms) {
    final amp = waveLevelOf(state, side) * state.rules.waveHeavePerLevel;
    return roundDiv(amp * sinMicro(_phase(side, ms)), trigScale);
  }

  /// [side] 배의 기울기(밀리도, 뱃머리가 들리면 +) — 턴 시작 후 [ms] 밀리초.
  int roll(int side, int ms) {
    final amp = waveLevelOf(state, side) * state.rules.waveRollPerLevel;
    return roundDiv(amp * cosMicro(_phase(side, ms)), trigScale);
  }
}
