import 'package:pb_sim/pb_sim.dart';
import 'package:test/test.dart';

import 'aim.dart';
import 'fixtures.dart';

/// 왼쪽이 선공인 샘플 판(파도 없음).
Match _match(List<PirateSpec> left) {
  for (var seed = 1; ; seed++) {
    final m = Match.start(
      seed: seed,
      rules: const MatchRules(waveLevel: 0),
      blueprints: [sampleBlueprint(), sampleBlueprint()],
      decks: [
        [for (final p in left) p.id],
        ['p01', 'p06'],
      ],
      costLimits: const [15, 15],
      pirates: PirateCatalog([...left, ...samplePirates]),
    );
    if (m.state.activeSide == 0) return m;
  }
}

void main() {
  group('미리 계산 previewShot (설계서 §5.1)', () {
    test('착탄 칸·틱이 실제로 쏜 결과와 같고, 매치 상태 해시는 바뀌지 않는다', () {
      for (var slot = 0; slot < 4; slot++) {
        final m = newSampleMatch(5)..apply(const MoveCommand(t: 10, dx: 0));
        final c = m.state.sides[1 - m.state.activeSide].cabins[slot];
        final fire = aimAt(m.state, slot: 0, tx: c.x, ty: c.y);
        final before = hashMatchState(m.state);
        final ms = realMs(m.state, effectiveMs(m.state, fire.t));
        final landing = previewShot(
          m.state,
          slot: 0,
          angle: fire.angle,
          power: fire.power,
          ms: ms,
        ).single;
        expect(hashMatchState(m.state), before);
        m.apply(fire);
        final impact = m.state.events.firstWhere(
          (e) => e.kind == SimEventKind.impact || e.kind == SimEventKind.splash,
        );
        expect(landing.tick, impact.value);
        if (impact.kind == SimEventKind.impact) {
          final w = m.state.sides[impact.side].grid.width;
          expect([landing.cx, landing.cy], [impact.cell % w, impact.cell ~/ w]);
        } else {
          expect(landing.hitShip, isFalse);
        }
      }
    });

    test('분열탄은 탭 틱을 주면 조각마다 착탄을 돌려준다', () {
      const uni = PirateSpec(
        id: 'uni',
        rarity: Rarity.hero,
        hp: 300,
        cooldownTurns: 0,
        blockDamage: 50,
        pirateDamage: 100,
        blastRadius: 1,
        range: RangeGrade.long,
        ammo: AmmoType.split,
        ammoValue: 4,
        spreadMdeg: 25000,
      );
      final m = _match([uni]);
      final whole = previewShot(
        m.state,
        slot: 0,
        angle: 45000,
        power: 9000,
        ms: 0,
      );
      final split = previewShot(
        m.state,
        slot: 0,
        angle: 45000,
        power: 9000,
        ms: 0,
        tapTick: 20,
      );
      expect(whole, hasLength(1));
      expect(split, hasLength(4));
      expect(split.first.spec.blockDamage, perShotDamage(50, 2, 4));
    });
  });
}
