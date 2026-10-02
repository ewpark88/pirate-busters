import 'package:pb_ai/src/scoring.dart';
import 'package:pb_sim/pb_sim.dart';

/// 후보 샷 하나 (설계서 §5.1).
class ShotPlan {
  const ShotPlan({
    required this.slot,
    required this.angle,
    required this.power,
    required this.tapTick,
    required this.value,
    required this.landings,
    this.tapDir = 0,
  });

  final int slot;
  final int angle;
  final int power;

  /// 분열탄·방향 전환 탭 틱(없으면 −1).
  final int tapTick;

  /// 방향 전환 탭 방향(알바: +1 위, −1 아래, ADR-075).
  final int tapDir;
  final ShotValue value;
  final List<ShotLanding> landings;
}

/// 후보 샷 격자: 각도 12 × 힘 8 = 96개 (BALANCE.md A5.1). 지원탄은 제 배에
/// 떨어지도록 거의 수직 각도를, 어뢰(바라)는 물속으로 들어가도록 아래 각도를 쓴다.
List<(int angle, int power)> candidateGrid(PirateSpec spec) {
  final support = spec.ammo == AmmoType.support;
  final torpedo = spec.ability == Ability.torpedo;
  int angle(int a) => support
      ? 78000 + a * 1000
      : (torpedo ? 336000 + a * 2000 : 10000 + a * 6000);
  return [
    for (var a = 0; a < 12; a++)
      for (var p = 0; p < 8; p++) (angle(a), 3000 + p * 1000),
  ];
}

/// 탭 시점 후보: 비행 25·50·75% (BALANCE.md A5.1).
const List<int> tapPercents = [25, 50, 75];

/// [slot] 해적이 ([angle], [power]) 로 [ms](실제 시각)에 쏘는 후보를 평가한다.
///
/// 바람은 [windPercent]% 만 계산에 넣는다(난이도 바람 보정, A5.5). 분열탄은 탭 없이와
/// 탭 시점 후보를 모두 보고 가장 좋은 것을 고른다. 매치 상태는 바뀌지 않는다.
ShotPlan evaluateShot(
  MatchState state, {
  required int slot,
  required int angle,
  required int power,
  required int ms,
  required int windPercent,
}) {
  final wind = state.wind;
  state.wind = wind * windPercent ~/ 100;
  try {
    final side = state.activeSide;
    final spec = state.sides[side].crew.pirates[slot].spec;
    ShotPlan plan(int tap, [int dir = 0]) {
      final landings = previewShot(
        state,
        slot: slot,
        angle: angle,
        power: power,
        ms: ms,
        tapTick: tap,
        tapDir: dir,
      );
      return ShotPlan(
        slot: slot,
        angle: angle,
        power: power,
        tapTick: tap,
        tapDir: dir,
        value: scoreLandings(state, side, landings),
        landings: landings,
      );
    }

    var best = plan(-1);
    final steer = spec.ability == Ability.steer;
    if ((spec.ammo != AmmoType.split && !steer) || best.landings.isEmpty) {
      return best;
    }
    final flight = best.landings.first.tick;
    for (final (pct, dir) in [
      for (final pct in tapPercents)
        for (final dir in steer ? const [1, -1] : const [0]) (pct, dir),
    ]) {
      final tick = flight * pct ~/ 100;
      if (tick < 1) continue;
      final p = plan(tick, dir);
      if (p.value.block + p.value.pirate + p.value.flood + p.value.module >
          best.value.block +
              best.value.pirate +
              best.value.flood +
              best.value.module) {
        best = p;
      }
    }
    return best;
  } finally {
    state.wind = wind;
  }
}
