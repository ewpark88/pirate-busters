import 'package:pb_sim/pb_sim.dart';
import 'package:pb_sim/src/combat/hit_effects.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

/// 물수제비 해적 (튕김 [value]회).
PirateSpec _skip({int value = 2}) => PirateSpec(
  id: 's',
  rarity: Rarity.common,
  hp: 240,
  cooldownTurns: 0,
  blockDamage: 30,
  pirateDamage: 60,
  family: Family.skip,
  ammo: AmmoType.skip,
  ammoValue: value,
  range: RangeGrade.long,
);

/// 수면에 ([vx], [vy]) 로 닿는 물수제비탄.
Projectile _shot(int vx, int vy, {int bounces = 2, int value = 2}) =>
    Projectile(
      id: 1,
      side: 0,
      slot: 0,
      spec: _skip(value: value),
      x: 0,
      y: 0,
      vx: vx,
      vy: vy,
    )..bouncesLeft = bounces;

void main() {
  group('A51 물수제비 튕김 조건 (설계서 §4.8, BALANCE.md A4.8, ADR-102)', () {
    test('가파르게 떨어진 물수제비탄은 튕기지 않는다', () {
      // 세로 속도가 가로 × 0.466 을 넘는다(25° 보다 가파름).
      final p = _shot(10000, -4700);
      expect(bounceOffSea(p, 0), isFalse);
      expect(p.bouncesLeft, 2);
      expect(p.bounced, isFalse);
    });

    test('얕게 닿으면 튕기고 세로 ×0.45·가로 ×0.70 으로 줄어든다', () {
      final p = _shot(10000, -4600);
      expect(bounceOffSea(p, 0), isTrue);
      expect(p.bouncesLeft, 1);
      expect(p.vy, 4600 * skipBounceVyPercent ~/ 100);
      expect(p.vx, 10000 * skipBounceVxPercent ~/ 100);
    });

    test('튕김이 남지 않으면 얕아도 튕기지 않는다', () {
      expect(bounceOffSea(_shot(10000, -1000, bounces: 0), 0), isFalse);
    });

    test('멀면 튕김 수가 하나 줄고, 1회 해적은 1회를 지킨다 (§2.6)', () {
      for (final (value, reach, want) in [
        (3, Reach.far, 2),
        (3, Reach.mid, 3),
        (3, Reach.near, 3),
        (1, Reach.far, 1),
      ]) {
        final p = _shot(1, 0, value: value);
        armShot(p, reach);
        expect(p.bouncesLeft, want, reason: '$value $reach');
      }
    });

    test('튕긴 탄의 ×1.5 는 흘수선 줄 칸에만 붙는다 (§4.3)', () {
      int damageAt(int cx, int cy, {required bool bounced}) {
        final m = Match.start(
          seed: 3,
          rules: const MatchRules(waveLevel: 0),
          blueprints: [sampleBlueprint(), sampleBlueprint()],
          decks: const [
            ['s', 'r0'],
            ['r0', 'r1'],
          ],
          costLimits: const [15, 15],
          pirates: PirateCatalog([_skip(), testPirate('r0'), testPirate('r1')]),
        );
        final target = m.state.sides[1];
        final p = _shot(10000, 0)..bounced = bounced;
        m.state.events.clear();
        onHullHit(m.state, p, target, cx: cx, cy: cy, x: 0, y: 0);
        return m.state.events
            .where((e) => e.kind == SimEventKind.blockHit)
            .fold(0, (sum, e) => sum + e.value);
      }

      final ship = newSampleMatch(3).state.sides[1];
      final water = ship.draft ~/ cellUnit;
      final grid = ship.grid;
      (int, int)? find(bool Function(int cy) ok) {
        for (var cy = 0; cy < grid.height; cy++) {
          for (var cx = 0; cx < grid.width; cx++) {
            if (ok(cy) && grid.hasBlock(cx, cy)) return (cx, cy);
          }
        }
        return null;
      }

      final (lx, ly) = find((cy) => cy <= water)!;
      final (hx, hy) = find((cy) => cy > water + 1)!;
      expect(
        damageAt(lx, ly, bounced: true),
        damageAt(lx, ly, bounced: false) * 3 ~/ 2,
      );
      expect(
        damageAt(hx, hy, bounced: true),
        damageAt(hx, hy, bounced: false),
      );
    });
  });
}
