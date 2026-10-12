import 'package:pb_sim/pb_sim.dart';
import 'package:pb_sim/src/combat/module_effects.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

/// 공격 해적 1명(투척) + 보급 해적 1명. 상대는 공격 해적 2명.
final PirateCatalog _catalog = PirateCatalog([
  testPirate('atk'),
  const PirateSpec(
    id: 'sup',
    rarity: Rarity.common,
    hp: 300,
    cooldownTurns: 0,
    blockDamage: 20,
    pirateDamage: 20,
    family: Family.support,
    ammo: AmmoType.support,
  ),
  testPirate('foe'),
  testPirate('foe2'),
]);

Match _start(List<String> left) => Match.start(
  seed: 59,
  rules: const MatchRules(waveLevel: 0),
  blueprints: [sampleBlueprint(), sampleBlueprint()],
  decks: [
    left,
    ['foe', 'foe2'],
  ],
  costLimits: const [15, 15],
  pirates: _catalog,
);

void _down(Match m, int side, String id) {
  for (final p in m.state.sides[side].crew.pirates) {
    if (p.spec.id == id) p.status = PirateStatus.down;
  }
}

void main() {
  group('A59 공격 불능 전멸 (설계서 §2.4, ADR-105)', () {
    test('공격 해적이 모두 쓰러져 보급 해적만 남으면 그 자리에서 진다', () {
      final m = _start(['atk', 'sup']);
      judgeInstant(m.state);
      expect(m.state.outcome, MatchOutcome.ongoing);
      _down(m, 0, 'atk');
      judgeInstant(m.state);
      expect(m.state.outcome, MatchOutcome.annihilation);
      expect(m.state.winner, 1);
    });

    test('처음부터 보급 해적만 태운 진영은 공격 불능으로 지지 않는다(튜토리얼 상대)', () {
      final m = _start(['sup']);
      judgeInstant(m.state);
      expect(m.state.outcome, MatchOutcome.ongoing);
      expect(m.state.sides[0].crew.attackersDown, isFalse);
    });

    test('같은 시드·같은 커맨드면 같은 결과·해시가 나온다', () {
      String run() {
        final m = _start(['atk', 'sup']);
        _down(m, 0, 'atk');
        judgeInstant(m.state);
        return '${m.state.outcome}/${m.state.winner}/${hashMatchState(m.state)}';
      }

      expect(run(), run());
      // 고정 기대값: 판정·해시가 바뀌면 이 값도 바뀐다 (재현성 회귀).
      expect(run(), 'MatchOutcome.annihilation/1/3359363047');
    });
  });

  group('A59 튜토리얼 3 펌프 몫 (설계서 §13.1, ADR-105)', () {
    Match start({required bool wounded}) => Match.start(
      seed: 59,
      rules: MatchRules(
        waveLevel: 0,
        gimmick: wounded ? BossGimmick.woundedStart.index : 0,
        gimmickSide: 0,
      ),
      blueprints: [sampleBlueprint(), sampleBlueprint()],
      decks: const [
        ['atk'],
        ['foe', 'foe2'],
      ],
      costLimits: const [15, 15],
      pirates: _catalog,
    );

    int floodAfterTurnEnd({required bool wounded, bool pumpsOff = false}) {
      final m = start(wounded: wounded);
      final me = m.state.sides[0]..flood = 100;
      endTurnWater(
        me,
        m.state.rules,
        m.state.turn,
        <SimEvent>[],
        pumpsOff: pumpsOff,
      );
      return me.flood;
    }

    test('시작 구멍 기믹 쪽 배는 턴 끝마다 펌프 하나 몫(−4%p)이 빠진다', () {
      // 같은 배·같은 침수에서 펌프를 쉬게 한 경우와 비교한다(샘플 배는 펌프가 없다).
      expect(
        floodAfterTurnEnd(wounded: true, pumpsOff: true) -
            floodAfterTurnEnd(wounded: true),
        ModuleNumbers.pumpFlood,
      );
      expect(
        floodAfterTurnEnd(wounded: false, pumpsOff: true) -
            floodAfterTurnEnd(wounded: false),
        0,
        reason: '기믹이 없으면 펌프 몫도 없다',
      );
    });

    test('펌프 몫은 0 아래로 내려가지 않는다', () {
      final me = start(wounded: true).state.sides[0]..flood = 10;
      runRepairAndPumps(me, <SimEvent>[], bonusPumps: 1);
      expect(me.flood, 0);
    });
  });
}
