import 'package:pb_sim/pb_sim.dart';
import 'package:test/test.dart';

import 'aim.dart';
import 'fixtures.dart';

/// M2·M3 재점검(설계서 대조)으로 고친 규칙.
void main() {
  test('한 턴에 같은 해적은 두 번 쏠 수 없다 (설계서 §2.3 서로 다른 해적)', () {
    final m = newSampleMatch(1, rules: const MatchRules(waveLevel: 0));
    final side = m.state.activeSide;
    final crew = m.state.sides[side].crew;
    m.apply(const FireCommand(t: 10, slot: 0, angle: 30000, power: 5000));
    // 쿨다운이 풀려도(세트 효과 등) 같은 턴에는 다시 못 쏜다.
    crew.pirates[0].cooldown = 0;
    expect(crew.canFire(0), isFalse);
    m.apply(const FireCommand(t: 20, slot: 0, angle: 30000, power: 5000));
    expect(m.state.sides[side].shotsFired, 1);
  });

  test('쿨다운이 0~2턴 밖인 해적은 출전할 수 없다', () {
    PirateSpec spec(int cd) => PirateSpec(
      id: 'x',
      rarity: Rarity.common,
      hp: 100,
      cooldownTurns: cd,
      blockDamage: 1,
      pirateDamage: 1,
    );
    expect(
      () => checkLineup(HullSpec.sloop, [spec(3)], 15),
      throwsArgumentError,
    );
    expect(
      () => checkLineup(HullSpec.sloop, [spec(-1)], 15),
      throwsArgumentError,
    );
    checkLineup(HullSpec.sloop, [spec(2)], 15);
  });

  test('블록이 부서진 발사는 부서지는 연출만큼 턴 타이머를 더 멈춘다 (설계서 §2.3)', () {
    const rules = MatchRules(waveLevel: 0);
    final m = newSampleMatch(5, rules: rules);
    // 뱃머리 소나무(40)는 일반 해적 한 발(60)에 부서진다.
    final shot = aimAt(m.state, slot: 0, tx: 11, ty: 1, t: 10);
    m.apply(shot);
    final events = m.state.events;
    final impact = events.firstWhere((e) => e.kind == SimEventKind.impact);
    expect(events.any((e) => e.kind == SimEventKind.blockDestroyed), isTrue);
    expect(
      m.state.pausedMs,
      roundDiv(impact.value * 1000, simTickHz) + rules.breakPauseMs,
    );
  });

  test('이동 한계선 앞 0.5칸은 절반 속도라 시간이 더 든다 (설계서 §2.6)', () {
    // 9칸은 감속 구간 밖이다.
    final m = newSampleMatch(3, rules: const MatchRules(waveLevel: 0))
      ..apply(const MoveCommand(t: 10, dx: 0)); // 턴 시작
    final me = m.state.sides[m.state.activeSide];
    me.fuel = 10 * me.fuelPerCell; // 한계선까지 갈 연료
    m.apply(const MoveCommand(t: 100, dx: 90));
    final free = m.state.busyUntilMs - 100;
    m.apply(MoveCommand(t: m.state.busyUntilMs, dx: 10)); // 마지막 1칸
    final last = m.state.busyUntilMs - 100 - free;
    // 1칸 = 0.5칸 보통 + 0.5칸 절반 속도 → 1.5칸 분량 시간.
    expect(last, (1500 * 1000 + 2799) ~/ 2800);
    expect(m.state.sides[m.state.activeSide].offset, 10 * cellUnit);
  });

  test('배의 로컬 좌표 변환은 기울기·파도를 되돌려 서로 역변환이다 (설계서 §2.5)', () {
    final m = newSampleMatch(2);
    final s = m.state;
    s.sides[1].grid
      ..damage(10, 0, 100)
      ..damage(11, 0, 100);
    expect(tiltAtMs(s, 1, 700), isNot(0));
    for (final (x, y) in const [(0, 0), (6000, 1500), (11500, 2500)]) {
      final (wx, wy) = fromShipLocal(s, 1, 700, x, y);
      final (lx, ly) = toShipLocal(s, 1, 700, wx, wy);
      expect((lx - x).abs(), lessThanOrEqualTo(2));
      expect((ly - y).abs(), lessThanOrEqualTo(2));
    }
  });
}
