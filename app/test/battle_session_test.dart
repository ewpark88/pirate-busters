import 'package:flutter_test/flutter_test.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/battle/battle_session.dart';
import 'package:pirate_busters/battle/battle_setup.dart';
import 'package:pirate_busters/battle/dummy_controller.dart';
import 'package:pirate_busters/battle/playback.dart';
import 'package:pirate_busters/battle/session_views.dart';

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

    test('쏘면 발사 이벤트가 바로 나오고, 착탄 효과는 탄 비행 연출이 끝난 뒤 나온다', () {
      final s = _humanFirst()
        ..update(500)
        ..fire(0, 30000, 9000);
      final shot = s.playback! as ShotPlayback;
      expect(shot.path.lastTick, greaterThan(10));
      // 발사 이벤트(공격 동작·포성)는 바로, 착탄 효과는 연출 뒤에 나온다.
      expect(s.takeCues().map((e) => e.kind), [SimEventKind.fire]);
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

    test('내 탄이 나는 동안 탭하면 TAP 이 발사로부터의 틱 수로 기록된다', () {
      final s = _humanFirst()
        ..update(500)
        ..fire(0, 45000, 10000)
        ..update(300)
        ..tap();
      _drain(s);
      s.endTurn();
      final taps = s.match.turnLog.first.commands.whereType<TapCommand>();
      expect(taps.single.tick, 9);
    });

    test('상대 턴에 누른 항복은 내 턴이 오면 바로 낸다 (설계서 §13.4)', () {
      final s = _humanFirst()
        ..update(100)
        ..endTurn()
        ..surrender();
      expect(s.surrenderQueued, isTrue);
      expect(s.isOver, isFalse);
      var guard = 0;
      while (!s.isOver && guard++ < 3000) {
        s.update(100);
      }
      expect(s.state.outcome, MatchOutcome.surrender);
      expect(s.state.winner, 1);
    });

    test('상대 턴에 미리 고른 해적은 내 턴에도 강조되고, 그 해적을 쏘면 풀린다', () {
      final s = _humanFirst()
        ..update(100)
        ..endTurn()
        ..preselect(2);
      expect(s.preselected, 2);
      var guard = 0;
      while (!s.isHumanTurn && guard++ < 2000) {
        s.update(100);
      }
      _drain(s);
      s.update(10);
      expect(s.preselected, 2);
      s.fire(2, 30000, 8000);
      expect(s.preselected, isNull);
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

    test('이동 버튼을 누르는 동안은 1/10칸씩 이어서 움직이고 쏠 수 없다 (ADR-030)', () {
      final s = _humanFirst()
        ..update(100)
        ..moveHeld = true;
      expect(s.canFire(0), isFalse);
      for (var i = 0; i < 10; i++) {
        if (s.playback == null) s.move(1);
        s.update(40);
      }
      expect(s.state.sides[0].offset, greaterThanOrEqualTo(800));
      s.moveHeld = false;
      _drain(s);
      expect(s.canFire(0), isTrue);
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
