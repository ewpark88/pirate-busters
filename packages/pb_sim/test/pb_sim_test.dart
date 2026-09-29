import 'package:pb_sim/pb_sim.dart';
import 'package:test/test.dart';

void main() {
  test('시뮬레이션 틱 속도는 30Hz 로 고정된다', () {
    expect(simTickHz, 30);
  });
}
