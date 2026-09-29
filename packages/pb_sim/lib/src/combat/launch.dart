import 'package:pb_sim/src/match/match_state.dart';
import 'package:pb_sim/src/match/rules.dart';
import 'package:pb_sim/src/math/fx.dart';
import 'package:pb_sim/src/projectile/projectile.dart';
import 'package:pb_sim/src/ship/flooding.dart';
import 'package:pb_sim/src/world/wave.dart';
import 'package:pb_sim/src/world/world.dart';

/// 커맨드 시각 [t] 를 처리할 턴 시각(밀리초, 비행 정지 제외). 이동 중이면 이동이
/// 끝난 시각이다 (ADR-025).
int effectiveMs(MatchState state, int t) {
  final active = t - state.pausedMs;
  return active > state.busyUntilMs ? active : state.busyUntilMs;
}

/// 턴 시각 [effective] 의 실제 시각(비행 정지 포함). 파도 위상에 쓴다.
int realMs(MatchState state, int effective) => effective + state.pausedMs;

/// [side] 배의 [ms](실제 시각) 때 좌표 변환: 파도 위아래 흔들림 포함.
ShipFrame frameAtMs(MatchState state, int side, int ms) {
  final wave = Wave(state.rules, state.turn);
  return state.sides[side].frameAt(wave.heave(side, ms));
}

/// 지금 턴 진영의 [slot] 해적이 [ms](실제 시각)에 [angle]·[power] 로 쏜 탄.
///
/// 발사 위치는 파도에 흔들린 선실 중심, 각도에는 파도 기울기와 침수 기울기를
/// 더한다 (설계서 §2.5). 사람·AI·재생 모두 이 계산을 쓴다. 쏠 수 있는지(물에 잠긴
/// 선실 등)는 [SideState.canFire] 로 먼저 본다. 파도가 선실 중심을 잠깐 물 아래로
/// 내리면 해수면에서 쏜다.
Projectile launchShot(
  MatchState state, {
  required int slot,
  required int angle,
  required int power,
  required int ms,
  int id = 0,
}) {
  final active = state.activeSide;
  final side = state.sides[active];
  final wave = Wave(state.rules, state.turn);
  final cabin = side.cabins[slot];
  final frame = side.frameAt(wave.heave(active, ms));
  final (x, y) = frame.cellCenter(cabin.x, cabin.y);
  final tilt = wave.roll(active, ms) + floodTilt(side, state.rules);
  return Projectile.launch(
    id: id,
    side: active,
    slot: slot,
    spec: side.crew.pirates[slot].spec,
    x: x,
    y: y < 0 ? 0 : y,
    angle: angle + tilt,
    power: power,
  );
}

/// 발사 [ms] 로부터 [age] 틱 뒤의 실제 시각.
int msAfterTicks(int ms, int age) => ms + roundDiv(age * 1000, simTickHz);
