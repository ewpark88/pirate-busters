import 'package:pb_sim/pb_sim.dart';
import 'package:test/test.dart';

import 'aim.dart';
import 'fixtures.dart';

SideState _boss(BossGimmick g) => SideState(
  side: 1,
  blueprint: sampleBlueprint(),
  lineup: [testPirate('a'), testPirate('b')],
  rules: MatchRules(gimmick: g.index, waveLevel: 0),
);

PirateSpec _shot(Family family) => PirateSpec(
  id: 'shot',
  rarity: Rarity.common,
  hp: 100,
  cooldownTurns: 0,
  blockDamage: 60,
  pirateDamage: 0,
  family: family,
);

void main() {
  group('1-5 뱃머리 철판 방패 (설계서 §5.4, BALANCE.md A5.4)', () {
    test('방패는 판 시작 때 가장 앞 세로줄 블록이고, 기믹이 없으면 없다', () {
      final s = _boss(BossGimmick.bowIronShield);
      final g = s.grid;
      expect(s.shieldCells, [g.indexOf(11, 2), g.indexOf(11, 3)]);
      expect(_boss(BossGimmick.none).shieldCells, isEmpty);
    });

    test('방패가 서 있는 동안 직사만 블록 피해 50%, 방패가 다 부서지면 원래대로', () {
      final s = _boss(BossGimmick.bowIronShield);
      expect(shieldPercent(s, _shot(Family.direct)), 50);
      expect(shieldPercent(s, _shot(Family.lob)), 100);
      s.shieldCells.forEach(s.grid.removeAt);
      expect(shieldPercent(s, _shot(Family.direct)), 100);
    });

    test('직사 착탄 피해가 실제로 절반이 된다', () {
      final s = _boss(BossGimmick.bowIronShield);
      final before = s.grid.hpAt(5, 1);
      resolveImpact(
        s,
        spec: _shot(Family.direct),
        cx: 5,
        cy: 1,
        x: 0,
        y: 0,
        events: [],
        rng: XorShift32(1),
      );
      expect(before - s.grid.hpAt(5, 1), 30, reason: '소나무 40 에 60 × 50%');
    });
  });

  group('1-12 다가오는 초계선 (설계서 §5.4, BALANCE.md A5.4)', () {
    Match start({MatchRules? rules}) => Match.start(
      seed: 4,
      rules:
          rules ??
          MatchRules(gimmick: BossGimmick.patrolClosingIn.index, waveLevel: 0),
      blueprints: [sampleBlueprint(), sampleBlueprint()],
      decks: sampleDecks,
      costLimits: sampleCostLimits,
      pirates: sampleCatalog,
    );

    test('보스 쪽 전진 한계가 턴마다 1칸씩 늘고 6칸에서 멈춘다', () {
      final m = start();
      final boss = m.state.sides[1];
      final seen = <int>[];
      for (var i = 0; i < 20; i++) {
        m.apply(const EndTurnCommand(t: 10));
        if (m.state.activeSide == 1) seen.add(boss.forwardBonus ~/ cellUnit);
      }
      expect(seen.take(4), [1, 2, 3, 4]);
      expect(seen.last, 6);
      expect(m.state.sides[0].forwardBonus, 0, reason: '플레이어는 그대로');
    });

    test('다가와도 두 뱃머리는 2칸보다 가까워지지 않는다', () {
      final m = start();
      m.state.sides[0].offset = moveRange;
      for (var i = 0; i < 16; i++) {
        m.apply(const EndTurnCommand(t: 10));
      }
      final boss = m.state.sides[1];
      expect(
        startGap - m.state.sides[0].offset - (moveRange + boss.forwardBonus),
        greaterThanOrEqualTo(2 * cellUnit),
      );
    });

    test('보스 쪽 해적 쿨다운은 턴 끝마다 2씩 준다', () {
      expect(cooldownStepOf(start().state.rules, 1), 2);
      expect(cooldownStepOf(start().state.rules, 0), 1);
      final crew = Crew([testPirate('c', cooldownTurns: 3)])..markFired(0);
      final first = crew.pirates[0].cooldown;
      crew.endOwnTurn(2);
      expect(crew.pirates[0].cooldown, first - 2);
      crew
        ..endOwnTurn(2)
        ..endOwnTurn(2);
      expect(crew.pirates[0].cooldown, 0, reason: '0 아래로 내려가지 않는다');
    });

    test('기믹은 규칙 JSON 에 들어가고, 없으면 예전 리플레이와 같은 JSON 이다', () {
      final rules = MatchRules(gimmick: BossGimmick.patrolClosingIn.index);
      expect(MatchRules.fromJson(rules.toJson()).gimmick, 2);
      expect(const MatchRules().toJson().containsKey('gimmick'), isFalse);
      expect(BossGimmick.byId('bow_iron_shield'), BossGimmick.bowIronShield);
      expect(BossGimmick.byId(null), BossGimmick.none);
    });
  });

  test('보스 기믹 판은 고정 해시로 끝나고, 기믹이 판을 바꾸며, 재생해도 같다', () {
    // 왼쪽은 직사 해적이 매 턴 보스 뱃머리를 쏘고, 보스는 매 턴 끝까지 전진하며 쏜다.
    final pirates = PirateCatalog([
      for (final id in ['d1', 'd2'])
        PirateSpec(
          id: id,
          rarity: Rarity.common,
          hp: 300,
          cooldownTurns: 0,
          blockDamage: 60,
          pirateDamage: 80,
          range: RangeGrade.long,
          family: Family.direct,
        ),
      testPirate('b1', cooldownTurns: 2),
      testPirate('b2', cooldownTurns: 2),
    ]);
    List<Command> me(MatchState s) => [
      if (s.activeSide == 1) const MoveCommand(t: 10, dx: 100),
      for (var slot = 0; slot < 2; slot++)
        if (s.sides[s.activeSide].canFire(slot))
          s.activeSide == 0
              ? _aimAny(s, slot, 1000 + slot * 6000)
              : FireCommand(
                  t: 4000 + slot * 6000,
                  slot: slot,
                  angle: 45000,
                  power: 8000,
                ),
      const EndTurnCommand(t: 20000),
    ];
    int play(BossGimmick g) {
      Match start() => Match.start(
        seed: 21,
        rules: MatchRules(gimmick: g.index, waveLevel: 0, maxWind: 0),
        blueprints: [sampleBlueprint(), sampleBlueprint()],
        decks: const [
          ['d1', 'd2'],
          ['b1', 'b2'],
        ],
        costLimits: sampleCostLimits,
        pirates: pirates,
      );
      final m = start();
      runMatch(m, FnController(me), FnController(me));
      final again = start();
      m.turnLog.forEach(again.playTurn);
      expect(hashMatchState(again.state), hashMatchState(m.state));
      return hashMatchState(m.state);
    }

    final none = play(BossGimmick.none);
    for (final g in [BossGimmick.bowIronShield, BossGimmick.patrolClosingIn]) {
      final h = play(g);
      expect(h, isNot(none), reason: '${g.name} 가 판을 바꾼다');
      expect(h, _gimmickHashes[g], reason: g.name);
    }
  });
}

/// 보스 기믹 판의 고정 해시. 규칙을 일부러 바꿨을 때만 고친다.
const Map<BossGimmick, int> _gimmickHashes = {
  BossGimmick.bowIronShield: 2786304569,
  BossGimmick.patrolClosingIn: 41280035,
};

/// 뱃머리부터 남은 칸을 차례로 노린다. 닿는 궤적이 없으면 기본 각도로 쏜다.
FireCommand _aimAny(MatchState s, int slot, int t) {
  for (final (x, y) in const [(11, 2), (11, 3), (10, 2), (9, 2), (6, 1)]) {
    try {
      return aimAt(s, slot: slot, tx: x, ty: y, t: t);
      // 테스트 조준 도우미는 닿는 궤적이 없으면 StateError 를 낸다: 다음 칸을 노린다.
      // ignore: avoid_catching_errors
    } on StateError {
      continue;
    }
  }
  return FireCommand(t: t, slot: slot, angle: 30000, power: 8000);
}
