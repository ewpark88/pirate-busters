import 'package:flutter_test/flutter_test.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/input/pull_aim.dart';

void main() {
  group('당겨서 쏘기 (설계서 §2.2)', () {
    test('오른쪽을 보는 배는 왼쪽 아래로 당기면 오른쪽 위로 45° 로 날아간다', () {
      final aim = PullAim(facing: 1)
        ..start()
        ..drag(-80, 80);
      expect(aim.shot.angle, 45000);
      expect(aim.shot.power, (113.137 / 160 * maxFirePower).round());
    });

    test('왼쪽을 보는 배는 좌우가 뒤집힌다', () {
      final aim = PullAim(facing: -1)
        ..start()
        ..drag(80, 80);
      expect(aim.shot.angle, 45000);
    });

    test('최대 거리보다 멀리 당겨도 힘은 최대다', () {
      final aim = PullAim(facing: 1)
        ..start()
        ..drag(-1000, 0);
      expect(aim.shot.power, maxFirePower);
      expect(aim.stretch, 1);
    });

    test('아래쪽을 향하면 수평, 뒤로 넘어가면 85° 로 막는다', () {
      final down = PullAim(facing: 1)
        ..start()
        ..drag(-80, -40);
      expect(down.shot.angle, 0);
      final back = PullAim(facing: 1)
        ..start()
        ..drag(40, 120);
      expect(back.shot.angle, PullAim.maxAngleMdeg);
    });

    test('너무 약하게 당기고 놓으면 쏘지 않는다', () {
      final aim = PullAim(facing: 1)
        ..start()
        ..drag(-5, 5);
      expect(aim.release(), isNull);
      expect(aim.isActive, isFalse);
    });
  });
}
