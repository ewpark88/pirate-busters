import 'package:flutter_test/flutter_test.dart';
import 'package:pirate_busters/game/view/shake.dart';
import 'package:pirate_busters/game/view/ship_motion.dart';

void main() {
  group('화면 흔들림 (설계서 §10.4, A20)', () {
    test('같은 시각·세기면 같은 흔들림이다', () {
      expect(Shake.offset(8, 0.37), Shake.offset(8, 0.37));
    });

    test('좌우로 번갈아 튀지 않고 매끄럽게 움직인다', () {
      // 1/60초 간격의 이웃 프레임 사이 이동이 세기의 절반을 넘지 않는다.
      for (var f = 0; f < 60; f++) {
        final a = Shake.offset(10, f / 60);
        final b = Shake.offset(10, (f + 1) / 60);
        expect((b.x - a.x).abs(), lessThan(10), reason: 'frame $f');
      }
      // 세기를 넘지 않는다.
      for (var f = 0; f < 120; f++) {
        expect(Shake.offset(10, f / 60).x.abs(), lessThanOrEqualTo(10));
      }
    });

    test('세기는 지수로 잦아들고 0.6초 안에 멈춘다', () {
      var amp = 12.0;
      var t = 0.0;
      var last = amp;
      while (amp > 0) {
        amp = Shake.decay(amp, 1 / 60);
        expect(amp, lessThan(last));
        last = amp;
        t += 1 / 60;
      }
      expect(t, inInclusiveRange(0.3, 0.6));
    });
  });

  group('배 움직임 (설계서 §10.4, A20)', () {
    test('쏘면 반대쪽으로 밀렸다가 돌아온다', () {
      final m = ShipMotion()..recoil(-1);
      expect(m.recoilX, closeTo(-ShipMotion.recoilPx, 1e-9));
      expect(m.recoilAngle, lessThan(0));
      m.update(0.6);
      expect(m.recoilX.abs(), lessThan(0.1));
    });

    test('맞으면 기울며 살짝 가라앉았다 떠오른다', () {
      final m = ShipMotion()..rock(1);
      expect(m.rockAngle, closeTo(ShipMotion.rockAmp, 1e-9));
      m.update(0.1);
      expect(m.dip, greaterThan(0));
      m.update(1.5);
      expect(m.dip, lessThan(0.01));
      expect(m.rockAngle.abs(), lessThan(0.001));
    });

    test('맞지 않은 배는 가라앉지 않는다', () {
      expect(ShipMotion().dip, 0);
      expect(ShipMotion().recoilX, 0);
    });
  });
}
