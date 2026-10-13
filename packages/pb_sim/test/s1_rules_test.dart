import 'package:pb_sim/pb_sim.dart';
import 'package:pb_sim/src/combat/ammo_rules.dart';
import 'package:pb_sim/src/combat/hit_effects.dart';
import 'package:pb_sim/src/combat/legend_effects.dart';
import 'package:pb_sim/src/combat/module_effects.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

/// S1 게임 정리로 바뀐 규칙 (설계서 §2.7, §3.3, §4.8, ADR-111).
PirateSpec _legend(
  String id,
  AmmoType ammo,
  Ability ability,
  int value, {
  int ammoValue = 1,
  int blastRadius = 1,
}) => PirateSpec(
  id: id,
  rarity: Rarity.legend,
  hp: 300,
  blockDamage: 40,
  pirateDamage: 80,
  blastRadius: blastRadius,
  ammo: ammo,
  ammoValue: ammoValue,
  ability: ability,
  abilityValue: value,
);

/// 왼쪽에 [spec] 해적, 오른쪽에 기본 해적 5명(선실 4 + 망대). 파도 없음, 왼쪽 턴.
Match _duel(PirateSpec spec) {
  final m = Match.start(
    seed: 11,
    rules: const MatchRules(calmSea: true),
    blueprints: [sampleBlueprint(), sampleBlueprint()],
    decks: [
      [spec.id],
      ['e0', 'e1', 'e2', 'e3', 'e4'],
    ],
    costLimits: const [40, 40],
    pirates: PirateCatalog([
      spec,
      for (var i = 0; i < 5; i++) testPirate('e$i'),
    ]),
  );
  while (m.state.activeSide != 0) {
    m.apply(const EndTurnCommand(t: 1000));
  }
  m.apply(const TapCommand(t: 0, slot: 9, ticks: 0));
  return m;
}

/// 왼쪽 0번 해적의 탄이 오른쪽 배 칸 ([cx], [cy]) 에 맞았다.
void _hit(Match m, int cx, int cy, {PirateSpec? spec}) {
  final target = m.state.sides[1];
  final (x, y) = target.frame.cellCenter(cx, cy);
  final p = Projectile(
    id: 0,
    side: 0,
    slot: 0,
    spec: spec ?? m.state.sides[0].crew.pirates[0].spec,
    x: x,
    y: y,
    vx: 100000,
    vy: 0,
  );
  armShot(p);
  onHullHit(m.state, p, target, cx: cx, cy: cy, x: x, y: y);
}

List<SimEvent> _of(Match m, SimEventKind k) => [
  for (final e in m.state.events)
    if (e.kind == k) e,
];

void main() {
  group('승리 판정 (설계서 §2.7)', () {
    test('선장실 블록이 부서지면 그 자리에서 진다', () {
      final m = newSampleMatch(1, rules: const MatchRules(calmSea: true));
      final foe = m.state.sides[1];
      final captain = foe.modules.list.firstWhere(
        (x) => x.kind == ModuleKind.captain,
      );
      foe.grid.damage(captain.x, captain.y, 9999);
      settleModules(foe, m.state.events);
      judgeInstant(m.state);
      expect(m.state.outcome, MatchOutcome.captainLost);
      expect(m.state.winner, 0);
    });

    test('같은 순간 양쪽 선장실이 부서지면 무승부다', () {
      final m = newSampleMatch(1, rules: const MatchRules(calmSea: true));
      for (final s in m.state.sides) {
        s.grid.damage(1, 1, 9999);
        settleModules(s, m.state.events);
      }
      judgeInstant(m.state);
      expect(m.state.outcome, MatchOutcome.captainLost);
      expect(m.state.winner, -1);
    });

    test('같은 순간 한쪽은 전멸, 다른 쪽은 선장실이 부서져도 무승부다 (ADR-113)', () {
      final m = newSampleMatch(1, rules: const MatchRules(calmSea: true));
      final a = m.state.sides[0];
      for (var slot = 0; slot < a.crew.size; slot++) {
        a.crew.damage(slot, 9999, 0, m.state.events);
      }
      final b = m.state.sides[1];
      b.grid.damage(1, 1, 9999);
      settleModules(b, m.state.events);
      judgeInstant(m.state);
      expect(m.state.outcome, MatchOutcome.annihilation);
      expect(m.state.winner, -1);
    });

    test('한쪽만 전멸하면 상대가 이긴다', () {
      final m = newSampleMatch(1, rules: const MatchRules(calmSea: true));
      final a = m.state.sides[0];
      for (var slot = 0; slot < a.crew.size; slot++) {
        a.crew.damage(slot, 9999, 0, m.state.events);
      }
      judgeInstant(m.state);
      expect(m.state.outcome, MatchOutcome.annihilation);
      expect(m.state.winner, 1);
    });

    test('턴 제한: 남은 해적 체력 비율이 높은 쪽, 같으면 선장실 내구도 비율이 높은 쪽', () {
      final m = newSampleMatch(1, rules: const MatchRules(calmSea: true));
      final s = m.state;
      expect(timeLeader(s), -1);
      s.sides[1].grid.damage(1, 1, 10);
      expect(timeLeader(s), 0, reason: '체력은 같고 선장실이 덜 깎였다');
      s.sides[0].crew.damage(0, 50, 0, s.events);
      expect(timeLeader(s), 1, reason: '체력 비율이 먼저다');
      // 왼쪽은 4명(1200), 오른쪽은 3명(900, 샘플 덱): 비율로 비교한다.
      expect(s.sides[0].crew.hpStart, isNot(s.sides[1].crew.hpStart));
    });
  });

  group('망대 (설계서 §3.3, BALANCE.md A3.3)', () {
    test('5번째 해적은 돛대 꼭대기 망대에 타고 피해가 30% 크다', () {
      final m = _duel(testPirate('x'));
      final foe = m.state.sides[1];
      expect(foe.cabins, hasLength(5));
      final nest = foe.cabins[4];
      expect([nest.x, nest.y], [0, 5]);
      expect(foe.isOnCrowsNest(4), isTrue);
      expect(foe.isOnCrowsNest(0), isFalse);
      expect(foe.damageBonusPercent(4), 30);
    });

    test('돛대 칸이 부러지면 망대 해적은 바다로 떨어져 KO 다', () {
      final m = _duel(testPirate('x', blockDamage: 100, blastRadius: 0));
      _hit(m, 0, 3);
      final foe = m.state.sides[1];
      expect(foe.crew.pirates[4].status, PirateStatus.down);
      expect(foe.isOnCrowsNest(4), isFalse);
      expect(foe.grid.hasBlock(0, 5), isFalse, reason: '위쪽 돛대 칸도 무너진다');
      expect(_of(m, SimEventKind.pirateFell).single.slot, 4);
    });

    test('망대 해적이 쏜 탄은 피해가 30% 크다', () {
      // 오른쪽 차례로 넘겨 망대 해적(슬롯 4)으로 쏜다.
      final m = _duel(testPirate('x'))
        ..apply(const EndTurnCommand(t: 1000))
        ..apply(const TapCommand(t: 0, slot: 9, ticks: 0));
      final shots = launchVolley(
        m.state,
        slot: 4,
        angle: 45000,
        power: 8000,
        ms: 0,
      );
      expect(shots.single.spec.blockDamage, 60 * 130 ~/ 100);
      expect(shots.single.spec.pirateDamage, 80 * 130 ~/ 100);
    });
  });

  group('전설 고유 능력 (설계서 §4.8, BALANCE.md A4.2)', () {
    test('모비: 선체에 맞으면 적 배를 인자 칸만큼 끌어당긴다', () {
      final m = _duel(
        _legend('moby', AmmoType.pierce, Ability.pull, 3, ammoValue: 2),
      );
      _hit(m, 11, 1);
      expect(m.state.sides[1].offset, 3 * cellUnit);
      expect(_of(m, SimEventKind.pushed).single.value, 3 * cellUnit);
    });

    test('오르카: 갑판 맨 위 해적에게 해적 피해 50%, 적 배를 2칸 밀어낸다', () {
      final m = _duel(
        _legend('orca', AmmoType.skip, Ability.wave, 2, blastRadius: 0),
      );
      _hit(m, 11, 0);
      final foe = m.state.sides[1];
      expect(foe.offset, -2 * cellUnit);
      // (3,2)·(8,2) 선실과 망대는 위가 비어 있다. (5,2)·(6,2) 는 위에 블록.
      final hp = [for (final p in foe.crew.pirates) p.hp];
      expect(hp, [260, 300, 300, 260, 260]);
    });

    test('크라키: 붙는 순간 터지고, 상대 턴이 끝날 때마다 둘레 칸을 2번 친다', () {
      final m = _duel(
        _legend('kraki', AmmoType.mine, Ability.tentacle, 2),
      );
      _hit(m, 6, 1);
      expect(_of(m, SimEventKind.blockHit), isNotEmpty, reason: '바로 터진다');
      final effect = m.state.effects.single;
      expect(effect.kind, EffectKind.tentacle);
      final grid = m.state.sides[1].grid;
      final hp = grid.totalHp;
      m.apply(const EndTurnCommand(t: 9000)); // 내 턴 끝: 촉수는 세지 않는다
      expect(grid.totalHp, hp);
      m
        ..apply(const TapCommand(t: 0, slot: 9, ticks: 0))
        ..apply(const EndTurnCommand(t: 9000)); // 상대 턴 끝
      expect(grid.totalHp, lessThan(hp));
      expect(m.state.effects.single.turnsLeft, 1);
    });

    test('만타: 상대의 다음 턴 궤적 점선을 숨긴다', () {
      final m = _duel(
        _legend('manta', AmmoType.homing, Ability.blindTrail, 0),
      );
      _hit(m, 11, 1);
      final foe = m.state.sides[1];
      expect(foe.status.trailBlockTurn, m.state.turn + 1);
    });

    test('램프: 충격탄이 2칸 민다(일반 충격탄은 1칸)', () {
      final m = _duel(
        _legend('lamp', AmmoType.shock, Ability.shove, 2, blastRadius: 2),
      );
      _hit(m, 11, 1);
      expect(m.state.sides[1].offset, -2 * cellUnit);
    });

    test('볼케: 블록 2층을 절반 피해로 뚫고 셋째 칸에서 반경 +1 로 터진다', () {
      final volke = _legend('volke', AmmoType.explosive, Ability.drill, 2);
      final p = Projectile(
        id: 0,
        side: 0,
        slot: 0,
        spec: volke,
        x: 0,
        y: 0,
        vx: 0,
        vy: 0,
      );
      armLegend(p);
      expect(p.pierceLeft, 3);
      final m = _duel(volke);
      final target = m.state.sides[1];
      expect(
        legendHullHit(m.state, p, target, cx: 6, cy: 3, x: 0, y: 0),
        isFalse,
      );
      expect(
        legendHullHit(m.state, p, target, cx: 6, cy: 2, x: 0, y: 0),
        isFalse,
      );
      expect(
        legendHullHit(m.state, p, target, cx: 6, cy: 1, x: 0, y: 0),
        isTrue,
      );
    });
  });

  group('경계 (설계서 §2.5, §3.3, §4.5, §4.8)', () {
    test('돛대 없는 배는 선실 4명만 타고, 5명이면 출전을 막는다', () {
      final base = sampleBlueprint();
      final noMast = Blueprint(
        base.hull,
        base.cells,
        cabins: base.cabins,
        modules: const [ModuleCell(1, 1, ModuleKind.captain)],
      );
      expect(noMast.seatCount, 4);
      Match start(int n) => Match.start(
        seed: 3,
        blueprints: [noMast, sampleBlueprint()],
        decks: [
          [for (var i = 0; i < n; i++) 'e$i'],
          ['e0'],
        ],
        costLimits: const [40, 40],
        pirates: PirateCatalog([
          for (var i = 0; i < 5; i++) testPirate('e$i'),
        ]),
      );
      expect(() => start(5), throwsArgumentError);
      final side = start(4).state.sides[0];
      expect(side.cabins, hasLength(4));
      for (var slot = 0; slot < 4; slot++) {
        expect(side.isOnCrowsNest(slot), isFalse);
        expect(side.damageBonusPercent(slot), 0);
      }
    });

    test('충격탄에 밀려도 바다 끝(시작 위치에서 뒤로 4칸)에서 멈춘다', () {
      final m = _duel(
        _legend('lamp', AmmoType.shock, Ability.shove, 2, blastRadius: 2),
      );
      for (var i = 0; i < 3; i++) {
        _hit(m, 11, 1);
      }
      expect(m.state.sides[1].offset, -m.state.rules.backRoom);
    });

    test('모비에 끌려도 최소 간격(2칸)에서 멈춘다', () {
      final m = _duel(
        _legend('moby', AmmoType.pierce, Ability.pull, 3, ammoValue: 2),
      );
      for (var i = 0; i < 8; i++) {
        _hit(m, 11, 1);
      }
      final s = m.state.sides;
      expect((s[1].bowX - s[0].bowX).abs(), m.state.rules.minGap);
    });

    test('크라키 촉수가 격자 모서리 칸에 붙어도 둘레 안 칸만 친다', () {
      final m = _duel(
        _legend('kraki', AmmoType.mine, Ability.tentacle, 2, blastRadius: 0),
      );
      _hit(m, 0, 0);
      expect(m.state.effects.single.kind, EffectKind.tentacle);
      final grid = m.state.sides[1].grid;
      final before = List.of(grid.rawHp);
      // 오른쪽(대상) 턴이 끝날 때 친다.
      m
        ..apply(const EndTurnCommand(t: 1000))
        ..apply(const EndTurnCommand(t: 1000));
      final w = grid.width;
      final changed = [
        for (var i = 0; i < before.length; i++)
          if (grid.rawHp[i] != before[i]) i,
      ];
      expect(changed, isNotEmpty);
      expect(changed, everyElement(isIn([0, 1, w, w + 1])));
    });
  });
}
