import 'package:pb_sim/pb_sim.dart';
import 'package:test/test.dart';

void main() {
  test('같은 시드는 같은 수열을 낸다', () {
    final a = XorShift32(12345);
    final b = XorShift32(12345);
    for (var i = 0; i < 100; i++) {
      expect(a.nextUint32(), b.nextUint32());
    }
  });

  test('시드 1 의 첫 값은 xorshift32 표준 수열과 같다', () {
    final r = XorShift32(1);
    expect(
      [for (var i = 0; i < 3; i++) r.nextUint32()],
      [
        270369,
        67634689,
        2647435461,
      ],
    );
  });

  test('시드 0 은 고정 상수로 대체되어 멈추지 않는다', () {
    final r = XorShift32(0);
    expect(r.state, 0x9E3779B9);
    expect(r.nextUint32(), isNot(0));
  });

  test('상태에서 복원하면 같은 수열을 이어서 낸다', () {
    final a = XorShift32(99)..nextUint32();
    final b = XorShift32.fromState(a.state);
    expect(b.nextUint32(), a.nextUint32());
  });

  test('범위 난수는 범위 안에서 고르게 나온다', () {
    final r = XorShift32(2026);
    final counts = List<int>.filled(6, 0);
    for (var i = 0; i < 60000; i++) {
      final v = r.nextInt(6);
      expect(v, inInclusiveRange(0, 5));
      counts[v]++;
    }
    for (final c in counts) {
      expect(c, inInclusiveRange(9500, 10500));
    }
    for (var i = 0; i < 1000; i++) {
      expect(r.nextRange(-3, 4), inInclusiveRange(-3, 3));
    }
  });

  test('범위가 잘못되면 오류를 낸다', () {
    final r = XorShift32(1);
    expect(() => r.nextInt(0), throwsArgumentError);
    expect(() => r.nextInt(0x80000001), throwsArgumentError);
  });
}
