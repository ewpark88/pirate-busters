import 'package:pb_sim/pb_sim.dart';

/// 탄 하나의 틱별 월드 위치 (1/1000칸). 렌더와 궤적 미리보기용.
///
/// 시뮬레이션과 같은 발사 계산(`launchShot`)과 같은 적분(`Projectile.advance`)을
/// 쓰므로 그린 궤적이 판정과 어긋나지 않는다. 표적과의 충돌은 보지 않는다.
class ShotPath {
  ShotPath._(this.xs, this.ys);

  /// 발사 전 [state] 에서 [slot] 해적이 [ms](실제 시각)에 쏜 탄의 궤적.
  /// 해수면 아래로 내려가거나 수명이 다할 때까지 담는다. 어뢰(바라)는 물속으로
  /// 사라지는 깊이까지 담는다 (설계서 §4.8).
  factory ShotPath.predict(
    MatchState state, {
    required int slot,
    required int angle,
    required int power,
    required int ms,
  }) {
    final p = launchShot(state, slot: slot, angle: angle, power: power, ms: ms);
    // 실제 발사와 같은 탄종 준비(유도탄은 중력 없이 휘어 난다, A33).
    armShot(p, reachOf(state));
    final homing = p.spec.ammo == AmmoType.homing;
    final wind = state.wind * state.rules.windAccel;
    final xs = <int>[p.x];
    final ys = <int>[p.y];
    final floor = p.submerged ? -torpedoDepthLimit : 0;
    for (var tick = 1; !p.isExpired && p.y >= floor; tick++) {
      if (homing) steerHoming(state, p, msAfterTicks(ms, tick));
      p.advance(wind);
      xs.add(p.x);
      ys.add(p.y);
    }
    return ShotPath._(xs, ys);
  }

  /// 처음 닿는 곳(상대 배 또는 해수면)에서 끝나는 예측. 판정과 같은
  /// `pb_sim` 의 [predictFirstHit] 를 쓴다(렌더 전용, 분열탄 탭 대기).
  factory ShotPath.predictToHit(
    MatchState state, {
    required int slot,
    required int angle,
    required int power,
    required int ms,
  }) {
    final p = predictFirstHit(
      state,
      slot: slot,
      angle: angle,
      power: power,
      ms: ms,
    );
    return ShotPath._(p.xs, p.ys);
  }

  /// 틱 0(발사)부터의 위치.
  final List<int> xs;
  final List<int> ys;

  /// 마지막 틱 번호.
  int get lastTick => xs.length - 1;

  /// [ticks] 틱까지만 남기고 끝점을 ([endX], [endY]) 로 바꾼다(착탄·물보라 지점).
  ShotPath truncated(int ticks, int endX, int endY) {
    final n = ticks.clamp(1, lastTick);
    return ShotPath._(
      [...xs.sublist(0, n), endX],
      [...ys.sublist(0, n), endY],
    );
  }

  /// 앞 [percent]% 구간 (궤적 미리보기, 개발 계획서 M4).
  ShotPath head(int percent) {
    final n = (lastTick * percent ~/ 100).clamp(1, lastTick) + 1;
    return ShotPath._(xs.sublist(0, n), ys.sublist(0, n));
  }
}
