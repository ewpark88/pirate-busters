import 'package:flutter_test/flutter_test.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/battle/battle_session.dart';
import 'package:pirate_busters/battle/dummy_controller.dart';
import 'package:pirate_busters/battle/playback.dart';

import 'test_catalog.dart';

/// [deck] 을 태운 사람이 선공인 허수아비전.
BattleSession _session(List<String> deck) {
  for (var seed = 1; ; seed++) {
    final m = testSetup.newMatch(seed, deck: deck);
    if (m.state.activeSide == 0) {
      return BattleSession(
        m,
        humanSides: const {0},
        speciesOf: testCatalog.speciesOf,
        opponent: const DummyController(),
      )..update(300);
    }
  }
}

List<SimEventKind> _drainCues(BattleSession s) {
  final kinds = <SimEventKind>[];
  var guard = 0;
  while (s.playback != null && guard++ < 1000) {
    s.update(33);
    kinds.addAll(s.takeCues().map((e) => e.kind));
  }
  return kinds;
}

void main() {
  group('분열탄 탭 (설계서 §2.2, §4.8)', () {
    test('우니를 쏘면 계산을 미루고 날다가, 탭한 틱에 조각으로 갈라진다', () {
      final s = _session(const ['p04_uni', 'p01_octo'])..fire(0, 45000, 9000);
      final flying = s.playback! as ShotPlayback;
      expect(flying.awaitingTap, isTrue);
      expect(s.match.pendingSlot, 0);
      s.update(400);
      final before = s.remainingMs;
      s.tap();
      final split = s.playback! as ShotPlayback;
      expect(split.awaitingTap, isFalse);
      expect(split.traces.length, greaterThan(1), reason: '조각 경로');
      expect(split.elapsedMs, flying.elapsedMs, reason: '같은 시각에서 잇는다');
      expect(s.remainingMs, before, reason: '비행 중 턴 시간은 줄지 않는다');
      final kinds = _drainCues(s);
      expect(kinds, contains(SimEventKind.divide));
    });

    test('탭하지 않으면 떨어지는 틱에 갈라지지 않은 채 계산한다', () {
      final s = _session(const ['p04_uni', 'p01_octo'])..fire(0, 45000, 9000);
      final kinds = _drainCues(s);
      expect(kinds, isNot(contains(SimEventKind.divide)));
      expect(
        kinds,
        anyOf(contains(SimEventKind.impact), contains(SimEventKind.splash)),
      );
      expect(s.match.pendingSlot, -1);
    });
  });

  test('연사탄(히포)은 여러 발이 차례로 날고 착탄 효과가 발마다 나온다', () {
    final s = _session(const ['p07_hippo', 'p01_octo'])..fire(0, 20000, 10000);
    final shot = s.playback! as ShotPlayback;
    expect(shot.traces.length, 3);
    expect([for (final t in shot.traces) t.startTick], [0, 3, 6]);
    final kinds = _drainCues(s);
    final landings = kinds.where(
      (k) => k == SimEventKind.impact || k == SimEventKind.splash,
    );
    expect(landings.length, 3);
  });
}
