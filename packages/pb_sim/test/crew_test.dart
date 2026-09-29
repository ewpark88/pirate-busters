import 'package:pb_sim/pb_sim.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

List<SimEventKind> _kinds(List<SimEvent> events) => [
  for (final e in events) e.kind,
];

void main() {
  test('선실이 부서지면 해적은 최대 체력 20% 를 잃고 바다에 떨어졌다가 다음 내 턴 시작에 돌아온다', () {
    final crew = Crew([testPirate('a')]);
    final events = <SimEvent>[];
    crew.fall(0, 0, events);
    final p = crew.pirates[0];
    expect(p.hp, 240);
    expect(p.status, PirateStatus.swimming);
    expect(crew.canFire(0), isFalse);
    expect(_kinds(events), [SimEventKind.pirateHit, SimEventKind.pirateFell]);

    events.clear();
    crew.startOwnTurn(0, events);
    expect(p.status, PirateStatus.aboard);
    expect(_kinds(events), [SimEventKind.pirateReturned]);
  });

  test('바다에 빠진 해적은 한 번만 맞아도 KO 된다', () {
    final crew = Crew([testPirate('a')]);
    final events = <SimEvent>[];
    crew
      ..fall(0, 0, events)
      ..damage(0, 1, 0, events);
    expect(crew.pirates[0].status, PirateStatus.down);
    expect(crew.pirates[0].hp, 0);
  });

  test('떨어질 때 입은 피해로 쓰러지면 바다에 떨어지지 않는다', () {
    final crew = Crew([testPirate('a')])..pirates[0].hp = 50;
    final events = <SimEvent>[];
    crew.fall(0, 0, events);
    expect(crew.pirates[0].status, PirateStatus.down);
    expect(_kinds(events), isNot(contains(SimEventKind.pirateFell)));
  });

  test('모든 해적이 KO 되면 전멸이고, 쓰러진 선실은 빈 채로 남는다', () {
    final crew = Crew([testPirate('a'), testPirate('b')]);
    final events = <SimEvent>[];
    crew.damage(0, 1000, 0, events);
    expect(crew.allDown, isFalse);
    expect(crew.canFire(0), isFalse);
    crew.damage(1, 1000, 0, events);
    expect(crew.allDown, isTrue);
  });

  test('쏘면 쿨다운이 걸리고 내 턴이 끝날 때마다 하나씩 준다', () {
    final crew = Crew([testPirate('a', cooldownTurns: 2)])..markFired(0);
    final left = <int>[];
    for (var i = 0; i < 4; i++) {
      left.add(crew.pirates[0].cooldown);
      crew.endOwnTurn();
    }
    expect(left, [3, 2, 1, 0]);
  });
}
