import 'package:pb_sim/pb_sim.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

List<SimEventKind> _kinds(List<SimEvent> events) => [
  for (final e in events) e.kind,
];

void main() {
  test('선실이 무너져 바다에 떨어진 해적은 KO 다 (설계서 §2.3)', () {
    final crew = Crew([testPirate('a'), testPirate('b')]);
    final events = <SimEvent>[];
    crew.fall(0, 0, events);
    final p = crew.pirates[0];
    expect(p.status, PirateStatus.down);
    expect(p.hp, 0);
    expect(crew.canFire(0), isFalse);
    expect(_kinds(events), [SimEventKind.pirateFell, SimEventKind.pirateDown]);
    expect(crew.hpLeft, 300);
    expect(crew.hpStart, 600);
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

  test('쏜 해적은 이번 턴에 다시 못 쏘고, 내 턴이 끝나면 다음 턴에 또 쏜다 (쿨다운 없음)', () {
    final crew = Crew([testPirate('a')])..markFired(0);
    expect(crew.canFire(0), isFalse);
    crew.endOwnTurn();
    expect(crew.canFire(0), isTrue);
  });

  test('덱 검사는 예외 없이 문제를 알려 주고 코스트 한도는 레벨마다 +1 (§4.5)', () {
    expect(costLimitForLevel(1), 15);
    expect(costLimitForLevel(20), 34);
    const hull = HullSpec.sloop;
    expect(deckProblem(hull, sampleCatalog, ['p01', 'p06'], 15), isNull);
    expect(
      deckProblem(hull, sampleCatalog, ['nobody'], 15),
      contains('알 수 없는'),
    );
    expect(deckProblem(hull, sampleCatalog, ['p01', 'p01'], 15), contains('둘'));
    expect(
      deckProblem(hull, sampleCatalog, ['p01', 'p06', 'p11', 'p16'], 11),
      contains('코스트'),
    );
  });
}
