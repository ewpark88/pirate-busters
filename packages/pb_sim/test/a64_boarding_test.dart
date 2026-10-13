import 'package:pb_sim/pb_sim.dart';
import 'package:pb_sim/src/combat/hit_effects.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

/// A64 강습 해적 적 갑판 체류 (설계서 §2.3 적 배에 오른 해적, §4.8 적 배 위 강습,
/// ADR-110).
PirateSpec _assault(
  String id, {
  Ability ability = Ability.none,
  int abilityValue = 0,
  int value = 1,
  int hp = 300,
  int pirateDamage = 90,
}) => PirateSpec(
  id: id,
  rarity: Rarity.common,
  hp: hp,
  cooldownTurns: 0,
  blockDamage: 20,
  pirateDamage: pirateDamage,
  blastRadius: 1,
  range: RangeGrade.long,
  family: Family.assault,
  ammo: AmmoType.assault,
  ammoValue: value,
  ability: ability,
  abilityValue: abilityValue,
);

/// 왼쪽(0) 에 [spec] 과 보조, 오른쪽(1) 에 기본 해적 4명(선실 (3,2)·(5,2)·(6,2)·(8,2)).
/// 파도 없음. 왼쪽 턴을 연다.
Match _duel(PirateSpec spec, {int enemyHp = 300}) {
  final m = Match.start(
    seed: 11,
    rules: const MatchRules(waveLevel: 0),
    blueprints: [sampleBlueprint(), sampleBlueprint()],
    decks: [
      [spec.id, 'r0'],
      ['e0', 'e1', 'e2', 'e3'],
    ],
    costLimits: const [15, 15],
    pirates: PirateCatalog([
      spec,
      testPirate('r0'),
      for (var i = 0; i < 4; i++) testPirate('e$i', hp: enemyHp),
    ]),
  );
  _passTo(m, 0);
  return m;
}

/// [side] 턴이 될 때까지 넘기고 그 턴을 연다(턴 시작 처리는 다음 커맨드에서 돈다).
void _passTo(Match m, int side) {
  while (m.state.activeSide != side) {
    m.apply(const EndTurnCommand(t: 1000));
  }
  m.apply(const TapCommand(t: 0, slot: 9, ticks: 0));
}

/// 왼쪽 0번 해적의 강습탄이 오른쪽 배 칸 ([cx], [cy]) 에 착지했다.
void _land(Match m, int cx, int cy) {
  final target = m.state.sides[1];
  final (x, y) = target.frame.cellCenter(cx, cy);
  final p = Projectile(
    id: 0,
    side: 0,
    slot: 0,
    spec: m.state.sides[0].crew.pirates[0].spec,
    x: x,
    y: y,
    vx: 100000,
    vy: 0,
  );
  onHullHit(m.state, p, target, cx: cx, cy: cy, x: x, y: y);
}

PirateState _boarder(Match m) => m.state.sides[0].crew.pirates[0];

List<SimEvent> _of(Match m, SimEventKind k) => [
  for (final e in m.state.events)
    if (e.kind == k) e,
];

void main() {
  group('적 배 위에 선다', () {
    test('착지하면 그 줄 맨 위 블록을 밟고 서며, 서 있는 동안 내 선실에서 쏠 수 없다', () {
      final m = _duel(_assault('sharky'));
      _land(m, 5, 2);
      final grid = m.state.sides[1].grid;
      expect(_boarder(m).status, PirateStatus.boarding);
      expect(_boarder(m).boardCell, grid.indexOf(5, 3), reason: '선실 위 망사');
      expect(m.state.sides[0].canFire(0), isFalse);
      expect(_of(m, SimEventKind.boarded), hasLength(1));
    });

    test('선실이 그 줄 맨 위면 선실 칸을 밟고 선다', () {
      final m = _duel(_assault('sharky'));
      _land(m, 3, 2);
      expect(_boarder(m).boardCell, m.state.sides[1].grid.indexOf(3, 2));
    });

    test('서 있는 강습 해적은 살아 있는 해적으로 센다', () {
      final m = _duel(_assault('sharky'));
      _land(m, 5, 2);
      final mine = m.state.sides[0].crew..damage(1, 9999, 0, m.state.events);
      expect(mine.pirates[1].status, PirateStatus.down);
      expect(mine.allDown, isFalse);
      expect(mine.attackersDown, isFalse);
    });
  });

  group('상대 턴 시작: 근접 수비 → 추가 물기', () {
    test('밟은 칸 2칸 안의 배 위 해적마다 30 피해를 받고, 살아남으면 한 번 더 문다', () {
      final m = _duel(_assault('sharky'));
      _land(m, 5, 2);
      final enemy = m.state.sides[1].crew;
      final hp = enemy.pirates[1].hp;
      m.apply(const EndTurnCommand(t: 9000));
      _passTo(m, 1);
      // (5,3) 에서 2칸 안: (5,2)·(6,2) 두 명.
      expect(_of(m, SimEventKind.boardDefended), hasLength(2));
      expect(_boarder(m).hp, 300 - 2 * boardDefenseDamage);
      expect(_of(m, SimEventKind.effectFired), hasLength(1));
      expect(enemy.pirates[1].hp, lessThan(hp), reason: '(5,2) 를 문다');
    });

    test('추가 물기는 착지 반경이 커져도 1칸만 문다', () {
      const wide = PirateSpec(
        id: 'wide',
        rarity: Rarity.common,
        hp: 300,
        cooldownTurns: 0,
        blockDamage: 20,
        pirateDamage: 90,
        blastRadius: 2,
        range: RangeGrade.long,
        family: Family.assault,
        ammo: AmmoType.assault,
        ammoValue: 1,
      );
      final m = _duel(wide);
      _land(m, 5, 2);
      final enemy = m.state.sides[1].crew;
      final hp = [for (final p in enemy.pirates) p.hp];
      m.apply(const EndTurnCommand(t: 9000));
      _passTo(m, 1);
      // 밟은 칸에서 1칸 안의 선실만 물린다(√2 칸 이상은 그대로).
      final target = m.state.sides[1];
      final (bx, by) = boardPosOf(target.grid, _boarder(m).boardCell);
      var bitten = 0;
      for (var slot = 0; slot < enemy.size; slot++) {
        final c = target.cabins[slot];
        final d = (c.x - bx) * (c.x - bx) + (c.y - by) * (c.y - by);
        if (d > 1) {
          expect(enemy.pirates[slot].hp, hp[slot], reason: '슬롯 $slot');
        } else if (enemy.pirates[slot].hp < hp[slot]) {
          bitten++;
        }
      }
      expect(bitten, greaterThan(0));
    });

    test('근접 수비에 쓰러지면 남은 물기는 터지지 않는다', () {
      final m = _duel(_assault('sharky', hp: 50));
      _land(m, 5, 2);
      m.apply(const EndTurnCommand(t: 9000));
      _passTo(m, 1);
      expect(_boarder(m).status, PirateStatus.down);
      expect(_of(m, SimEventKind.effectFired), isEmpty);
    });

    test('물기가 끝나면 다음 내 턴 시작에 원래 선실로 돌아와 다시 쏠 수 있다', () {
      final m = _duel(_assault('sharky'));
      _land(m, 5, 2);
      m.apply(const EndTurnCommand(t: 9000));
      _passTo(m, 1);
      m.apply(const EndTurnCommand(t: 9000));
      _passTo(m, 0);
      expect(_boarder(m).status, PirateStatus.aboard);
      expect(_boarder(m).boardCell, -1);
      expect(_of(m, SimEventKind.boardReturned), hasLength(1));
      expect(m.state.sides[0].canFire(0), isTrue);
    });

    test('물기가 남았으면 내 턴이 와도 적 배 위에 남는다', () {
      final m = _duel(_assault('sharky', value: 2));
      _land(m, 5, 2);
      m.apply(const EndTurnCommand(t: 9000));
      _passTo(m, 1);
      m.apply(const EndTurnCommand(t: 9000));
      _passTo(m, 0);
      expect(_boarder(m).status, PirateStatus.boarding);
      expect(m.state.sides[0].canFire(0), isFalse);
    });
  });

  group('떨어뜨리기', () {
    test('상대가 배를 한 번에 1칸 이상 움직이면 바다에 빠지고 남은 물기는 사라진다', () {
      final m = _duel(_assault('sharky', value: 2));
      _land(m, 5, 2);
      m.apply(const EndTurnCommand(t: 9000));
      _passTo(m, 1);
      // dx 는 1/10칸: 1칸.
      m.apply(const MoveCommand(t: 2000, dx: -10));
      expect(_boarder(m).status, PirateStatus.swimming);
      expect(_of(m, SimEventKind.pirateFell).single.side, 0);
      m.apply(const EndTurnCommand(t: 9000));
      _passTo(m, 0);
      expect(_boarder(m).status, PirateStatus.aboard, reason: '헤엄 복귀');
      expect(
        m.state.effects.where(isBoarderBite),
        isEmpty,
        reason: '남은 물기는 지운다',
      );
    });

    test('1칸보다 짧게 움직이면 그대로 서 있다', () {
      final m = _duel(_assault('sharky', value: 2));
      _land(m, 5, 2);
      m.apply(const EndTurnCommand(t: 9000));
      _passTo(m, 1);
      // dx 는 1/10칸: 0.5칸.
      m.apply(const MoveCommand(t: 2000, dx: -5));
      expect(_boarder(m).status, PirateStatus.boarding);
    });

    test('이동 버튼처럼 0.1칸씩 여러 번 움직여도 이번 턴 합이 1칸이 되면 떨어진다', () {
      final m = _duel(_assault('sharky', value: 2));
      _land(m, 5, 2);
      m.apply(const EndTurnCommand(t: 9000));
      _passTo(m, 1);
      for (var i = 0; i < 9; i++) {
        m.apply(MoveCommand(t: 2000 + i * 200, dx: i.isEven ? -1 : 1));
      }
      expect(_boarder(m).status, PirateStatus.boarding, reason: '0.9칸');
      m.apply(const MoveCommand(t: 4000, dx: -1));
      expect(_boarder(m).status, PirateStatus.swimming, reason: '앞뒤 합 1칸');
    });

    test('적 배 위에 있는 동안 내 배 선실이 부서져도 떨어지지 않는다', () {
      final m = _duel(_assault('sharky'));
      _land(m, 5, 2);
      final mine = m.state.sides[0];
      final cabin = mine.cabins[0];
      final (x, y) = mine.frame.cellCenter(cabin.x, cabin.y);
      resolveImpact(
        mine,
        spec: testPirate('big', blockDamage: 9999, pirateDamage: 0),
        cx: cabin.x,
        cy: cabin.y,
        x: x,
        y: y,
        events: m.state.events,
        rng: m.state.rng,
      );
      expect(mine.grid.hasBlock(cabin.x, cabin.y), isFalse);
      expect(_boarder(m).status, PirateStatus.boarding);
    });

    test('그 배에 떨어진 폭발에 맞는다 (내 편이 쏜 탄도)', () {
      final m = _duel(_assault('sharky'));
      _land(m, 5, 2);
      final target = m.state.sides[1];
      final (x, y) = target.frame.cellCenter(6, 3);
      resolveImpact(
        target,
        spec: testPirate('r0'),
        cx: 6,
        cy: 3,
        x: x,
        y: y,
        events: m.state.events,
        rng: m.state.rng,
      );
      expect(_boarder(m).hp, lessThan(300));
    });

    test('밟은 칸 블록이 부서지면 바다에 빠진다', () {
      final m = _duel(_assault('sharky'));
      _land(m, 3, 2);
      final target = m.state.sides[1];
      final (x, y) = target.frame.cellCenter(3, 2);
      resolveImpact(
        target,
        spec: testPirate('big', blockDamage: 9999, pirateDamage: 0),
        cx: 3,
        cy: 2,
        x: x,
        y: y,
        events: m.state.events,
        rng: m.state.rng,
      );
      expect(_boarder(m).status, PirateStatus.swimming);
    });
  });

  group('고유 해적', () {
    test('킹은 막은 선실 줄 위에 선다', () {
      final m = _duel(_assault('king', ability: Ability.sealCabin));
      _land(m, 8, 1);
      final target = m.state.sides[1];
      final sealed = target.cabins[target.status.sealedSlot];
      expect(sealed.x, 8);
      expect(_boarder(m).boardCell, deckCellAt(target.grid, sealed.x));
    });

    test('크래비는 문 해적과 함께 바다에 빠지고 추가 물기가 없다', () {
      final m = _duel(_assault('crabby', ability: Ability.grab));
      _land(m, 5, 2);
      expect(_boarder(m).status, PirateStatus.swimming);
      expect(
        m.state.sides[1].crew.pirates.where(
          (p) => p.status == PirateStatus.swimming,
        ),
        hasLength(1),
      );
      expect(m.state.effects.where(isBoarderBite), isEmpty);
    });

    test('크래비는 물 해적이 없으면 샤키처럼 선다', () {
      final m = _duel(_assault('crabby', ability: Ability.grab));
      for (var slot = 0; slot < 4; slot++) {
        m.state.sides[1].crew.damage(slot, 9999, 1, m.state.events);
      }
      _land(m, 5, 2);
      expect(_boarder(m).status, PirateStatus.boarding);
    });

    test('랍은 마지막에 벤 해적 줄 위에 서고, 다음 내 턴에 돌아온다', () {
      final m = _duel(
        _assault('lob', ability: Ability.leap, pirateDamage: 400),
      );
      _land(m, 3, 2);
      final target = m.state.sides[1];
      expect(_boarder(m).status, PirateStatus.boarding);
      expect(
        _boarder(m).boardCell,
        deckCellAt(target.grid, 5),
        reason: '(3,2) 를 쓰러뜨리고 가장 가까운 (5,2) 로 뛴다',
      );
      m.apply(const EndTurnCommand(t: 9000));
      _passTo(m, 1);
      m.apply(const EndTurnCommand(t: 9000));
      _passTo(m, 0);
      expect(_boarder(m).status, PirateStatus.aboard);
    });

    test('데비는 서지 않고 해골 선원만 남긴다', () {
      final m = _duel(
        _assault('davy', ability: Ability.summon, abilityValue: 3),
      );
      _land(m, 5, 2);
      expect(_boarder(m).status, PirateStatus.aboard);
      m.apply(const EndTurnCommand(t: 9000));
      _passTo(m, 1);
      expect(_of(m, SimEventKind.effectFired), hasLength(3), reason: '해골 물기');
    });
  });

  test('강습 해적이 섞인 판은 같은 커맨드·재생이면 같은 해시로 끝난다 (결정론)', () {
    final pirates = PirateCatalog([
      _assault('sharky', value: 2),
      _assault('king', ability: Ability.sealCabin),
      _assault('crabby', ability: Ability.grab),
      _assault('lob', ability: Ability.leap),
      testPirate('r0'),
      testPirate('r1'),
    ]);
    Match start() => Match.start(
      seed: 4321,
      blueprints: [sampleBlueprint(), sampleBlueprint()],
      decks: const [
        ['sharky', 'king', 'r0'],
        ['crabby', 'lob', 'r1'],
      ],
      costLimits: const [15, 15],
      pirates: pirates,
    );
    final a = start();
    runMatch(a, RandomController(7), RandomController(8));
    final b = start();
    runMatch(b, RandomController(7), RandomController(8));
    expect(hashMatchState(b.state), hashMatchState(a.state));
    final c = start();
    a.turnLog.forEach(c.playTurn);
    expect(hashMatchState(c.state), hashMatchState(a.state));
    expect(hashMatchState(a.state), _boardingHash);
  });
}

/// 강습 섞인 판(시드 4321, 스크립트 7·8)의 기대 해시. 의도한 규칙 변경일 때만 갱신한다.
const int _boardingHash = 1250131111;
