import 'package:pb_sim/pb_sim.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

FireCommand _fire(int tick, int side, int slot) =>
    FireCommand(tick: tick, side: side, slot: slot, angle: 45000, power: 5000);

final _idle = ScriptedController(const []);

void main() {
  test('시뮬레이션은 30Hz 고정 틱이고 한 판은 5400틱이다', () {
    expect(simTickHz, 30);
    expect(matchDurationTicks, 5400);
  });

  test('덱 앞에서부터 선실 슬롯 수만큼만 발사할 수 있다', () {
    final m = newSampleMatch(1)
      ..step([_fire(0, 0, 3), _fire(0, 0, 4), _fire(0, 1, 3)]);
    final crew = m.state.sides[0].crew;
    expect(m.state.sides[0].shotsFired, 1);
    expect(
      [for (var s = 0; s < 4; s++) crew.pirateAt(s)!.reload],
      [
        0,
        0,
        0,
        sampleCatalog.byId('p16').reloadTicks - 1,
      ],
    );
    expect(crew.pirates[4].status, PirateStatus.queued);
    expect(m.state.sides[1].shotsFired, 1);
  });

  test('재장전 중 발사는 무시하고 재장전이 끝나면 다시 쏜다', () {
    final reload = sampleCatalog.byId('p01').reloadTicks;
    final m = newSampleMatch(1)..step([_fire(0, 0, 0)]);
    for (var t = 1; t < reload; t++) {
      m.step([_fire(t, 0, 0)]);
    }
    expect(m.state.sides[0].shotsFired, 1);
    m.step([_fire(reload, 0, 0)]);
    expect(m.state.sides[0].shotsFired, 2);
  });

  test('각도·힘이 범위를 벗어난 발사는 무시한다', () {
    final m = newSampleMatch(1)
      ..step(const [
        FireCommand(tick: 0, side: 0, slot: 0, angle: -1, power: 10),
        FireCommand(tick: 0, side: 0, slot: 1, angle: 360000, power: 10),
        FireCommand(tick: 0, side: 0, slot: 2, angle: 0, power: 10001),
      ]);
    expect(m.state.sides[0].shotsFired, 0);
  });

  test('현재 틱이 아닌 커맨드는 무시한다', () {
    final m = newSampleMatch(1)..step([_fire(5, 0, 0)]);
    expect(m.state.sides[0].shotsFired, 0);
    expect(m.commandLog, isEmpty);
    expect(m.state.tick, 1);
  });

  test('항복하면 상대가 이기고 이후 커맨드는 적용하지 않는다', () {
    final m = newSampleMatch(1)
      ..step([const SurrenderCommand(tick: 0, side: 1), _fire(0, 1, 0)]);
    expect(m.state.outcome, MatchOutcome.surrender);
    expect(m.state.winner, 0);
    // 같은 틱에서는 FIRE 가 SURRENDER 보다 먼저 적용된다.
    expect(m.state.sides[1].shotsFired, 1);
    m.step([_fire(1, 0, 0)]);
    expect(m.state.tick, 1);
    expect(m.state.sides[0].shotsFired, 0);
  });

  test('3분(5400틱)이 지나면 시간 종료로 끝난다', () {
    final m = newSampleMatch(1);
    runMatch(m, _idle, _idle, ticks: 10000);
    expect(m.state.tick, matchDurationTicks);
    expect(m.state.outcome, MatchOutcome.timeUp);
    expect(m.state.winner, -1);
  });

  test('컨트롤러는 자기 진영 커맨드만 낼 수 있다', () {
    final m = newSampleMatch(1);
    runMatch(m, ScriptedController([_fire(0, 1, 0)]), _idle, ticks: 1);
    expect(m.state.sides[1].shotsFired, 0);
  });
}
