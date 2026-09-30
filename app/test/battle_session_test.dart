import 'package:flutter_test/flutter_test.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/battle/battle_session.dart';
import 'package:pirate_busters/battle/battle_setup.dart';
import 'package:pirate_busters/battle/dummy_controller.dart';
import 'package:pirate_busters/battle/playback.dart';

/// 사람이 선공인 시드를 찾아 허수아비전 세션을 만든다.
BattleSession _humanFirst({bool hotseat = false}) {
  for (var seed = 1; ; seed++) {
    final m = BattleSetup.newMatch(seed);
    if (m.state.activeSide == 0) {
      return BattleSession(
        m,
        humanSides: hotseat ? const {0, 1} : const {0},
        opponent: hotseat ? null : const DummyController(),
      );
    }
  }
}

/// 연출이 끝날 때까지 돌린다.
void _drain(BattleSession s) {
  var guard = 0;
  while (s.playback != null && guard++ < 1000) {
    s.update(50);
  }
}

void main() {
  group('BattleSession (개발 계획서 M4)', () {
    test('내 턴에 움직이면 이동 연출이 나오고, 연출 동안은 조작할 수 없다', () {
      final s = _humanFirst()
        ..update(500)
        ..move(28);
      expect(s.playback, isA<MovePlayback>());
      expect(s.canAct, isFalse);
      expect(s.state.sides[0].offset, 2800);
      _drain(s);
      expect(s.canAct, isTrue);
    });

    test('쏘면 착탄 전까지 탄 비행 연출이 나오고, 끝나면 효과 이벤트가 나온다', () {
      final s = _humanFirst()
        ..update(500)
        ..fire(0, 30000, 9000);
      final shot = s.playback! as ShotPlayback;
      expect(shot.path.lastTick, greaterThan(10));
      expect(s.takeCues(), isEmpty);
      _drain(s);
      final cues = s.takeCues().map((e) => e.kind);
      expect(
        cues,
        anyOf(contains(SimEventKind.impact), contains(SimEventKind.splash)),
      );
    });

    test('2발을 쏘면 턴이 넘어가고, 허수아비가 두고 다시 내 턴이 온다', () {
      final s = _humanFirst()
        ..update(500)
        ..fire(0, 30000, 9000);
      _drain(s);
      s.fire(2, 35000, 9000);
      _drain(s);
      expect(s.isHumanTurn, isFalse);
      var guard = 0;
      while (!s.isHumanTurn && !s.isOver && guard++ < 2000) {
        s.update(100);
      }
      _drain(s); // 허수아비의 마지막 탄 연출
      expect(s.isHumanTurn, isTrue);
      expect(s.state.turn, 3);
      expect(s.turnMs, lessThan(1000), reason: '새 턴 시계');
    });

    test('남은 시간은 탄 비행 연출 동안 줄지 않는다', () {
      final s = _humanFirst()..update(1000);
      final before = s.remainingMs;
      s.fire(0, 45000, 10000);
      final flight = s.playback!.durationMs;
      expect(flight, greaterThan(500));
      s.update(400);
      expect(s.remainingMs, before);
    });

    test('시간이 다 되면 턴이 저절로 넘어간다', () {
      final s = _humanFirst();
      for (var i = 0; i < 260; i++) {
        s.update(100);
      }
      expect(s.state.turn, greaterThan(1));
    });

    test('궤적 미리보기는 실제로 쏜 탄의 경로와 같다', () {
      final s = _humanFirst()..update(700);
      final preview = s.previewShot(1, 25000, 8000);
      s.fire(1, 25000, 8000);
      final shot = s.playback! as ShotPlayback;
      final n = shot.path.lastTick - 1;
      expect(shot.path.xs.sublist(0, n), preview.xs.sublist(0, n));
      expect(shot.path.ys.sublist(0, n), preview.ys.sublist(0, n));
    });

    test('핫시트에서는 양쪽 모두 사람이 두고 컨트롤러를 부르지 않는다', () {
      final s = _humanFirst(hotseat: true)
        ..update(100)
        ..endTurn()
        ..update(100);
      expect(s.state.activeSide, 1);
      expect(s.isHumanTurn, isTrue);
      expect(s.canAct, isTrue);
    });

    test('항복하면 판이 끝나고 상대가 이긴다', () {
      final s = _humanFirst()
        ..update(100)
        ..surrender();
      expect(s.isOver, isTrue);
      expect(s.state.winner, 1);
    });

    test('누르고 있을 때의 이동 끝 지점은 시뮬레이션의 이동 거리와 같다', () {
      final s = _humanFirst()..update(100);
      s.state.sides[0].fuel = 10 * SideState.fuelUnit; // 2.5칸
      expect(s.reach(80), 2500);
      expect(s.reach(-3), -300);
    });
  });

  group('허수아비 (ADR-029)', () {
    test('같은 판·같은 턴이면 같은 커맨드를 내고, 사람과 같은 커맨드만 쓴다', () {
      final m = BattleSetup.newMatch(9);
      const dummy = DummyController();
      final a = dummy.turnFor(m.state).toJson();
      final b = dummy.turnFor(m.state).toJson();
      expect(a, b);
      final bundle = dummy.turnFor(m.state);
      expect(bundle.commands.last, isA<EndTurnCommand>());
      expect(
        bundle.commands.whereType<FireCommand>().length,
        lessThanOrEqualTo(2),
      );
    });

    test('허수아비끼리 끝까지 두면 판이 끝난다', () {
      final m = BattleSetup.newMatch(4);
      runMatch(m, const DummyController(), const DummyController());
      expect(m.state.isOver, isTrue);
    });
  });
}
