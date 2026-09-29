import 'package:pb_sim/pb_sim.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

List<SimEventKind> _kinds(List<SimEvent> events) => [
  for (final e in events) e.kind,
];

void main() {
  test('덱 앞에서부터 선실에 타고 나머지는 교대 대기열에 선다', () {
    final crew = Crew([for (var i = 0; i < 6; i++) testPirate('p$i')], 4);
    expect(
      [for (final p in crew.pirates) p.status],
      [
        ...List.filled(4, PirateStatus.aboard),
        PirateStatus.queued,
        PirateStatus.queued,
      ],
    );
    expect([for (var s = 0; s < 4; s++) crew.pirateIndexAt(s)], [0, 1, 2, 3]);
    expect(crew.canFire(0), isTrue);
  });

  test('선실이 부서지면 해적은 최대 체력 20% 를 잃고 바다에 떨어졌다가 4초 뒤 돌아온다', () {
    final crew = Crew([testPirate('a')], 4);
    final events = <SimEvent>[];
    crew.fall(0, 0, events);
    final p = crew.pirateAt(0)!;
    expect(p.hp, 240);
    expect(p.status, PirateStatus.swimming);
    expect(crew.canFire(0), isFalse);
    expect(_kinds(events), [SimEventKind.pirateHit, SimEventKind.pirateFell]);

    for (var t = 1; t < swimTicks; t++) {
      crew.tick(0, events);
    }
    expect(p.status, PirateStatus.swimming);
    events.clear();
    crew.tick(0, events);
    expect(p.status, PirateStatus.aboard);
    expect(_kinds(events), [SimEventKind.pirateReturned]);
  });

  test('헤엄치는 해적은 한 번만 맞아도 쓰러진다', () {
    final crew = Crew([testPirate('a')], 4);
    final events = <SimEvent>[];
    crew
      ..fall(0, 0, events)
      ..damage(0, 1, 0, events);
    expect(crew.pirates[0].status, PirateStatus.down);
    expect(crew.pirates[0].hp, 0);
  });

  test('선실 해적이 쓰러지면 대기열 다음 해적이 그 선실에 들어가 재장전부터 한다', () {
    final crew = Crew([
      testPirate('a'),
      testPirate('b'),
      testPirate('c'),
      testPirate('d'),
      testPirate('e', reloadTicks: 200),
    ], 4);
    final events = <SimEvent>[];
    crew.damage(2, 1000, 1, events);
    expect(crew.pirates[2].status, PirateStatus.down);
    expect(crew.pirateIndexAt(2), 4);
    expect(crew.pirates[4].reload, 200);
    expect(_kinds(events), [
      SimEventKind.pirateHit,
      SimEventKind.pirateDown,
      SimEventKind.pirateBoarded,
    ]);
    // 대기열이 비면 선실은 빈다.
    crew.damage(2, 1000, 1, events);
    expect(crew.pirateIndexAt(2), -1);
    expect(crew.pirateAt(2), isNull);
  });

  test('모든 해적이 쓰러지면 전멸이다', () {
    final crew = Crew([testPirate('a'), testPirate('b')], 4);
    final events = <SimEvent>[];
    crew.damage(0, 1000, 0, events);
    expect(crew.allDown, isFalse);
    crew.damage(1, 1000, 0, events);
    expect(crew.allDown, isTrue);
  });

  test('떨어질 때 입은 피해로 쓰러지면 바다에 떨어지지 않는다', () {
    final crew = Crew([testPirate('a')], 4)..pirates[0].hp = 50;
    final events = <SimEvent>[];
    crew.fall(0, 0, events);
    expect(crew.pirates[0].status, PirateStatus.down);
    expect(_kinds(events), isNot(contains(SimEventKind.pirateFell)));
  });
}
