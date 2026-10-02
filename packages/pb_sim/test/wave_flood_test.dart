import 'package:pb_sim/pb_sim.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  group('파도 (설계서 §2.5)', () {
    const rules = MatchRules();
    const wave = Wave(rules, 1);

    test('같은 시각이면 같은 흔들림, 주기(4초)마다 되풀이된다', () {
      for (var ms = 0; ms < 8000; ms += 137) {
        expect(wave.heave(0, ms), wave.heave(0, ms + 4000));
        expect(wave.roll(0, ms), wave.roll(0, ms + 4000));
      }
      expect(wave.heave(0, 1000), 150);
      expect(wave.heave(0, 3000), -150);
      expect(wave.roll(0, 0), 1000);
    });

    test('두 배는 반주기 어긋나 흔들린다', () {
      for (var ms = 0; ms < 4000; ms += 250) {
        expect(wave.heave(1, ms), -wave.heave(0, ms));
      }
    });

    test('파도 세기 0 이면 흔들리지 않고, 폭풍 타임에는 1.5배다', () {
      const calm = Wave(MatchRules(waveLevel: 0), 1);
      expect([calm.heave(0, 1000), calm.roll(0, 0)], [0, 0]);
      const storm = Wave(rules, 27);
      expect([storm.heave(0, 1000), storm.roll(0, 0)], [225, 1500]);
    });

    test('놓는 순간에 따라 발사 높이와 각도가 달라진다', () {
      final s = newSampleMatch(3).state;
      Projectile at(int ms) =>
          launchShot(s, slot: 0, angle: 45000, power: 5000, ms: ms);
      expect((at(1000).y - at(3000).y).abs(), 300);
      expect(at(0).vy, isNot(at(2000).vy));
      expect([at(500).y, at(500).vy], [at(4500).y, at(4500).vy]);
    });
  });

  group('흘수선과 침수 (설계서 §2.5, §3.4)', () {
    test('흘수선 = (총무게 − 부력재) ÷ (선형 폭 × 4): 샘플 슬루프는 약 0.9칸', () {
      final side = newSampleMatch(1).state.sides[0];
      expect(
        SideState.waterlineOf(sampleBlueprint(), const MatchRules()),
        895,
      );
      expect(side.waterline, 895);
      expect(side.frame.baseY, -895);
    });

    test('잠긴 깊이로 줄마다 완전히·반쯤·안 잠김을 가른다', () {
      expect(submersionOf(0, 1041), Submersion.full);
      expect(submersionOf(1, 1041), Submersion.half);
      expect(submersionOf(2, 1041), Submersion.dry);
      expect(submersionOf(1, 1000), Submersion.dry);
    });

    test('구멍 단계 블록과 부서진 칸은 새고, 멀쩡한 칸·원래 빈 칸은 새지 않는다', () {
      final grid = newSampleMatch(1).state.sides[0].grid;
      expect(isLeak(grid, 3, 0), isFalse);
      grid.damage(3, 0, 60); // 참나무 80 → 20: 구멍 단계
      expect(isLeak(grid, 3, 0), isTrue);
      grid.damage(4, 0, 100);
      expect(grid.isBroken(4, 0), isTrue);
      expect(isLeak(grid, 4, 0), isTrue);
      expect(isLeak(grid, 0, 2), isFalse);
      grid.damage(5, 0, 10); // 금간 단계
      expect(isLeak(grid, 5, 0), isFalse);
    });

    test('완전히 잠긴 구멍은 턴마다 +4%p, 반쯤 잠긴 구멍은 +2%p', () {
      const rules = MatchRules();
      // 침수 50% 로 1칸 내려앉아 잠긴 깊이 1.895칸: 맨 아래 줄은 완전히, 둘째 줄은 반쯤.
      final side = newSampleMatch(1).state.sides[0]..flood = 500;
      side.grid
        ..damage(3, 0, 100)
        ..damage(4, 1, 100);
      expect(floodGain(side, rules, 1), 40 + 20);
      expect(floodGain(side, rules, 27), (40 + 20) * 3 ~/ 2);
      expect(applyFlood(side, rules, 1), 60);
      expect(side.flood, 560);
    });

    test('침수량은 100% 에서 멈추고, 그만큼 배가 내려앉는다(100% 에 2칸)', () {
      const rules = MatchRules();
      final side = newSampleMatch(1).state.sides[0];
      for (var x = 0; x < 12; x++) {
        side.grid.damage(x, 0, 100);
      }
      side.flood = 990;
      applyFlood(side, rules, 1);
      expect(side.flood, fullFlood);
      expect(side.draft, 895 + 2000);
      side.flood = 500;
      expect(side.draft, 895 + 1000);
    });

    test('뱃머리 쪽만 뚫리면 뱃머리가 내려가고, 기울기는 ±6° 에서 멈춘다', () {
      const rules = MatchRules();
      // 둘째 줄까지 물에 잠기게 1칸 내려앉힌다.
      final side = newSampleMatch(1).state.sides[0]..flood = 500;
      side.grid.damage(10, 0, 100);
      expect(floodTilt(side, rules), -1000);
      side.grid.damage(1, 0, 100);
      expect(floodTilt(side, rules), 0);
      for (var x = 6; x < 12; x++) {
        side.grid.damage(x, 0, 100);
        side.grid.damage(x, 1, 100);
      }
      expect(floodTilt(side, rules), -6000);
    });

    test('자기 턴이 끝날 때 침수가 차고 이벤트가 나온다', () {
      final m = newSampleMatch(1);
      final me = m.state.activeSide;
      m.state.sides[me].grid.damage(3, 0, 100);
      m.state.sides[1 - me].grid.damage(3, 0, 100);
      m.apply(const EndTurnCommand(t: 10));
      // 샘플 배 맨 아래 줄은 반쯤 잠겨 +2%p.
      expect(m.state.sides[me].flood, 20);
      expect(m.state.sides[1 - me].flood, 0);
      expect(
        m.state.events.where((e) => e.kind == SimEventKind.flood).single.value,
        20,
      );
    });

    test('침수량이 100% 가 되면 그 자리에서 격침(침수)으로 진다', () {
      final m = newSampleMatch(1);
      final me = m.state.activeSide;
      m.state.sides[me]
        ..flood = 990
        ..grid.damage(3, 0, 100);
      m.apply(const EndTurnCommand(t: 10));
      expect(m.state.outcome, MatchOutcome.floodSunk);
      expect(m.state.winner, 1 - me);
    });
  });

  group('물에 잠긴 선실 (ADR-027)', () {
    test('배가 내려앉아 선실이 흘수선 아래로 잠기면 그 해적은 쏠 수 없다', () {
      final m = newSampleMatch(1);
      final me = m.state.sides[m.state.activeSide];
      expect(me.canFire(0), isTrue);
      me.flood = fullFlood; // 잠긴 깊이 3.04칸 > 3층 선실 중심 2.5칸
      expect(me.isCabinFlooded(0), isTrue);
      m.apply(const FireCommand(t: 100, slot: 0, angle: 30000, power: 8000));
      expect(me.shotsFired, 0);
      expect(m.state.nextProjectileId, 0);
    });

    test('맨 아래 줄 선실은 처음부터 잠겨 있어, 낮은 각도로 쏴도 멈추지 않고 무시된다', () {
      final keelCabins = Blueprint(
        HullSpec.sloop,
        [for (var x = 0; x < 12; x++) BlockCell(x, 0, BlockMaterial.oak)],
        cabins: const [
          CabinCell(3, 0),
          CabinCell(5, 0),
          CabinCell(6, 0),
          CabinCell(8, 0),
        ],
        modules: const [ModuleCell(0, 0, ModuleKind.captain)],
      );
      final m = Match.start(
        seed: 2,
        blueprints: [keelCabins, keelCabins],
        decks: const [
          ['p01', 'p06'],
          ['p01', 'p06'],
        ],
        costLimits: sampleCostLimits,
        pirates: sampleCatalog,
      );
      final me = m.state.sides[m.state.activeSide];
      expect(me.isCabinFlooded(0), isTrue);
      // 옛 버그: 수직 속도가 중력과 같은 각도에서 0 으로 나눴다.
      m.apply(const FireCommand(t: 100, slot: 0, angle: 1600, power: 10000));
      expect(me.shotsFired, 0);
    });

    test('파도가 선실 중심을 물 아래로 내려도 발사는 해수면 위에서 한다', () {
      final m = newSampleMatch(1);
      final me = m.state.sides[m.state.activeSide]..flood = 700; // 잠긴 깊이 2.44칸
      expect(me.isCabinFlooded(0), isFalse);
      for (var ms = 0; ms < 4000; ms += 100) {
        final p = launchShot(
          m.state,
          slot: 0,
          angle: 1600,
          power: 10000,
          ms: ms,
        );
        expect(p.y, greaterThanOrEqualTo(0), reason: 'ms $ms');
      }
    });
  });
}
