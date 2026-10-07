import 'package:pb_sim/pb_sim.dart';
import 'package:pb_sim/src/combat/ability_effects.dart';
import 'package:pb_sim/src/combat/ammo_rules.dart';
import 'package:pb_sim/src/combat/barrier_effects.dart';
import 'package:pb_sim/src/combat/flight.dart';
import 'package:pb_sim/src/combat/support_effects.dart';
import 'package:pb_sim/src/combat/unique_effects.dart';
import 'package:pb_sim/src/combat/unique_turns.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

/// R1a-2 시험용 해적 (설계서 §4.8 고유 효과, ADR-078).
PirateSpec _pirate(
  String id, {
  AmmoType ammo = AmmoType.explosive,
  Ability ability = Ability.none,
  int abilityValue = 0,
  int value = 0,
  int value2 = 0,
  int blastRadius = 0,
  int blockDamage = 40,
  int pirateDamage = 80,
  int hp = 300,
}) => PirateSpec(
  id: id,
  rarity: Rarity.common,
  hp: hp,
  cooldownTurns: 0,
  blockDamage: blockDamage,
  pirateDamage: pirateDamage,
  blastRadius: blastRadius,
  range: RangeGrade.long,
  ammo: ammo,
  ammoValue: value,
  ammoValue2: value2,
  ability: ability,
  abilityValue: abilityValue,
);

/// 왼쪽(0) 에 [spec] 과 보조, 오른쪽(1) 에 기본 해적 4명. 파도 없음. 왼쪽 턴을 연다.
Match _duel(PirateSpec spec) {
  final m = Match.start(
    seed: 11,
    rules: const MatchRules(waveLevel: 0),
    blueprints: [sampleBlueprint(), sampleBlueprint()],
    decks: [
      [spec.id, 'r0'],
      ['r0', 'r1', 'r2', 'r3'],
    ],
    costLimits: const [15, 15],
    pirates: PirateCatalog([
      spec,
      for (var i = 0; i < 4; i++) testPirate('r$i'),
    ]),
  );
  while (m.state.activeSide != 0) {
    m.apply(const EndTurnCommand(t: 1000));
  }
  m.apply(const TapCommand(t: 0, slot: 9, ticks: 0));
  return m;
}

Projectile _shot(
  PirateSpec spec, {
  int side = 0,
  int vx = 100000,
  int vy = 0,
  int x = 0,
  int y = 5000,
}) => Projectile(
  id: 0,
  side: side,
  slot: 0,
  spec: spec,
  x: x,
  y: y,
  vx: vx,
  vy: vy,
);

bool? _hit(Match m, Projectile p, int cx, int cy) {
  final target = m.state.sides[1];
  final (x, y) = target.frame.cellCenter(cx, cy);
  return uniqueHullHit(m.state, p, target, cx: cx, cy: cy, x: x, y: y);
}

/// 판 진행 중 나온 이벤트 종류를 모으는 컨트롤러.
class _Recorder implements Controller {
  _Recorder(this.inner, this.seen);

  final Controller inner;
  final List<SimEventKind> seen;

  @override
  TurnBundle turnFor(MatchState state) {
    seen.addAll(state.events.map((e) => e.kind));
    return inner.turnFor(state);
  }
}

/// R1a-2 섞인 판(시드 777, 스크립트 33·34)의 기대 해시. 의도한 규칙 변경일 때만 갱신한다.
const int _mixedHash = 3127421906;

List<SimEvent> _of(Match m, SimEventKind kind) =>
    m.state.events.where((e) => e.kind == kind).toList();

void main() {
  group('투척·직사 고유 동작', () {
    test('꽃게 형제는 같은 각도로 두 발을 쏘고 두 발 합계는 120% 다 (R1d)', () {
      final crab = _pirate('crab', ability: Ability.twin, blockDamage: 100);
      final m = _duel(crab);
      final shots = launchVolley(
        m.state,
        slot: 0,
        angle: 45000,
        power: 9000,
        ms: 0,
      );
      expect(shots, hasLength(2));
      expect(shots[0].vx, shots[1].vx);
      expect(shots[1].startTick, greaterThan(shots[0].startTick));
      expect(shots[0].spec.blockDamage, 60);
    });

    test('볼케는 인자 층을 절반 피해로 뚫고 마지막 칸에서 반경을 넓혀 터진다', () {
      final volke = _pirate(
        'volke',
        ability: Ability.drill,
        abilityValue: 3,
        blastRadius: 1,
        value: 50,
      );
      final m = _duel(volke);
      final p = _shot(volke);
      armUnique(p);
      expect(p.pierceLeft, 3);
      final grid = m.state.sides[1].grid;
      final hp = grid.hpAt(10, 1);
      expect(_hit(m, p, 10, 1), isFalse);
      expect(grid.hpAt(10, 1), hp - 20, reason: '반경 0, 블록 피해 50%');
      expect(p.passedNet, grid.indexOf(10, 1));
      expect(_hit(m, p, 10, 0), isFalse);
      expect(_hit(m, p, 11, 0), isTrue, reason: '마지막 층에서 대폭발');
    });

    test('라이언 탄은 망사를 늦춰지지 않고 찢어 없앤다', () {
      final lion = _pirate(
        'lion',
        ammo: AmmoType.burst,
        ability: Ability.shred,
      );
      final m = _duel(lion);
      final target = m.state.sides[1];
      final p = _shot(lion);
      expect(passNet(p, target, 5, 3, events: m.state.events), isTrue);
      expect(target.grid.hasBlock(5, 3), isFalse);
      expect(p.vx, 100000, reason: '속도 그대로');
    });
  });

  group('관통 고유 동작', () {
    test('나르는 인자 명까지 해적 피해를 줄이지 않고, 넘으면 해적 피해가 없다', () {
      final nar = _pirate(
        'nar',
        ammo: AmmoType.pierce,
        ability: Ability.skewer,
        abilityValue: 1,
        blockDamage: 10,
      );
      final m = _duel(nar);
      final crew = m.state.sides[1].crew;
      final p = _shot(nar)..pierceLeft = 5;
      final hp1 = crew.pirates[1].hp;
      final hp2 = crew.pirates[2].hp;
      _hit(m, p, 5, 2);
      _hit(m, p, 6, 2);
      expect(crew.pirates[1].hp, hp1 - 80);
      expect(crew.pirates[2].hp, hp2, reason: '인자 1명을 넘었다');
    });

    test('왈러스는 뚫고 지나간 블록이 구멍 단계가 되면 뜯어낸다', () {
      final wal = _pirate(
        'wal',
        ammo: AmmoType.pierce,
        ability: Ability.rip,
        blockDamage: 30,
      );
      final m = _duel(wal);
      final grid = m.state.sides[1].grid;
      _hit(m, _shot(wal)..pierceLeft = 1, 10, 1);
      expect(grid.hasBlock(10, 1), isFalse, reason: '소나무 40 − 30 = 구멍 단계');
    });

    test('소오는 처음 맞은 칸의 세로줄 모든 블록에 블록 피해 50% 를 준다', () {
      final saw = _pirate('saw', ammo: AmmoType.pierce, ability: Ability.saw);
      final m = _duel(saw);
      final grid = m.state.sides[1].grid;
      final oak = grid.hpAt(4, 0);
      _hit(m, _shot(saw)..pierceLeft = 1, 4, 2);
      expect(grid.hpAt(4, 0), oak - 20);
    });

    test('바라 어뢰는 중력 없이 물속으로 들어가 해수면에서 멈추지 않는다', () {
      final bara = _pirate(
        'bara',
        ammo: AmmoType.pierce,
        ability: Ability.torpedo,
      );
      final m = _duel(bara);
      final p = _shot(bara, vy: -20000, y: 100);
      armUnique(p);
      expect(p.gravity, isFalse);
      final step = traceStep(m.state, p, 0, 0, 1);
      expect(p.y, lessThan(0));
      expect(step.sea, isFalse);
    });
  });

  group('물수제비 고유 동작', () {
    test('셀던은 남은 튕김 수만큼 벽에서 되튄다', () {
      final shell = _pirate(
        'shell',
        ammo: AmmoType.skip,
        ability: Ability.ricochet,
      );
      final m = _duel(shell);
      final p = _shot(shell)..bouncesLeft = 1;
      expect(_hit(m, p, 10, 1), isFalse);
      expect(p.vx, lessThan(0));
      expect(p.bouncesLeft, 0);
      expect(_hit(m, p, 9, 1), isTrue);
    });

    test('돌피는 맞은 세로줄 흘수선 칸을 사다리 횟수 − 1 번 더 친다', () {
      final dolphin = _pirate(
        'dol',
        ammo: AmmoType.skip,
        ability: Ability.cling,
        value: 3,
      );
      final m = _duel(dolphin);
      final target = m.state.sides[1];
      final cell = waterlineCellIn(target, 10);
      final grid = target.grid;
      final cx = cell % grid.width;
      final cy = cell ~/ grid.width;
      final hp = grid.hpAt(cx, cy);
      _hit(m, _shot(dolphin), 10, 2);
      expect(grid.hpAt(cx, cy), lessThan(hp));
    });

    test('핑구는 진행 방향으로 갑판 맨 위 블록을 인자 칸만큼 절반으로 친다', () {
      final pingu = _pirate(
        'pingu',
        ammo: AmmoType.skip,
        ability: Ability.slide,
        abilityValue: 2,
      );
      final m = _duel(pingu);
      final grid = m.state.sides[1].grid;
      final before = [for (var x = 0; x < grid.width; x++) grid.hpAt(x, 1)];
      _hit(m, _shot(pingu, vx: -100000), 0, 1);
      final changed = [
        for (var x = 1; x < grid.width; x++)
          if (grid.hpAt(x, 1) != before[x] ||
              grid.hpAt(x, 2) != 0 && grid.stageAt(x, 2) != DamageStage.intact)
            x,
      ];
      expect(changed, isNotEmpty);
    });

    test('오르카는 침수를 더하고 드러난 갑판 해적을 쓸어낸다', () {
      final orca = _pirate(
        'orca',
        ammo: AmmoType.skip,
        ability: Ability.wave,
        abilityValue: 80,
      );
      final m = _duel(orca);
      final target = m.state.sides[1];
      final c = target.cabins[3];
      target.grid.removeAt(target.grid.indexOf(c.x, c.y));
      _hit(m, _shot(orca), 0, 1);
      expect(target.flood, 80);
      expect(target.crew.pirates[3].status, PirateStatus.swimming);
      expect(target.crew.pirates[0].status, PirateStatus.aboard);
    });
  });

  group('수중·공중 고유 동작', () {
    test('모레이는 상대 턴 시작에 물어뜯고 그 턴 끝 펌프를 멈춘다', () {
      final moray = _pirate(
        'moray',
        ammo: AmmoType.mine,
        ability: Ability.gnaw,
        abilityValue: 25,
      );
      final m = _duel(moray);
      final target = m.state.sides[1];
      final cell = target.grid.indexOf(10, 1);
      expect(attachUnique(m.state, _shot(moray), target, cell), isTrue);
      final hp = target.grid.hpAt(10, 1);
      m
        ..apply(const EndTurnCommand(t: 1000))
        ..apply(const TapCommand(t: 0, slot: 9, ticks: 0));
      expect(target.grid.hpAt(10, 1), hp - 25);
      expect(pumpsOffFor(m.state), isTrue);
    });

    test('크라키 촉수는 지속 턴 동안 상대 턴 끝마다 침수를 더한다', () {
      final kraki = _pirate(
        'kraki',
        ammo: AmmoType.mine,
        ability: Ability.tentacle,
        value: 2,
        value2: 40,
      );
      final m = _duel(kraki);
      final target = m.state.sides[1];
      attachUnique(m.state, _shot(kraki), target, target.grid.indexOf(10, 1));
      for (var i = 0; i < 6; i++) {
        m.apply(const EndTurnCommand(t: 1000));
      }
      expect(target.flood, greaterThanOrEqualTo(80));
      expect(m.state.effects, isEmpty, reason: '2턴 뒤 사라진다');
    });

    test('펠리 투하 표시는 상대 탄이 1칸 안을 지나면 요격된다', () {
      final m = _duel(testPirate('x'));
      m.state.effects.add(
        TurnEffect(
          kind: EffectKind.flockDrop,
          owner: 1,
          ownerSlot: 0,
          target: 0,
          trigger: 1,
          turnsLeft: 1,
          spec: testPirate('pelly'),
          x: 3000,
        ),
      );
      interceptDrops(
        m.state,
        _shot(testPirate('x'), x: 3500, y: flockDropHeight + 500),
      );
      expect(m.state.effects, isEmpty);
      expect(_of(m, SimEventKind.intercepted), hasLength(1));
    });

    test('만타 무작위 피해는 매치 난수로 고른 칸에 블록 피해 50% 를 준다', () {
      final manta = _pirate('manta', blockDamage: 60);
      final m = _duel(manta);
      final target = m.state.sides[1];
      final before = target.grid.totalHp;
      randomStrikes(m.state, target, manta, 3);
      expect(target.grid.totalHp, lessThan(before));
      expect(before - target.grid.totalHp, lessThanOrEqualTo(90));
    });
  });

  group('강습·지원 고유 동작', () {
    test('크래비는 착지 칸에서 가장 가까운 배 위 해적을 바다로 떨어뜨린다', () {
      final crab = _pirate(
        'crabby',
        ammo: AmmoType.assault,
        ability: Ability.grab,
      );
      final m = _duel(crab);
      final target = m.state.sides[1];
      applyHitAbility(m.state, _shot(crab), target, cx: 8, cy: 3);
      expect(target.crew.pirates[3].status, PirateStatus.swimming);
    });

    test('랍은 해적을 쓰러뜨리면 가장 가까운 다음 해적을 벤다', () {
      final lob = _pirate(
        'lob',
        ammo: AmmoType.assault,
        ability: Ability.leap,
        value: 1,
        pirateDamage: 400,
      );
      final m = _duel(lob);
      final crew = m.state.sides[1].crew;
      final hp = crew.pirates[1].hp;
      _hit(m, _shot(lob), 3, 2);
      expect(crew.pirates[0].status, PirateStatus.down);
      expect(crew.pirates[1].hp, lessThan(hp), reason: '(5,2) 가 가장 가깝다');
    });

    test('데비는 해골 선원을 소환하고, 한 번 쓰러지면 체력 절반으로 되살아난다', () {
      final davy = _pirate(
        'davy',
        ammo: AmmoType.assault,
        ability: Ability.summon,
        abilityValue: 3,
      );
      final m = _duel(davy);
      _hit(m, _shot(davy), 5, 2);
      final bites = m.state.effects.where(
        (e) => e.kind == EffectKind.biteAgain,
      );
      expect(bites, hasLength(3));
      expect(bites.first.spec.pirateDamage, 40);
      final mine = m.state.sides[0].crew..damage(0, 1000, 0, m.state.events);
      expect(mine.pirates[0].status, PirateStatus.aboard);
      expect(mine.pirates[0].hp, 150);
      mine.damage(0, 1000, 0, m.state.events);
      expect(mine.pirates[0].status, PirateStatus.down);
    });

    test('쿡은 착지 둘레 2칸 선실의 아군을 치유한다', () {
      final cook = _pirate(
        'cook',
        ammo: AmmoType.support,
        ability: Ability.cooldownCut,
        abilityValue: 1,
        value: 100,
      );
      final m = _duel(cook);
      final ship = m.state.sides[0];
      ship.crew.pirates[1].hp = 100;
      onSupportHit(m.state, _shot(cook), ship, x: 0);
      expect(ship.crew.pirates[1].hp, 100 + cookHeal);
    });

    test('코리 방벽은 상대 탄을 막고 깎이며, 세운 쪽 턴이 지나면 사라진다', () {
      final coral = _pirate(
        'coral',
        ammo: AmmoType.support,
        ability: Ability.coral,
        abilityValue: 2,
        value: 100,
      );
      final m = _duel(coral);
      placeCoral(m.state, _shot(coral), 2000);
      final enemy = _shot(testPirate('e'), side: 1);
      final b = barrierCrossed(m.state, enemy, 3000, 1000, 1000, 1500);
      expect(b, isNotNull);
      expect(barrierCrossed(m.state, enemy, 3000, 9000, 1000, 9000), isNull);
      expect(
        barrierCrossed(m.state, _shot(coral), 3000, 1000, 1000, 1500),
        isNull,
        reason: '내 탄은 막지 않는다',
      );
      hitBarrier(m.state, enemy, b!);
      expect(b.hp, coralBaseHp - 60);
      for (var i = 0; i < 4; i++) {
        m.apply(const EndTurnCommand(t: 1000));
      }
      m.apply(const TapCommand(t: 0, slot: 9, ticks: 0));
      expect(m.state.barriers, isEmpty);
    });
  });

  test('R1a-2 해적이 섞인 판은 고정 해시로 끝나고, 같은 커맨드·재생이면 같다', () {
    PirateSpec p(
      String id,
      AmmoType ammo,
      Ability ability, {
      int av = 0,
      int v = 0,
      int v2 = 0,
    }) => _pirate(
      id,
      ammo: ammo,
      ability: ability,
      abilityValue: av,
      value: v,
      value2: v2,
      blastRadius: 1,
    );
    final pirates = [
      p('t', AmmoType.explosive, Ability.twin, v: 50),
      p('d', AmmoType.explosive, Ability.drill, av: 3, v: 50),
      p('s', AmmoType.pierce, Ability.saw, v: 2),
      p('w', AmmoType.skip, Ability.wave, av: 80, v: 2),
      p('g', AmmoType.mine, Ability.gnaw, av: 25, v: 1, v2: 20),
      p('k', AmmoType.mine, Ability.tentacle, av: 3, v: 2, v2: 40),
      p('c', AmmoType.support, Ability.coral, av: 2, v: 100),
      p('l', AmmoType.assault, Ability.leap, v: 1),
    ];
    Match start() => Match.start(
      seed: 777,
      blueprints: [sampleBlueprint(), sampleBlueprint()],
      decks: const [
        ['t', 'd', 's', 'w'],
        ['g', 'k', 'c', 'l'],
      ],
      costLimits: const [15, 15],
      pirates: PirateCatalog(pirates),
    );
    final seen = <SimEventKind>[];
    final a = start();
    runMatch(
      a,
      _Recorder(RandomController(33), seen),
      _Recorder(RandomController(34), seen),
    );
    seen.addAll(a.state.events.map((e) => e.kind));
    expect(hashMatchState(a.state), _mixedHash);
    for (final k in [
      SimEventKind.mineAttached,
      SimEventKind.effectFired,
      SimEventKind.barrierPlaced,
      SimEventKind.barrierHit,
      SimEventKind.bounce,
    ]) {
      expect(seen, contains(k), reason: '이 판에서 ${k.name} 이 일어난다');
    }
    final b = start();
    runMatch(b, RandomController(33), RandomController(34));
    expect(hashMatchState(b.state), _mixedHash);
    final c = start();
    a.turnLog.forEach(c.playTurn);
    expect(hashMatchState(c.state), _mixedHash);
  });
}
