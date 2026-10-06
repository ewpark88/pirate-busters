import 'package:flutter_test/flutter_test.dart';
import 'package:pirate_busters/input/aim_ticks.dart';

void main() {
  group('당길 때 진동 (설계서 §10.4 발사, A32)', () {
    test('힘을 끝까지 당기면 눈금마다 한 번씩 아홉 번 톡, 마지막에 딸깍이다', () {
      final t = AimTicks()..reset();
      final ticks = [
        for (var p = 0; p <= 10000; p += 250) t.update(p, 10000),
      ].whereType<AimTick>().toList();
      expect(ticks.where((k) => k == AimTick.step), hasLength(9));
      expect(ticks.last, AimTick.full);
    });

    test('힘을 줄일 때는 울리지 않고, 다시 넘으면 울린다', () {
      final t = AimTicks()..update(5000, 10000);
      expect(t.update(3000, 10000), isNull);
      expect(t.update(4000, 10000), AimTick.step);
    });

    test('새로 당기면 처음부터 센다', () {
      final t = AimTicks()..update(10000, 10000);
      expect(t.update(10000, 10000), isNull, reason: '최대에 머물면 다시 안 운다');
      t.reset();
      expect(t.update(1000, 10000), AimTick.step);
    });
  });
}
