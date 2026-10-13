import 'package:pb_sim/pb_sim.dart';
import 'package:pb_sim/src/combat/ammo_rules.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

/// 연사 해적: 직사 일반, 3발.
PirateSpec _burst({required int pattern, int spread = 12000, int count = 3}) =>
    PirateSpec(
      id: 'b',
      rarity: Rarity.common,
      hp: 220,
      blockDamage: 60,
      pirateDamage: 100,
      family: Family.direct,
      ammo: AmmoType.burst,
      ammoValue: count,
      spreadMdeg: spread,
      ammoParam: pattern,
    );

Match _match(PirateSpec spec, {int seed = 5}) {
  return Match.start(
    seed: seed,
    rules: const MatchRules(calmSea: true),
    blueprints: [sampleBlueprint(), sampleBlueprint()],
    decks: [
      [spec.id, 'r0'],
      [spec.id, 'r1'],
    ],
    costLimits: const [15, 15],
    pirates: PirateCatalog([spec, testPirate('r0'), testPirate('r1')]),
  )..apply(const TapCommand(t: 0, slot: 9, ticks: 0));
}

/// 지금 턴 진영 0번 해적의 연사 한 번: 발마다 (vx, vy).
List<(int, int)> _volley(Match m) => [
  for (final p in launchVolley(
    m.state,
    slot: 0,
    angle: 40000,
    power: 8000,
    ms: 1000,
  ))
    (p.vx, p.vy),
];

int _speed2((int, int) v) => v.$1 * v.$1 + v.$2 * v.$2;

void main() {
  group('A52 연사 집중·산발 (설계서 §4.8, ADR-102)', () {
    test('집중 연사는 퍼짐 각이 있어도 모든 발이 같은 각도·세기로 난다', () {
      final shots = _volley(_match(_burst(pattern: burstFocus)));
      expect(shots, hasLength(3));
      expect(shots.toSet(), hasLength(1));
    });

    test('산발 연사는 발마다 흩어지고, 같은 시드면 똑같이 흩어진다', () {
      final a = _volley(_match(_burst(pattern: burstScatter, count: 12)));
      final b = _volley(_match(_burst(pattern: burstScatter, count: 12)));
      expect(a, b);
      expect(a.toSet().length, greaterThan(6));
    });

    test('산발 세기 흔들림은 ±8% 를 넘지 않는다 (BALANCE.md A4.8)', () {
      final base = _speed2(
        _volley(_match(_burst(pattern: burstFocus))).first,
      );
      final shots = _volley(_match(_burst(pattern: burstScatter, count: 20)));
      for (final v in shots) {
        // 속도² 비율이 (0.92 − 여유)² ~ (1.08 + 여유)² 안.
        expect(_speed2(v) * 10000, lessThanOrEqualTo(base * 11700));
        expect(_speed2(v) * 10000, greaterThanOrEqualTo(base * 8400));
      }
    });

    test('산발 연사가 낀 판도 같은 시드·커맨드면 해시가 같다', () {
      int run() {
        final m = _match(_burst(pattern: burstScatter, count: 12), seed: 9)
          ..apply(
            const FireCommand(t: 500, slot: 0, angle: 30000, power: 9000),
          )
          ..apply(const EndTurnCommand(t: 900));
        return hashMatchState(m.state);
      }

      expect(run(), run());
    });
  });
}
