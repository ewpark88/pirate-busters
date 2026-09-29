import 'dart:math' as math;

import 'package:pb_sim/pb_sim.dart';
import 'package:test/test.dart';

int _refMicro(num Function(num) f, int mdeg) =>
    (f(mdeg * math.pi / 180000) * 1000000).round();

void main() {
  group('Fx (계획서 M1 고정소수점)', () {
    test('정수를 ×1000 으로 바꾸고 더하고 뺀다', () {
      expect(Fx.fromInt(3).raw, 3000);
      expect((const Fx(1500) + const Fx(250)).raw, 1750);
      expect((const Fx(1500) - const Fx(2500)).raw, -1000);
      expect((-const Fx(1500)).raw, -1500);
    });

    test('곱셈은 0 에서 먼 쪽으로 반올림한다', () {
      expect((const Fx(1500) * const Fx(1500)).raw, 2250);
      expect((const Fx(1) * const Fx(500)).raw, 1); // 0.0005 → 0.001
      expect((const Fx(-1) * const Fx(500)).raw, -1);
      expect((const Fx(1) * const Fx(499)).raw, 0);
    });

    test('나눗셈은 0 에서 먼 쪽으로 반올림한다', () {
      expect((const Fx(1000) ~/ const Fx(3000)).raw, 333);
      expect((const Fx(2000) ~/ const Fx(3000)).raw, 667);
      expect((const Fx(-2000) ~/ const Fx(3000)).raw, -667);
      expect((const Fx(2000) ~/ const Fx(-3000)).raw, -667);
    });

    test('0 으로 나누면 오류를 낸다', () {
      expect(() => Fx.one ~/ Fx.zero, throwsArgumentError);
      expect(() => roundDiv(1, 0), throwsArgumentError);
    });

    test('범위를 넘으면 StateError 를 낸다', () {
      expect(() => const Fx(Fx.maxRaw) + const Fx(1), throwsStateError);
      expect(() => const Fx(Fx.maxRaw) * const Fx(Fx.maxRaw), throwsStateError);
      expect(() => const Fx(Fx.maxRaw).scaleBy(1 << 30), throwsStateError);
    });

    test('정수로 반올림하거나 버린다', () {
      expect(const Fx(2500).toIntRound(), 3);
      expect(const Fx(-2500).toIntRound(), -3);
      expect(const Fx(2499).toIntRound(), 2);
      expect(const Fx(-2999).toIntTrunc(), -2);
    });
  });

  group('정수 삼각함수', () {
    test('sin·cos 는 모든 각도에서 실수 계산과 3 마이크로 이내로 같다', () {
      for (var a = -360000; a <= 720000; a += 37) {
        expect(sinMicro(a), closeTo(_refMicro(math.sin, a), 3), reason: '$a');
        expect(cosMicro(a), closeTo(_refMicro(math.cos, a), 3), reason: '$a');
      }
    });

    test('0.25° 격자점과 사분면 경계에서는 테이블 값 그대로다', () {
      expect(sinMicro(0), 0);
      expect(sinMicro(90000), 1000000);
      expect(sinMicro(180000), 0);
      expect(sinMicro(270000), -1000000);
      expect(cosMicro(0), 1000000);
      expect(sinMicro(30000), 500000);
    });

    test('Fx 버전은 ×1000 으로 반올림한다', () {
      expect(sinFx(30000).raw, 500);
      expect(cosFx(60000).raw, 500);
      expect(sinFx(-90000).raw, -1000);
      expect(
        sinFx(41250).raw,
        (math.sin(41.25 * math.pi / 180) * 1000).round(),
      );
    });

    test('각도는 0 이상 360000 미만으로 정규화된다', () {
      expect(normalizeMdeg(-1), 359999);
      expect(normalizeMdeg(360000), 0);
      expect(normalizeMdeg(725000), 5000);
    });
  });

  group('정수 sqrt·atan2', () {
    test('isqrt 는 내림 제곱근을 낸다', () {
      const cases = [
        (0, 0),
        (1, 1),
        (2, 1),
        (3, 1),
        (4, 2),
        (15, 3),
        (16, 4),
        (17, 4),
      ];
      for (final (n, r) in cases) {
        expect(isqrt(n), r, reason: '$n');
      }
      for (final r in [999, 1000000, 3037000499]) {
        expect(isqrt(r * r), r);
        expect(isqrt(r * r - 1), r - 1);
      }
      expect(() => isqrt(-1), throwsArgumentError);
    });

    test('atan2 는 8 방향을 정확히 낸다', () {
      expect(atan2Mdeg(0, 0), 0);
      expect(atan2Mdeg(0, 5), 0);
      expect(atan2Mdeg(5, 5), 45000);
      expect(atan2Mdeg(5, 0), 90000);
      expect(atan2Mdeg(5, -5), 135000);
      expect(atan2Mdeg(0, -5), 180000);
      expect(atan2Mdeg(-5, -5), -135000);
      expect(atan2Mdeg(-5, 0), -90000);
      expect(atan2Mdeg(-5, 5), -45000);
    });

    test('atan2 는 실수 계산과 0.01° 이내로 같다', () {
      for (var a = -179000; a <= 180000; a += 1013) {
        final x = (math.cos(a * math.pi / 180000) * 1000000).round();
        final y = (math.sin(a * math.pi / 180000) * 1000000).round();
        expect(atan2Mdeg(y, x), closeTo(a, 10), reason: '$a');
      }
    });

    test('atan2 결과는 -180° 가 아니라 180° 로 낸다', () {
      expect(atan2Mdeg(-1, -1000000000), 180000);
    });
  });
}
