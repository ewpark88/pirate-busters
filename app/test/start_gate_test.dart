import 'package:flutter_test/flutter_test.dart';
import 'package:pirate_busters/game/start_gate.dart';

void main() {
  group('전투 시작 문 (A33, 플레이 점검 버그 6)', () {
    test('느린 첫 프레임 동안은 닫혀 있다가 프레임이 고르게 나오면 열린다', () {
      final gate = StartGate();
      expect(gate.tick(.4), isFalse);
      expect(gate.tick(.3), isFalse);
      expect(gate.tick(.016), isFalse);
      expect(gate.tick(.016), isFalse);
      expect(gate.tick(.016), isTrue);
      expect(gate.tick(.5), isTrue, reason: '한 번 열리면 계속 열려 있다');
    });

    test('계속 느린 기기도 최대 대기 뒤에는 연다', () {
      final gate = StartGate();
      var t = 0.0;
      while (!gate.tick(.2)) {
        t += .2;
      }
      expect(t, lessThanOrEqualTo(StartGate.maxWaitSec));
    });
  });
}
