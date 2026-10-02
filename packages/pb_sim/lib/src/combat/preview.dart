import 'package:pb_sim/src/combat/ammo_rules.dart';
import 'package:pb_sim/src/combat/volley.dart';
import 'package:pb_sim/src/match/match_state.dart';
import 'package:pb_sim/src/pirate/pirate_spec.dart';

/// 미리 계산한 탄 하나가 처음 닿는 곳.
class ShotLanding {
  const ShotLanding({
    required this.side,
    required this.cx,
    required this.cy,
    required this.x,
    required this.tick,
    required this.spec,
    required this.bounced,
  });

  /// 닿은 배(또는 떨어진 바다)의 진영.
  final int side;

  /// 맞은 배 로컬 칸. 바다면 −1.
  final int cx;
  final int cy;

  /// 월드 x (바다에 떨어진 곳 포함).
  final int x;

  /// 발사부터의 틱.
  final int tick;

  /// 그 탄의 정의(여러 발이면 나눈 피해).
  final PirateSpec spec;

  /// 물수제비로 튕긴 뒤 닿았다(흘수선 명중 ×1.5, §4.3).
  final bool bounced;

  bool get hitShip => cx >= 0;
}

/// 지금 턴 진영의 [slot] 해적이 쏘면 탄마다 어디에 먼저 닿는지 미리 계산한다
/// (설계서 §5.1: AI 조준 솔버). 판정과 같은 발사·비행 계산이고, 효과는 내지 않는다.
/// 쓰는 난수와 투사체 id 는 끝나면 되돌리므로 매치 상태는 바뀌지 않는다.
/// [tapTick] 은 분열탄이 갈라지거나 방향 전환 탄이 꺾일 틱(없으면 −1), [tapDir] 은
/// 방향 전환 방향(ADR-075).
List<ShotLanding> previewShot(
  MatchState state, {
  required int slot,
  required int angle,
  required int power,
  required int ms,
  int tapTick = -1,
  int tapDir = 0,
}) {
  final rng = state.rng.state;
  final nextId = state.nextProjectileId;
  final out = <ShotLanding>[];
  try {
    final shots = launchVolley(
      state,
      slot: slot,
      angle: angle,
      power: power,
      ms: ms,
    );
    runVolley(
      state,
      shots,
      ms,
      tapTick: tapTick,
      tapDir: tapDir,
      dry: (p, step, tick) {
        final hit = step.hit;
        out.add(
          ShotLanding(
            side: step.target.side,
            cx: hit?.cx ?? -1,
            cy: hit?.cy ?? -1,
            x: step.x,
            tick: tick,
            spec: p.spec,
            bounced: p.bounced,
          ),
        );
      },
    );
  } finally {
    state.rng.restore(rng);
    state.nextProjectileId = nextId;
  }
  return out;
}
