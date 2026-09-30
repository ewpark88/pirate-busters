import 'package:pb_sim/pb_sim.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

Projectile _launch({required int angle, int side = 0, int power = 10000}) =>
    Projectile.launch(
      id: 0,
      side: side,
      slot: 0,
      spec: testPirate('t'),
      x: 0,
      y: 2500,
      angle: angle,
      power: power,
    );

void main() {
  test('중력은 36칸/초² 를 30Hz 틱으로 나눈 40 이다', () {
    expect(gravityPerTick, 40);
  });

  test('사거리 긺 해적의 최대 힘 수평 발사는 틱당 1.414칸, 오른쪽 진영은 반대 방향이다', () {
    final left = _launch(angle: 0);
    expect([left.vx, left.vy], [1414, 0]);
    final right = _launch(side: 1, angle: 0);
    expect([right.vx, right.vy], [-1414, 0]);
    final up = _launch(angle: 90000, power: 5000);
    expect([up.vx, up.vy], [0, 707]);
  });

  test('탄도는 가로는 바람을 더한 속도로, 세로는 반 스텝 보정한 속도로 옮기는 정수 적분과 같다', () {
    const wind = 3;
    final p = _launch(angle: 45000);
    final vx0 = p.vx;
    final vy0 = p.vy;
    for (var n = 1; n <= 30; n++) {
      p.advance(wind);
      final tri = n * (n + 1) ~/ 2;
      expect(p.x, n * vx0 + wind * tri, reason: 'tick $n');
      // 세로는 반 스텝 보정: y = y0 + n·vy0 − g·n²/2.
      expect(
        p.y,
        2500 + n * vy0 - gravityPerTick * n * n ~/ 2,
        reason: 'tick $n',
      );
    }
  });

  test('최대 힘·45° 로 쏘면 해수면까지 등급 사거리만큼 날아간다 (설계서 §2.8)', () {
    for (final grade in RangeGrade.values) {
      final p = Projectile.launch(
        id: 0,
        side: 0,
        slot: 0,
        spec: testPirate('t', range: grade),
        x: 0,
        y: 0,
        angle: 45000,
        power: maxFirePower,
      );
      while (p.y >= 0) {
        p.advance(0);
      }
      final lo = (grade.cells - 1) * cellUnit;
      final hi = (grade.cells + 1) * cellUnit;
      expect(p.x, inInclusiveRange(lo, hi), reason: grade.name);
    }
  });

  test('사거리 등급은 데이터 이름으로 찾고, 모르는 이름은 오류를 낸다', () {
    expect(RangeGrade.byName('veryLong'), RangeGrade.veryLong);
    expect(() => RangeGrade.byName('far'), throwsFormatException);
  });

  test('순풍이면 더 멀리, 역풍이면 덜 날아간다', () {
    int range(int wind) {
      final p = _launch(angle: 45000);
      while (p.y >= 0) {
        p.advance(wind);
      }
      return p.x;
    }

    expect(range(5), greaterThan(range(0)));
    expect(range(-5), lessThan(range(0)));
  });

  test('전장 밖으로 나가거나 10초가 지나면 투사체가 끝난다', () {
    final far = Projectile(
      id: 0,
      side: 0,
      slot: 0,
      spec: testPirate('t'),
      x: worldHalfWidth + 1,
      y: 0,
      vx: 0,
      vy: 0,
    );
    expect(far.isExpired, isTrue);
    final slow = _launch(angle: 90000);
    for (var i = 0; i < projectileMaxTicks; i++) {
      slow.advance(0);
    }
    expect(slow.isExpired, isTrue);
  });

  test('바다에 떨어진 탄은 물보라를 내고 블록을 다치게 하지 않는다', () {
    final m = newSampleMatch(3);
    final me = m.state.activeSide;
    m.apply(const FireCommand(t: 10, slot: 0, angle: 80000, power: 2000));
    final splash = m.state.events.where((e) => e.kind == SimEventKind.splash);
    expect(splash, hasLength(1));
    expect(splash.first.value, greaterThan(0)); // 착탄 틱
    final enemy = m.state.sides[1 - me].grid;
    expect(enemy.totalHp, enemy.initialTotalHp);
  });

  test('바람은 탄을 바람 방향으로 민다', () {
    int landX(int seed) {
      final m = newSampleMatch(seed)
        ..apply(const FireCommand(t: 10, slot: 0, angle: 85000, power: 3000));
      final e = m.state.events.firstWhere(
        (e) => e.kind == SimEventKind.splash || e.kind == SimEventKind.impact,
      );
      return e.x;
    }

    // 같은 진영이 선공인 시드끼리 바람 부호에 따라 착탄 x 의 순서가 같다.
    const rules = MatchRules();
    final seeds = [
      for (var s = 0; s < 200; s++)
        if (newSampleMatch(s).state.firstSide == 0) s,
    ];
    final strong = seeds.firstWhere((s) => rules.windForTurn(s, 1) == 3);
    final calm = seeds.firstWhere((s) => rules.windForTurn(s, 1) == 0);
    final against = seeds.firstWhere((s) => rules.windForTurn(s, 1) == -3);
    expect(landX(strong), greaterThan(landX(calm)));
    expect(landX(calm), greaterThan(landX(against)));
  });
}
