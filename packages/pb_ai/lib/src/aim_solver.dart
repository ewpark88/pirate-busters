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
  });

  final int slot;
  final int angle;
  final int power;

  /// 분열탄 탭 틱(없으면 −1).
  final int tapTick;
  final ShotValue value;
  final List<ShotLanding> landings;
}

/// 후보 샷 격자: 각도 12 × 힘 8 = 96개 (BALANCE.md A5.1). 어뢰(바라)는 물속으로
/// 들어가도록 아래 각도를 쓴다.
List<(int angle, int power)> candidateGrid(PirateSpec spec) {
  final torpedo = spec.ability == Ability.torpedo;
  int angle(int a) => torpedo ? 336000 + a * 2000 : 10000 + a * 6000;
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
    ShotPlan plan(int tap) {
      final landings = previewShot(
        state,
        slot: slot,
        angle: angle,
        power: power,
        ms: ms,
        tapTick: tap,
      );
      return ShotPlan(
        slot: slot,
        angle: angle,
        power: power,
        tapTick: tap,
        value: scoreLandings(state, side, landings),
        landings: landings,
      );
    }

    int raw(ShotPlan p) => p.value.block + p.value.pirate + p.value.captain;
    var best = plan(-1);
    if (spec.ammo != AmmoType.split || best.landings.isEmpty) return best;
    final flight = best.landings.first.tick;
    for (final pct in tapPercents) {
      final tick = flight * pct ~/ 100;
      if (tick < 1) continue;
      final p = plan(tick);
      if (raw(p) > raw(best)) best = p;
    }
    return best;
  } finally {
    state.wind = wind;
  }
}
