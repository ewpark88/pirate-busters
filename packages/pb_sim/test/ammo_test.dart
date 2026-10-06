import 'package:pb_sim/pb_sim.dart';
import 'package:pb_sim/src/combat/ammo_rules.dart';
import 'package:pb_sim/src/combat/flight.dart';
import 'package:pb_sim/src/combat/hit_effects.dart';
import 'package:test/test.dart';

import 'aim.dart';
import 'fixtures.dart';

/// 탄종 시험용 해적: 기본은 투척 계열 일반 등급, 반경 0.
PirateSpec _ammoPirate(
  AmmoType ammo, {
  int value = 0,
  int value2 = 0,
  int param = 0,
  int spread = 0,
  Family family = Family.lob,
  int blockDamage = 40,
  int pirateDamage = 80,
  int blastRadius = 0,
}) => PirateSpec(
  id: 'a_${ammo.jsonName}',
  rarity: Rarity.common,
  hp: 300,
  cooldownTurns: 0,
  blockDamage: blockDamage,
  pirateDamage: pirateDamage,
  blastRadius: blastRadius,
  range: RangeGrade.long,
  family: family,
  ammo: ammo,
  ammoValue: value,
  ammoValue2: value2,
  spreadMdeg: spread,
  ammoParam: param,
);

/// 왼쪽(0) 에 [spec] 해적과 보조 해적, 오른쪽(1) 에 기본 해적 둘. 파도 없음.
/// 왼쪽 턴이 올 때까지 넘긴다.
Match _duel(PirateSpec spec, {int seed = 11}) {
  final m = Match.start(
    seed: seed,
    rules: const MatchRules(waveLevel: 0),
    blueprints: [sampleBlueprint(), sampleBlueprint()],
    decks: [
      [spec.id, 'r0'],
      ['r0', 'r1'],
    ],
    costLimits: const [15, 15],
    pirates: PirateCatalog([spec, testPirate('r0'), testPirate('r1')]),
  );
  _passTo(m, 0);
  return m;
}

/// [side] 진영 턴이 될 때까지 넘기고, 그 턴을 연다(턴 시작 효과가 이벤트에 남는다).
void _passTo(Match m, int side) {
  while (m.state.activeSide != side) {
    m.apply(const EndTurnCommand(t: 1000));
  }
  m.apply(const TapCommand(t: 0, slot: 9, ticks: 0));
}

/// 상대 배에서 부서진 블록 중 망사가 아닌 것의 수. 샘플 배의 망사(4..7, 3)는
/// 탄이 지나가며 부서진다 (설계서 §3.2).
int _solidDestroyed(Match m) {
  final w = m.state.sides[1].grid.width;
  return _of(m, SimEventKind.blockDestroyed)
      .where(
        (e) =>
            e.side == 1 &&
            !(e.cell ~/ w == 3 && e.cell % w >= 4 && e.cell % w <= 7),
      )
      .length;
}

List<SimEvent> _of(Match m, SimEventKind kind) =>
    m.state.events.where((e) => e.kind == kind).toList();

/// 상대 배 2층 이상 블록(선실 포함)을 모두 걷어 해적이 갑판에 드러난 [_duel].
/// 해적은 떨어지지 않고 선실 자리에 그대로 선다.
Match _exposed(PirateSpec spec) {
  final m = _duel(spec);
  final grid = m.state.sides[1].grid;
  for (var i = 0; i < grid.cellCount; i++) {
    if (i ~/ grid.width >= 2 && grid.hasBlockAt(i)) grid.removeAt(i);
  }
  return m;
}

/// 상대 배 [slot] 선실 칸을 노린 발사.
FireCommand _atCabin(Match m, {bool highArc = true, int slot = 0}) {
  final c = m.state.sides[1].cabins[slot];
  return aimAt(m.state, slot: 0, tx: c.x, ty: c.y, highArc: highArc);
}

void main() {
  group('분열탄 (설계서 §4.8)', () {
    final uni = _ammoPirate(AmmoType.split, value: 4, spread: 25000);

    test('쏜 뒤 TAP 을 기다리고, TAP 틱에 4조각으로 갈라진다', () {
      final m = _duel(uni);
      m.apply(_atCabin(m));
      expect(m.pendingSlot, 0);
      expect(_of(m, SimEventKind.impact), isEmpty, reason: '아직 계산 전');
      m.apply(const TapCommand(t: 1000, slot: 0, ticks: 20));
      expect(m.pendingSlot, -1);
      final divide = _of(m, SimEventKind.divide);
      expect(divide, hasLength(1));
      expect(divide.single.value, 20);
      expect(m.state.lastTraces, hasLength(5));
      expect(
        [for (final t in m.state.lastTraces.skip(1)) t.startTick],
        [20, 20, 20, 20],
      );
    });

    test('TAP 없이 다른 커맨드가 오면 갈라지지 않고 계산한다', () {
      final m = _duel(uni);
      m
        ..apply(_atCabin(m))
        ..apply(const EndTurnCommand(t: 9000));
      expect(m.state.activeSide, 1);
      final commands = m.turnLog.last.commands;
      expect(commands.whereType<FireCommand>(), hasLength(1));
      expect(commands.last, isA<EndTurnCommand>());
      expect(_of(m, SimEventKind.divide), isEmpty);
    });

    test('기다리던 분열탄을 지금 계산해도 다음 커맨드에서 계산한 것과 해시가 같다', () {
      final a = _duel(uni)
        ..apply(_atCabin(_duel(uni)))
        ..settlePending();
      expect(a.pendingSlot, -1);
      a.apply(const EndTurnCommand(t: 9000));
      final b = _duel(uni)
        ..apply(_atCabin(_duel(uni)))
        ..apply(const EndTurnCommand(t: 9000));
      expect(hashMatchState(a.state), hashMatchState(b.state));
    });

    test('분열 조각 피해는 합계 140% 를 4조각에 나눈다', () {
      final m = _duel(uni);
      final before = m.state.nextProjectileId;
      m
        ..apply(_atCabin(m))
        ..apply(const TapCommand(t: 1000, slot: 0, ticks: 10));
      expect(m.state.nextProjectileId - before, 5);
      expect(perShotDamage(40, 0, 4), 14);
    });

    test('같은 턴 묶음을 다시 재생하면 해시가 같다 (분열 탭 재현)', () {
      final m = _duel(uni);
      m
        ..apply(_atCabin(m))
        ..apply(const TapCommand(t: 1000, slot: 0, ticks: 18))
        ..apply(const EndTurnCommand(t: 9000));
      final log = m.turnLog;
      final again = Match.start(
        seed: 11,
        rules: const MatchRules(waveLevel: 0),
        blueprints: [sampleBlueprint(), sampleBlueprint()],
        decks: [
          [uni.id, 'r0'],
          ['r0', 'r1'],
        ],
        costLimits: const [15, 15],
        pirates: PirateCatalog([uni, testPirate('r0'), testPirate('r1')]),
      );
      log.forEach(again.playTurn);
      expect(hashMatchState(again.state), hashMatchState(m.state));
      expect(log.last.hash, isNotNull);
    });
  });

  test('연사탄: 발수만큼 3틱 간격으로 쏘고 발마다 피해를 나눈다', () {
    final hippo = _ammoPirate(
      AmmoType.burst,
      value: 3,
      spread: 4000,
      family: Family.direct,
    );
    final m = _duel(hippo);
    m.apply(_atCabin(m, highArc: false));
    expect(_of(m, SimEventKind.fire), hasLength(1));
    expect(
      [for (final t in m.state.lastTraces) t.startTick],
      [0, 3, 6],
    );
  });

  test('저격탄: 선실 해적 명중 피해에 치명 배율을 곱한다', () {
    final pang = _ammoPirate(AmmoType.sniper, value: 150, pirateDamage: 100);
    final m = _exposed(pang);
    m.apply(_atCabin(m, slot: 1));
    final hit = _of(m, SimEventKind.pirateHit).where((e) => e.side == 1);
    expect(hit.single.value, 150);
  });

  test('관통탄: 부서진 블록을 뚫고 다음 칸까지 피해를 준다', () {
    PirateSpec spec(AmmoType a) => _ammoPirate(a, value: 3, blockDamage: 2000);
    int destroyed(AmmoType a) {
      final m = _duel(spec(a));
      final c = m.state.sides[1].cabins[0];
      m.apply(aimAt(m.state, slot: 0, tx: c.x, ty: c.y));
      return _solidDestroyed(m);
    }

    expect(destroyed(AmmoType.explosive), 1);
    expect(destroyed(AmmoType.pierce), greaterThan(1));
  });

  test('물수제비탄: 바다에 떨어지면 튕기고 튕김 수를 넘지 않는다', () {
    final suri = _ammoPirate(AmmoType.skip, value: 2);
    final m = _duel(suri)
      ..apply(const FireCommand(t: 1000, slot: 0, angle: 8000, power: 4000));
    final bounces = _of(m, SimEventKind.bounce);
    expect(bounces, isNotEmpty);
    expect(bounces.length, lessThanOrEqualTo(2));
  });

  test('설치탄: 선체에 붙고, 다음 내 턴 시작에 터져 침수를 더한다', () {
    final puffy = _ammoPirate(
      AmmoType.mine,
      value: 1,
      value2: 20,
      blastRadius: 1,
    );
    final m = _duel(puffy);
    m.apply(_atCabin(m));
    expect(_of(m, SimEventKind.mineAttached), hasLength(1));
    expect(_solidDestroyed(m), 0, reason: '지나간 망사만 부서진다');
    expect(m.state.effects, hasLength(1));
    final flood = m.state.sides[1].flood;
    m.apply(const EndTurnCommand(t: 9000));
    _passTo(m, 0);
    expect(_of(m, SimEventKind.effectFired), hasLength(1));
    expect(m.state.effects, isEmpty);
    expect(m.state.sides[1].flood, greaterThanOrEqualTo(flood + 20));
  });

  test('유도탄: 중력 없이 날며 선회력이 있으면 위로 쏴도 해적 쪽으로 꺾여 맞힌다', () {
    int impacts(int turn) {
      final m = _duel(_ammoPirate(AmmoType.homing, value: turn))
        ..apply(const FireCommand(t: 1000, slot: 0, angle: 20000, power: 6000));
      return _of(m, SimEventKind.impact).length;
    }

    expect(impacts(0), 0, reason: '선회력 0 이면 곧게 날아 사라진다');
    expect(impacts(90), 1);
  });

  test('다중투하(윙): 꼭대기에서 폭탄 3개로 갈라진다', () {
    final wing = _ammoPirate(AmmoType.flock, value: 3, family: Family.air);
    final m = _duel(wing)
      ..apply(const FireCommand(t: 1000, slot: 0, angle: 60000, power: 8000));
    expect(_of(m, SimEventKind.divide), hasLength(1));
    expect(m.state.lastTraces, hasLength(4));
  });

  test('다중투하(펠리): 떨어진 곳을 표시하고 다음 내 턴 시작에 4개를 떨군다', () {
    final pelly = _ammoPirate(
      AmmoType.flock,
      value: 4,
      param: 1,
      family: Family.air,
    );
    final m = _duel(pelly);
    m.apply(_atCabin(m));
    expect(_of(m, SimEventKind.divide), isEmpty);
    expect(m.state.effects.single.kind, EffectKind.flockDrop);
    m.apply(const EndTurnCommand(t: 9000));
    _passTo(m, 0);
    expect(_of(m, SimEventKind.effectFired), hasLength(1));
    expect(m.state.lastTraces, hasLength(4));
  });

  test('강습탄: 착지해 물고, 다음 상대 턴 시작에 한 번 더 문다', () {
    final sharky = _ammoPirate(
      AmmoType.assault,
      value: 1,
      blockDamage: 20,
      pirateDamage: 90,
      blastRadius: 1,
    );
    final m = _exposed(sharky);
    m.apply(_atCabin(m, slot: 1));
    expect(m.state.effects.single.kind, EffectKind.biteAgain);
    final hp = m.state.sides[1].crew.pirates[1].hp;
    expect(hp, lessThan(300), reason: '착지해 문다');
    m.apply(const EndTurnCommand(t: 9000));
    _passTo(m, 1);
    expect(_of(m, SimEventKind.effectFired), hasLength(1));
    expect(m.state.sides[1].crew.pirates[1].hp, lessThan(hp));
  });

  test('지원탄: 내 배에 떨어져 가까운 구멍 난 블록을 고친다', () {
    final tok = _ammoPirate(
      AmmoType.support,
      value: 100,
      param: 3,
      family: Family.support,
      blockDamage: 0,
      pirateDamage: 0,
    );
    final m = _duel(tok);
    final grid = m.state.sides[0].grid;
    // 참나무 용골 줄 한 칸을 구멍 단계로 만든다.
    final max = grid.materialAt(5, 1)!.durability;
    grid.damage(5, 1, max - max ~/ 4);
    expect(grid.stageAt(5, 1), DamageStage.holed);
    m.apply(const FireCommand(t: 1000, slot: 0, angle: 88000, power: 5000));
    expect(_of(m, SimEventKind.repaired), isNotEmpty);
    expect(grid.hpAt(5, 1), max);
  });

  test('여러 탄종이 섞인 판을 끝까지 돌려도 재생 해시가 같다', () {
    final specs = [
      _ammoPirate(AmmoType.split, value: 3, spread: 20000),
      _ammoPirate(AmmoType.mine, value: 1, value2: 20, blastRadius: 1),
      _ammoPirate(AmmoType.flock, value: 3, param: 1),
      _ammoPirate(AmmoType.assault, value: 1, blastRadius: 1),
    ];
    Match start() => Match.start(
      seed: 5,
      rules: const MatchRules(waveLevel: 0),
      blueprints: [sampleBlueprint(), sampleBlueprint()],
      decks: [
        [specs[0].id, specs[1].id],
        [specs[2].id, specs[3].id],
      ],
      costLimits: const [15, 15],
      pirates: PirateCatalog(specs),
    );
    final m = start();
    runMatch(m, RandomController(3), RandomController(4));
    final again = start();
    m.turnLog.forEach(again.playTurn);
    expect(hashMatchState(again.state), hashMatchState(m.state));
  });

  test('사거리 밖 표시: 간격이 사거리 − 8칸보다 멀면 닿기 어렵다 (설계서 §2.8)', () {
    expect(RangeGrade.short.hitGap, 18 * cellUnit);
    expect(RangeGrade.medium.hitGap, 28 * cellUnit);
    final m = _duel(testPirate('far', range: RangeGrade.short));
    // 시작 간격 22칸: 짧음(18칸)은 밖, 긺(42칸)은 안.
    expect(isOutOfRange(m.state, 0, 0), isTrue);
    expect(isOutOfRange(m.state, 0, 1), isFalse);
  });

  group('거리에 따른 계열 상성 (설계서 §2.6, BALANCE.md A2.6)', () {
    /// 두 배를 같은 거리만큼 옮겨 뱃머리 간격을 [gap] 칸으로.
    void setGap(Match m, int gap) {
      final now = (m.state.sides[0].bowX - m.state.sides[1].bowX).abs();
      for (final s in m.state.sides) {
        s.offset += (now - gap * cellUnit) ~/ 2;
      }
    }

    List<Projectile> volley(PirateSpec spec, int gap) {
      final m = _duel(spec);
      setGap(m, gap);
      return launchVolley(
        m.state,
        slot: 0,
        angle: 30000,
        power: 9000,
        ms: 0,
      );
    }

    test('간격 16칸 이하 가까움, 36칸 이상 멂', () {
      final m = _duel(testPirate('x'));
      setGap(m, 16);
      expect(reachOf(m.state), Reach.near);
      setGap(m, 17);
      expect(reachOf(m.state), Reach.mid);
      setGap(m, 36);
      expect(reachOf(m.state), Reach.far);
    });

    test('직사: 가까우면 피해 +20%, 멀면 −20% 에 매치 난수로 각도가 흔들린다', () {
      final direct = _ammoPirate(
        AmmoType.explosive,
        value: 50,
        family: Family.direct,
        blockDamage: 60,
        pirateDamage: 100,
      );
      expect(volley(direct, 16).single.spec.blockDamage, 72);
      expect(volley(direct, 28).single.spec.blockDamage, 60);
      expect(volley(direct, 36).single.spec.pirateDamage, 80);
      // 먼 거리 흔들림은 매치 난수를 쓴다: 같은 시드면 같은 각도.
      final a = volley(direct, 40).single;
      final b = volley(direct, 40).single;
      expect([a.vx, a.vy], [b.vx, b.vy]);
      final lob = volley(_ammoPirate(AmmoType.explosive, value: 50), 40);
      expect(lob.single.spec.blockDamage, 40, reason: '투척은 거리 영향 없음');
    });

    test('관통: 가까우면 +1칸, 멀면 −1칸 (최소 1)', () {
      final finn = _ammoPirate(AmmoType.pierce, value: 2);
      expect(volley(finn, 16).single.pierceLeft, 3);
      expect(volley(finn, 28).single.pierceLeft, 2);
      expect(volley(finn, 36).single.pierceLeft, 1);
    });

    test('설치탄: 멀면 도달에 1턴 더 걸린다', () {
      const mine = PirateSpec(
        id: 'far_mine',
        rarity: Rarity.common,
        hp: 300,
        cooldownTurns: 0,
        blockDamage: 40,
        pirateDamage: 50,
        blastRadius: 1,
        range: RangeGrade.veryLong,
        family: Family.underwater,
        ammo: AmmoType.mine,
        ammoValue: 1,
        ammoValue2: 20,
      );
      int delay(int gap) {
        final m = _duel(mine);
        setGap(m, gap);
        m.apply(_atCabin(m));
        return m.state.effects.single.turnsLeft;
      }

      expect(delay(28), 1);
      expect(delay(40), 2);
    });
  });

  test('지원 해적의 FIRE 는 0~180° 만 받는다 (설계서 §7.2)', () {
    PirateSpec tok() => _ammoPirate(
      AmmoType.support,
      value: 100,
      param: 3,
      family: Family.support,
      blockDamage: 0,
      pirateDamage: 0,
    );
    final m = _duel(tok())
      ..apply(const FireCommand(t: 1000, slot: 0, angle: 190000, power: 5000));
    expect(m.state.sides[0].shotsFired, 0);
    m.apply(const FireCommand(t: 1100, slot: 0, angle: 170000, power: 5000));
    expect(m.state.sides[0].shotsFired, 1);
  });

  group('검토 반영 규칙 (ADR-050)', () {
    /// 오른쪽 배 망사 칸 (5, 3) 으로 곧게 날아가는 탄을 한 틱씩 진행한다.
    (Projectile, List<SimEvent>) throughNet(Family family) {
      final m = _duel(_ammoPirate(AmmoType.explosive, family: family));
      final target = m.state.sides[1];
      final (x, y) = target.frame.cellCenter(5, 3);
      final p = Projectile(
        id: 99,
        side: 0,
        slot: 0,
        spec: _ammoPirate(AmmoType.explosive, family: family),
        x: x - 3000,
        y: y,
        vx: 60000 * facingOf(0),
        vy: 0,
      )..gravity = false;
      m.state.events.clear();
      for (var tick = 1; tick < 10; tick++) {
        if (stepShot(m.state, p, 0, 0, tick)) break;
        if (p.passedNet >= 0) break;
      }
      return (p, m.state.events);
    }

    test('망사: 공중이 아닌 탄은 속도 50% 로 지나가고, 공중 탄은 막혀 맞는다 (§3.2)', () {
      final (shot, _) = throughNet(Family.lob);
      expect(shot.passedNet, isNonNegative);
      expect(shot.vx.abs(), 30000);
      final (bird, events) = throughNet(Family.air);
      expect(bird.passedNet, -1);
      expect(events.any((e) => e.kind == SimEventKind.impact), isTrue);
    });

    test('관통탄은 두 번째 칸부터 피해 40% (§4.8, R1d 2차)', () {
      expect(pierceFalloffPercent, 40);
      final m = _duel(_ammoPirate(AmmoType.pierce, value: 3));
      final grid = m.state.sides[1].grid;
      final before = grid.totalHp;
      final p = Projectile(
        id: 1,
        side: 0,
        slot: 0,
        spec: _ammoPirate(AmmoType.pierce, value: 3),
        x: 0,
        y: 0,
        vx: 0,
        vy: 0,
      )..pierceLeft = 3;
      // 소나무 두 칸을 차례로: 첫 칸 40(부서짐), 둘째 칸 20.
      onHullHit(m.state, p, m.state.sides[1], cx: 3, cy: 1, x: 0, y: 0);
      onHullHit(m.state, p, m.state.sides[1], cx: 4, cy: 1, x: 0, y: 0);
      expect(before - grid.totalHp, 56);
    });

    test('다중투하는 합계를 폭탄 수로 나눈다 (§4.8)', () {
      final wing = _ammoPirate(
        AmmoType.flock,
        value: 3,
        family: Family.air,
        blockDamage: 50,
        pirateDamage: 90,
      );
      final m = _duel(wing);
      final p = Projectile(
        id: 1,
        side: 0,
        slot: 0,
        spec: wing,
        x: 0,
        y: 5000,
        vx: 30000,
        vy: 0,
      );
      final bombs = flockBombs(m.state, p, 10);
      expect(bombs, hasLength(3));
      expect(
        [bombs.first.spec.blockDamage, bombs.first.spec.pirateDamage],
        [perShotDamage(50, 0, 3), perShotDamage(90, 0, 3)],
      );
    });
  });
}
