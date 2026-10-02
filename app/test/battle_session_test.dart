import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:pb_ai/pb_ai.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/battle/auto_end.dart';
import 'package:pirate_busters/battle/battle_session.dart';
import 'package:pirate_busters/battle/playback.dart';
import 'package:pirate_busters/battle/session_views.dart';

import 'test_catalog.dart';

/// 사람이 선공인 시드를 찾아 허수아비전 세션을 만든다.
BattleSession _humanFirst({bool hotseat = false}) {
  for (var seed = 1; ; seed++) {
    final m = testSetup.newMatch(seed);
    if (m.state.activeSide == 0) {
      return BattleSession(
        m,
        humanSides: hotseat ? const {0, 1} : const {0},
        speciesOf: testCatalog.speciesOf,
        opponent: hotseat ? null : const AiController(level: AiLevel.easy),
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
      expect(shot.lastTick, greaterThan(10));
      // 발사 이벤트(공격 동작·포성)는 바로, 착탄 효과는 연출 뒤에 나온다.
      expect(s.takeCues().map((e) => e.kind), [SimEventKind.fire]);
      _drain(s);
      final cues = s.takeCues().map((e) => e.kind);
      expect(
        cues,
        anyOf(contains(SimEventKind.impact), contains(SimEventKind.splash)),
      );
    });

    test('2발을 쏘면 유예 뒤 턴이 넘어가고, AI 가 두고 다시 내 턴이 온다 (ADR-042)', () {
      final s = _humanFirst()
        ..update(500)
        ..fire(0, 30000, 9000);
      _drain(s);
      s.fire(1, 35000, 9000);
      _drain(s);
      expect(s.isHumanTurn, isTrue, reason: '유예 동안은 이동할 수 있다');
      s.update(AutoEndClock.graceMs);
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
      final path = shot.traces.single;
      final n = path.xs.length - 1;
      expect(path.xs.sublist(0, n), preview.xs.sublist(0, n));
      expect(path.ys.sublist(0, n), preview.ys.sublist(0, n));
    });

    test('조준 표시의 발사 방향(조준 각도 + 배 기울기)은 실제 탄이 나가는 방향과 같다', () {
      for (final at in const [300, 1300, 2300, 3300]) {
        final s = _humanFirst()..update(at);
        final p = launchShot(
          s.state,
          slot: 1,
          angle: 25000,
          power: 8000,
          ms: realMs(s.state, effectiveMs(s.state, s.turnMs)),
        );
        final facing = s.state.activeSide == 0 ? 1 : -1;
        final deg = math.atan2(p.vy, p.vx * facing) * 180 / math.pi;
        expect(deg, closeTo((25000 + s.launchTilt) / 1000, .1));
      }
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
      expect(taps.single.ticks, 9);
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

    test('상대 턴에 고른 해적은 내 턴에 줌인 대상이 되고, 그 해적을 쏘면 풀린다 (ADR-033)', () {
      final s = _humanFirst()
        ..update(100)
        ..endTurn()
        ..select(1);
      expect(s.selected, 1);
      expect(s.focusSlot, isNull, reason: '상대 턴에는 줌인하지 않는다');
      var guard = 0;
      while (!s.isHumanTurn && guard++ < 2000) {
        s.update(100);
      }
      _drain(s);
      s.update(10);
      expect(s.focusSlot, 1);
      s.fire(1, 30000, 8000);
      expect(s.selected, isNull);
    });

    test('같은 카드를 다시 누르면 선택이 풀리고, 내 턴이 끝나면 풀린다', () {
      final s = _humanFirst()
        ..update(100)
        ..select(1);
      expect(s.focusSlot, 1);
      s.select(1);
      expect(s.selected, isNull);
      s
        ..select(3)
        ..select(0, toggle: false)
        ..select(0, toggle: false);
      expect(s.selected, 0, reason: '해적을 끌 때는 풀리지 않는다');
      s
        ..endTurn()
        ..update(10);
      expect(s.selected, isNull);
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
      final me = s.state.sides[0];
      me.fuel = me.fuelPerCell * 5 ~/ 2; // 2.5칸 (무게 연료 반영, 설계서 §2.7)
      expect(s.reach(80), 2500);
      expect(s.reach(-3), -300);
    });
  });

  group('AI 상대 (설계서 §5, ADR-040)', () {
    test('AI 는 프레임마다 나눠 계획한 뒤 사람과 같은 커맨드로 두고 턴을 넘긴다', () {
      final s = _humanFirst()
        ..update(100)
        ..endTurn();
      expect(s.isHumanTurn, isFalse);
      s.update(16);
      expect(s.state.turn, 2, reason: '계획이 한 프레임에 끝나지 않는다');
      var guard = 0;
      while (!s.isHumanTurn && !s.isOver && guard++ < 5000) {
        s.update(16);
      }
      expect(s.isHumanTurn || s.isOver, isTrue);
      final log = s.match.turnLog[1];
      expect(
        log.commands.every(
          (c) =>
              c is MoveCommand ||
              c is FireCommand ||
              c is TapCommand ||
              c is EndTurnCommand,
        ),
        isTrue,
      );
    });

    test('AI 가 쏘기 전 조준 자세는 난이도별 생각 연출 시간만큼 보인다 (A5.2)', () {
      final s = _humanFirst();
      expect(s.aimShowMs, AiDials.of(AiLevel.easy).thinkMs);
    });

    test('AI 덱은 플레이어 덱과 같은 인원이다', () {
      final m = testSetup.newMatch(
        4,
        deck: const ['p01_octo', 'p06_pang', 'p16_suri'],
      );
      expect(m.state.sides[1].crew.size, 3);
    });
  });

  test('자동 턴 종료를 끄면 2발을 쏴도 턴이 넘어가지 않는다 (§2.2)', () {
    final clock = AutoEndClock()..enabled = false;
    expect(clock.tick(5000, done: true, held: false), isFalse);
    clock.enabled = true;
    expect(clock.tick(1000, done: true, held: true), isFalse, reason: '이동 중');
    expect(clock.tick(1000, done: true, held: false), isFalse);
    expect(clock.tick(600, done: true, held: false), isTrue);
  });
}
