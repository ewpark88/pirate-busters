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

  test('최대 힘 수평 발사는 틱당 1.333칸, 오른쪽 진영은 반대 방향으로 날아간다', () {
    final left = _launch(angle: 0);
    expect([left.vx, left.vy], [1333, 0]);
    final right = _launch(side: 1, angle: 0);
    expect([right.vx, right.vy], [-1333, 0]);
    final up = _launch(angle: 90000, power: 5000);
    expect([up.vx, up.vy], [0, 667]);
  });

  test('탄도는 속도에 바람과 중력을 더한 뒤 위치를 옮기는 정수 적분과 정확히 같다', () {
    const wind = 3;
    final p = _launch(angle: 45000);
    final vx0 = p.vx;
    final vy0 = p.vy;
    for (var n = 1; n <= 30; n++) {
      p.advance(wind);
      final tri = n * (n + 1) ~/ 2;
      expect(p.x, n * vx0 + wind * tri, reason: 'tick $n');
      expect(p.y, 2500 + n * vy0 - gravityPerTick * tri, reason: 'tick $n');
    }
  });

  test('45° 로 약 30칸을 쏘면 1.2~1.4초 날아간다 (설계서 §2.6)', () {
    final p = _launch(angle: 45000, power: 8250);
    var ticks = 0;
    while (p.y >= 0) {
      p.advance(0);
      ticks++;
    }
    expect(p.x, inInclusiveRange(28 * cellUnit, 34 * cellUnit));
    expect(ticks, inInclusiveRange(36, 42));
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

  test('바다에 떨어진 탄은 물보라를 내고 사라진다', () {
    final m = newSampleMatch(3)
      ..step(const [
        FireCommand(tick: 0, side: 0, slot: 0, angle: 80000, power: 2000),
      ]);
    var splashed = false;
    for (var i = 0; i < 120 && m.state.projectiles.isNotEmpty; i++) {
      m.step();
      splashed |= m.state.events.any((e) => e.kind == SimEventKind.splash);
    }
    expect(splashed, isTrue);
    expect(m.state.projectiles, isEmpty);
    expect(m.state.sides[1].grid.totalHp, m.state.sides[1].grid.initialTotalHp);
  });
}
