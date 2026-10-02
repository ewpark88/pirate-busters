import 'package:pb_sim/pb_sim.dart';
import 'package:pb_sim/src/combat/ability_effects.dart';
import 'package:pb_sim/src/combat/fire.dart';
import 'package:pb_sim/src/combat/module_effects.dart';
import 'package:pb_sim/src/combat/support_effects.dart';
import 'package:pb_sim/src/match/turn_end.dart';
import 'package:test/test.dart';

import 'aim.dart';
import 'fixtures.dart';

/// R1a-1 시험용 해적 (설계서 §4.8 고유 효과 공통 규칙, ADR-075).
PirateSpec _pirate(
  String id, {
  AmmoType ammo = AmmoType.explosive,
  Ability ability = Ability.none,
  int abilityValue = 0,
  int value = 0,
  int value2 = 0,
  int param = 0,
  Family family = Family.lob,
  int pirateDamage = 80,
  int blastRadius = 0,
}) => PirateSpec(
  id: id,
  rarity: Rarity.common,
  hp: 300,
  cooldownTurns: 0,
  blockDamage: 40,
  pirateDamage: pirateDamage,
  blastRadius: blastRadius,
  range: RangeGrade.long,
  family: family,
  ammo: ammo,
  ammoValue: value,
  ammoValue2: value2,
  ammoParam: param,
  ability: ability,
  abilityValue: abilityValue,
);

/// 왼쪽(0) 에 [spec] 과 보조 해적, 오른쪽(1) 에 기본 해적 4명. 파도 없음.
/// 왼쪽 턴이 올 때까지 넘기고 그 턴을 연다.
Match _duel(PirateSpec spec, {int seed = 11}) {
  final m = Match.start(
    seed: seed,
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
  _passTo(m, 0);
  return m;
}

void _passTo(Match m, int side) {
  while (m.state.activeSide != side) {
    m.apply(const EndTurnCommand(t: 1000));
  }
  m.apply(const TapCommand(t: 0, slot: 9, ticks: 0));
}

/// 판 진행 중 나온 이벤트 종류를 모으는 컨트롤러 (턴을 고르기 전 직전 턴 이벤트를 본다).
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

/// R1a-1 섞인 판(시드 4242, 스크립트 35·36)의 기대 해시. 의도한 규칙 변경일 때만 갱신한다.
const int _mixedHash = 473789135;

List<SimEvent> _of(Match m, SimEventKind kind) =>
    m.state.events.where((e) => e.kind == kind).toList();

Projectile _shot(Match m, PirateSpec spec, {int vx = 100000, int vy = 0}) =>
    Projectile(
      id: 0,
      side: 0,
      slot: 0,
      spec: spec,
      x: 0,
      y: 5000,
      vx: vx,
      vy: vy,
    );

void main() {
  group('화재 (설계서 §2.5, BALANCE.md A2.5)', () {
    test('화상 지대는 둘레 3×3 블록에 불을 붙이고 철판에는 붙지 않는다', () {
      final m = _duel(testPirate('x'));
      final ship = m.state.sides[1];
      final grid = ship.grid;
      igniteAround(
        ship,
        3,
        2,
        radius: fireZoneRadius,
        turns: 2,
        extraPercent: 50,
        events: m.state.events,
      );
      expect(ship.fireTurns[grid.indexOf(3, 2)], 2);
      expect(ship.fireTurns[grid.indexOf(4, 1)], 2);
      expect(ship.fireExtra[grid.indexOf(4, 3)], 50, reason: '망사도 나무');
      expect(ship.fireTurns[grid.indexOf(2, 2)], 0, reason: '철판 면역');
      expect(_of(m, SimEventKind.ignited), isNotEmpty);
    });

    test('물에 잠긴 줄에는 불이 붙지 않는다', () {
      final m = _duel(testPirate('x'));
      final ship = m.state.sides[1];
      expect(submersionOf(0, ship.draft), isNot(Submersion.dry));
      igniteAround(
        ship,
        5,
        0,
        radius: 0,
        turns: 2,
        extraPercent: 0,
        events: m.state.events,
      );
      expect(ship.fireTurns[ship.grid.indexOf(5, 0)], 0);
    });

    test('턴 끝마다 블록이 10 × (1 + 나무 추가 피해) 타고 지속 턴이 지나면 꺼진다', () {
      final m = _duel(testPirate('x'));
      final ship = m.state.sides[1];
      final grid = ship.grid;
      final i = grid.indexOf(10, 1);
      igniteAround(
        ship,
        10,
        1,
        radius: 0,
        turns: 2,
        extraPercent: 50,
        events: m.state.events,
      );
      final hp = grid.hpAt(10, 1);
      burnAtTurnEnd(ship, m.state.rng, m.state.events);
      expect(grid.hpAt(10, 1), hp - 15);
      expect(ship.fireTurns[i], 1);
      burnAtTurnEnd(ship, m.state.rng, m.state.events);
      expect(grid.hpAt(10, 1), hp - 30);
      expect(ship.fireTurns[i], 0);
      expect(ship.fireExtra[i], 0);
    });

    test('불붙은 선실 칸의 해적은 턴 끝마다 10 피해를 입는다', () {
      final m = _duel(testPirate('x'));
      final ship = m.state.sides[1];
      final c = ship.cabins[1];
      igniteAround(
        ship,
        c.x,
        c.y,
        radius: 0,
        turns: 1,
        extraPercent: 0,
        events: m.state.events,
      );
      final hp = ship.crew.pirates[1].hp;
      burnAtTurnEnd(ship, m.state.rng, m.state.events);
      expect(ship.crew.pirates[1].hp, hp - firePirateDamage);
    });

    test('불은 그 배 주인의 턴 끝 처리 첫 단계에서 탄다 (§2.3)', () {
      final m = _duel(testPirate('x'));
      final mine = m.state.sides[0];
      igniteAround(
        mine,
        10,
        1,
        radius: 0,
        turns: 1,
        extraPercent: 0,
        events: m.state.events,
      );
      m.apply(const EndTurnCommand(t: 1000));
      expect(_of(m, SimEventKind.burned), hasLength(1));
      expect(_of(m, SimEventKind.burned).single.side, 0);
    });

    test('화약고가 터지면 둘레 칸에 불이 붙는다 (§3.3)', () {
      final blueprint = Blueprint(
        HullSpec.sloop,
        sampleBlueprint().cells,
        cabins: sampleCabins,
        modules: const [
          ModuleCell(11, 1, ModuleKind.captain),
          ModuleCell(7, 1, ModuleKind.magazine),
        ],
      );
      final ship = SideState(
        side: 1,
        blueprint: blueprint,
        lineup: [testPirate('r0')],
        rules: const MatchRules(waveLevel: 0),
      );
      final events = <SimEvent>[];
      ship.grid.removeAt(ship.grid.indexOf(7, 1));
      settleModules(ship, events, rng: XorShift32(3));
      expect(events.where((e) => e.kind == SimEventKind.ignited), isNotEmpty);
    });

    test('화염탄이 배에 맞으면 사다리 지속 턴으로 불이 붙는다 (§4.8)', () {
      final star = _pirate('star', ammo: AmmoType.fire, value: 2, value2: 50);
      final m = _duel(star);
      final c = m.state.sides[1].cabins[0];
      m.apply(aimAt(m.state, slot: 0, tx: c.x, ty: c.y, highArc: true));
      final ignited = _of(m, SimEventKind.ignited);
      expect(ignited, isNotEmpty);
      final ship = m.state.sides[1];
      expect(ship.fireTurns.where((t) => t == 2), isNotEmpty);
    });
  });

  group('연쇄탄 (§4.8, BALANCE.md A4.8)', () {
    final bolt = _pirate('bolt', ammo: AmmoType.chain, value: 2);

    test('맞은 해적에서 가까운 순으로 사다리 수만큼 50% 피해가 번진다', () {
      final m = _duel(bolt);
      final target = m.state.sides[1];
      final c = target.cabins[0];
      final from = m.state.events.length;
      target.crew.damage(0, 80, 1, m.state.events);
      final hp = [for (final p in target.crew.pirates) p.hp];
      spreadChain(
        m.state,
        target,
        bolt,
        cx: c.x,
        cy: c.y,
        from: from,
        candidates: const [0],
      );
      final chained = _of(m, SimEventKind.chained).map((e) => e.slot);
      expect(chained, [1, 2], reason: '(5,2)·(6,2) 가 (8,2) 보다 가깝다');
      expect(target.crew.pirates[1].hp, hp[1] - 40);
      expect(target.crew.pirates[3].hp, hp[3]);
    });

    test('해적을 맞히지 못하면 번지지 않는다', () {
      final m = _duel(bolt);
      final from = m.state.events.length;
      spreadChain(
        m.state,
        m.state.sides[1],
        bolt,
        cx: 3,
        cy: 2,
        from: from,
        candidates: const [0],
      );
      expect(_of(m, SimEventKind.chained), isEmpty);
    });

    test('착탄 범위 밖 해적의 낙하 피해로는 번지지 않는다', () {
      final m = _duel(bolt);
      final target = m.state.sides[1];
      expect(
        chainStruckCandidates(target, bolt, cx: 3, cy: 2),
        [0],
        reason: '반경 0 이면 착탄 칸 선실만',
      );
      final from = m.state.events.length;
      target.crew.fall(3, 1, m.state.events);
      spreadChain(
        m.state,
        target,
        bolt,
        cx: 3,
        cy: 2,
        from: from,
        candidates: const [0],
      );
      expect(_of(m, SimEventKind.chained), isEmpty);
    });
  });

  group('상태 효과 (§4.8 고유 효과 공통 규칙)', () {
    test('끌어당기면 구간 안에서만 끌리고 다음 상대 턴에 움직이지 못한다', () {
      final moby = _pirate(
        'moby',
        ammo: AmmoType.pierce,
        ability: Ability.pull,
        abilityValue: 3,
      );
      final m = _duel(moby);
      final target = m.state.sides[1]..offset = moveRange - 1000;
      applyHitAbility(m.state, _shot(m, moby), target, cx: 0, cy: 1);
      expect(target.offset, moveRange, reason: '남는 2칸은 버린다');
      expect(target.moveLocked, isFalse, reason: '건 턴에는 아직 아니다');
      target.turnNow = m.state.turn + 1;
      expect(target.moveLocked, isTrue);
      expect(moveReach(target, m.state.rules, m.state.turn + 1, 30, 9000), 0);
      target.turnNow = m.state.turn + 2;
      expect(target.moveLocked, isFalse, reason: '그 턴이 지나면 풀린다');
    });

    test('관통탄이 여러 칸을 맞아도 끌기는 한 번이다', () {
      final moby = _pirate(
        'moby',
        ammo: AmmoType.pierce,
        ability: Ability.pull,
        abilityValue: 3,
      );
      final m = _duel(moby);
      final target = m.state.sides[1];
      final p = _shot(m, moby);
      applyHitAbility(m.state, p, target, cx: 0, cy: 1);
      applyHitAbility(m.state, p, target, cx: 1, cy: 1);
      expect(target.offset, 3000);
    });

    test('선실 봉쇄는 착지 칸에서 가장 가까운 선실을 다음 상대 턴에만 막는다', () {
      final king = _pirate(
        'king',
        ammo: AmmoType.assault,
        ability: Ability.sealCabin,
      );
      final m = _duel(king);
      final target = m.state.sides[1];
      applyHitAbility(m.state, _shot(m, king), target, cx: 6, cy: 3);
      expect(target.status.sealedSlot, 2);
      target.turnNow = m.state.turn + 1;
      expect(target.canFire(2), isFalse);
      expect(target.canFire(1), isTrue);
    });

    test('궤적 봉쇄는 다음 상대 턴 0% 이고 같은 턴의 확대보다 앞선다', () {
      final manta = _pirate('manta', ability: Ability.blindTrail);
      final m = _duel(manta);
      final target = m.state.sides[1];
      applyHitAbility(m.state, _shot(m, manta), target, cx: 5, cy: 2);
      target.status.trailBoostTurn = m.state.turn + 1;
      target.turnNow = m.state.turn + 1;
      expect(target.trailOverride, 0);
    });

    test('봉쇄가 걸린 턴에 램프를 써도 그 턴 봉쇄는 남는다', () {
      final lamp = _pirate(
        'lamp',
        ammo: AmmoType.support,
        ability: Ability.lantern,
        abilityValue: 30,
        value: 100,
      );
      final m = _duel(lamp);
      final ship = m.state.sides[0];
      final now = m.state.turn;
      ship.status.trailBlockTurn = now;
      onSupportHit(m.state, _shot(m, lamp), ship, cx: 5, cy: 2, x: 0);
      expect(ship.trailOverride, 0, reason: '지금 턴 봉쇄 유지');
      ship.turnNow = now + 2;
      expect(ship.trailOverride, 100, reason: '다음 내 턴 확대');
    });

    test('바람 역전은 다음 상대 턴 바람을 뒤집고, 바람 무시가 앞선다', () {
      final alba = _pirate(
        'alba',
        ammo: AmmoType.homing,
        ability: Ability.steer,
      );
      final m = _duel(alba);
      final next = m.state.turn + 1;
      final base = m.state.rules.windForTurn(m.state.seed, next);
      final target = m.state.sides[1];
      applyHitAbility(m.state, _shot(m, alba), target, cx: 5, cy: 2);
      expect(windOf(m.state, next), -base);
      target.status.windIgnoreTurn = next;
      expect(windOf(m.state, next), 0);
    });

    test('바람 역전은 실제로 다음 턴 바람에 들어간다', () {
      final alba = _pirate(
        'alba',
        ammo: AmmoType.homing,
        ability: Ability.steer,
      );
      final m = _duel(alba);
      final next = m.state.turn + 1;
      final base = m.state.rules.windForTurn(m.state.seed, next);
      m.state.sides[1].status.windReverseTurn = next;
      m.apply(const EndTurnCommand(t: 1000));
      expect(m.state.wind, -base);
      expect(m.state.sides[1].turnNow, next);
    });
  });

  group('방향 전환 탭 (알바)', () {
    final alba = _pirate(
      'alba',
      ammo: AmmoType.homing,
      ability: Ability.steer,
    );

    test('위로 꺾으면 앞으로 가는 탄의 세로 속도가 커지고, 한 번만 꺾인다', () {
      final m = _duel(alba);
      final p = _shot(m, alba);
      expect(steerOnTap(m.state, p, 1, 5), isTrue);
      expect(p.vy, greaterThan(0));
      expect(p.vx, lessThan(100000));
      final vy = p.vy;
      expect(steerOnTap(m.state, p, -1, 6), isFalse);
      expect(p.vy, vy);
    });

    test('아래로 꺾으면 세로 속도가 음수가 된다', () {
      final m = _duel(alba);
      final p = _shot(m, alba);
      steerOnTap(m.state, p, -1, 5);
      expect(p.vy, lessThan(0));
    });

    test('쏘면 TAP 을 기다리고, TAP 틱에 꺾인다', () {
      final m = _duel(alba)
        ..apply(const FireCommand(t: 1000, slot: 0, angle: 30000, power: 8000));
      expect(m.pendingSlot, 0);
      m.apply(const TapCommand(t: 1500, slot: 0, ticks: 10, dir: 1));
      expect(m.pendingSlot, -1);
      final steered = _of(m, SimEventKind.steered);
      expect(steered, hasLength(1));
      expect(steered.single.value, 10);
    });
  });

  group('떠 있는 기뢰 (젤리)', () {
    final jelly = _pirate(
      'jelly',
      ammo: AmmoType.mine,
      ability: Ability.floatMine,
      value: 2,
      value2: 30,
    );

    test('상대 배가 이동하다 지나가면 터지고 침수가 오른다', () {
      final m = _duel(jelly);
      final target = m.state.sides[1];
      final x = target.bowX - 2 * cellUnit;
      placeFloatMine(m.state, _shot(m, jelly), target, x);
      _passTo(m, 1);
      final flood = target.flood;
      m.apply(const MoveCommand(t: 1000, dx: 40));
      final fired = _of(m, SimEventKind.effectFired);
      expect(fired, hasLength(1));
      expect(fired.single.value, EffectKind.floatMine.index);
      expect(target.flood, greaterThanOrEqualTo(flood + 30));
      expect(m.state.effects, isEmpty);
    });

    test('지나가지 않으면 지속 턴이 지난 뒤 터지지 않고 사라진다', () {
      final m = _duel(jelly);
      final target = m.state.sides[1];
      placeFloatMine(
        m.state,
        _shot(m, jelly),
        target,
        target.bowX - 8 * cellUnit,
      );
      for (var i = 0; i < 4; i++) {
        m.apply(const EndTurnCommand(t: 1000));
      }
      _passTo(m, 0);
      expect(m.state.effects, isEmpty);
      expect(_of(m, SimEventKind.effectFired), isEmpty);
      expect(target.flood, 0);
    });
  });

  group('지원 효과 (§4.2, BALANCE.md A4.2)', () {
    test('배수는 침수량을 인자 × 지원 배율만큼 줄인다', () {
      final pump = _pirate(
        'pump',
        ammo: AmmoType.support,
        ability: Ability.bail,
        abilityValue: 150,
        value: 110,
      );
      final m = _duel(pump);
      final ship = m.state.sides[0]..flood = 300;
      onSupportHit(m.state, _shot(m, pump), ship, cx: 5, cy: 2, x: 0);
      expect(ship.flood, 300 - 165);
    });

    test('쿨다운 감소는 쏜 해적을 포함한 아군 전체를 줄이고 0 아래로 내리지 않는다', () {
      final cook = _pirate(
        'cook',
        ammo: AmmoType.support,
        ability: Ability.cooldownCut,
        abilityValue: 1,
        value: 100,
      );
      final m = _duel(cook);
      final ship = m.state.sides[0];
      ship.crew.pirates[0].cooldown = 2;
      ship.crew.pirates[1].cooldown = 0;
      onSupportHit(m.state, _shot(m, cook), ship, cx: 5, cy: 2, x: 0);
      expect(ship.crew.pirates[0].cooldown, 1);
      expect(ship.crew.pirates[1].cooldown, 0);
    });

    test('램프는 연료를 채우고 다음 내 턴 궤적 100%·바람 무시를 건다', () {
      final lamp = _pirate(
        'lamp',
        ammo: AmmoType.support,
        ability: Ability.lantern,
        abilityValue: 30,
        value: 100,
      );
      final m = _duel(lamp);
      final ship = m.state.sides[0]..fuel = 0;
      onSupportHit(m.state, _shot(m, lamp), ship, cx: 5, cy: 2, x: 0);
      expect(ship.fuel, 30 * SideState.fuelUnit);
      final mine = m.state.turn + 2;
      expect(ship.status.windIgnoreTurn, mine);
      ship.turnNow = mine;
      expect(ship.trailOverride, 100);
      expect(windOf(m.state, mine), 0);
    });
  });

  test('새 능력 해적이 섞인 판은 고정 해시로 끝나고, 같은 커맨드·재생이면 같다', () {
    final pirates = [
      _pirate('f', ammo: AmmoType.fire, value: 2, value2: 50, blastRadius: 1),
      _pirate('c', ammo: AmmoType.chain, value: 1, blastRadius: 1),
      _pirate(
        'a',
        ammo: AmmoType.homing,
        ability: Ability.steer,
        value: 45,
        blastRadius: 1,
      ),
      _pirate(
        'm',
        ammo: AmmoType.pierce,
        ability: Ability.pull,
        abilityValue: 3,
        value: 2,
        blastRadius: 1,
      ),
      _pirate(
        'k',
        ammo: AmmoType.assault,
        ability: Ability.sealCabin,
        value: 1,
        blastRadius: 1,
      ),
      _pirate(
        'j',
        ammo: AmmoType.mine,
        ability: Ability.floatMine,
        value: 2,
        value2: 30,
        blastRadius: 1,
      ),
      _pirate(
        'l',
        ammo: AmmoType.support,
        ability: Ability.lantern,
        abilityValue: 30,
        value: 100,
        blastRadius: 1,
      ),
      _pirate(
        'b',
        ammo: AmmoType.support,
        ability: Ability.bail,
        abilityValue: 150,
        value: 100,
        blastRadius: 1,
      ),
    ];
    Match start() => Match.start(
      seed: 4242,
      blueprints: [sampleBlueprint(), sampleBlueprint()],
      decks: const [
        ['f', 'c', 'a', 'm'],
        ['k', 'j', 'l', 'b'],
      ],
      costLimits: const [15, 15],
      pirates: PirateCatalog(pirates),
    );
    final seen = <SimEventKind>[];
    final a = start();
    runMatch(
      a,
      _Recorder(RandomController(35), seen),
      _Recorder(RandomController(36), seen),
    );
    seen.addAll(a.state.events.map((e) => e.kind));
    expect(hashMatchState(a.state), _mixedHash);
    for (final k in [
      SimEventKind.ignited,
      SimEventKind.burned,
      SimEventKind.chained,
      SimEventKind.statusApplied,
      SimEventKind.mineFloated,
      SimEventKind.steered,
    ]) {
      expect(seen, contains(k), reason: '이 판에서 ${k.name} 이 일어난다');
    }
    final b = start();
    runMatch(b, RandomController(35), RandomController(36));
    expect(hashMatchState(b.state), _mixedHash);
    final c = start();
    a.turnLog.forEach(c.playTurn);
    expect(hashMatchState(c.state), _mixedHash);
  });
}
