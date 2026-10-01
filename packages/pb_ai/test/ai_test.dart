import 'package:pb_ai/pb_ai.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

/// [a] 가 왼쪽·오른쪽을 번갈아 맡아 [games] 판 둔 승수.
int _wins(AiLevel a, AiLevel b, int games) {
  var wins = 0;
  for (var i = 0; i < games; i++) {
    final left = i.isEven;
    final m = newMatch(100 + i);
    runMatch(
      m,
      AiController(level: left ? a : b),
      AiController(level: left ? b : a),
    );
    if (m.state.winner == (left ? 0 : 1)) wins++;
  }
  return wins;
}

void main() {
  group('AI 컨트롤러 (설계서 §5)', () {
    test('같은 판·같은 턴이면 같은 턴 묶음을 내고, 계획해도 매치 상태는 그대로다', () {
      for (final level in AiLevel.values) {
        final m = newMatch(7)..apply(const MoveCommand(t: 0, dx: 0));
        final before = hashMatchState(m.state);
        final ai = AiController(level: level);
        final a = ai.turnFor(m.state).toJson();
        expect(hashMatchState(m.state), before, reason: '$level');
        expect(ai.turnFor(m.state).toJson(), a, reason: '$level');
      }
    });

    test('사람과 같은 커맨드만 쓰고, 발사는 2번 이하, 시각은 줄지 않는다 (§5.5)', () {
      final m = newMatch(9, left: const ['uni', 'octo', 'pang']);
      final bundle = const AiController(level: AiLevel.hell).turnFor(m.state);
      var t = 0;
      for (final c in bundle.commands) {
        expect(
          c,
          anyOf(
            isA<MoveCommand>(),
            isA<FireCommand>(),
            isA<TapCommand>(),
            isA<EndTurnCommand>(),
          ),
        );
        expect(c.t, greaterThanOrEqualTo(t));
        t = c.t;
      }
      expect(
        bundle.commands.whereType<FireCommand>().length,
        lessThanOrEqualTo(2),
      );
      expect(bundle.commands.last, isA<EndTurnCommand>());
    });

    test('쉬움은 움직이지 않고 지원 해적을 쓰지 않는다 (A5.2, A5.5)', () {
      for (var seed = 1; seed < 6; seed++) {
        final m = newMatch(
          seed,
          left: const ['tok', 'octo'],
          right: const ['tok', 'octo'],
        );
        m.state.sides[m.state.activeSide].flood = 800;
        final bundle = const AiController(level: AiLevel.easy).turnFor(m.state);
        expect(bundle.commands.whereType<MoveCommand>(), isEmpty);
        expect(
          bundle.commands.whereType<FireCommand>().where((f) => f.slot == 0),
          isEmpty,
        );
      }
    });

    test('AI 끼리 끝까지 두어도 판이 끝나고 턴 묶음 재생 해시가 같다', () {
      final m = newMatch(
        21,
        left: const ['uni', 'octo'],
        right: const ['suri', 'pang'],
      );
      runMatch(
        m,
        const AiController(level: AiLevel.hard),
        const AiController(
          level: AiLevel.normal,
          personality: Personality.hunter,
        ),
      );
      expect(m.isOver, isTrue);
      final again = newMatch(
        21,
        left: const ['uni', 'octo'],
        right: const ['suri', 'pang'],
      );
      m.turnLog.forEach(again.playTurn);
      expect(hashMatchState(again.state), hashMatchState(m.state));
    });

    test('연패 보정: 3연패마다 각도 오차 +1°, 최대 +3° (A5.2)', () {
      expect(
        [
          for (final n in [0, 2, 3, 6, 9, 30]) AiDials.streakBonusMdeg(n),
        ],
        [0, 0, 1000, 2000, 3000, 3000],
      );
    });
  });

  // 이웃한 난이도의 차이(보통 → 어려움 → 지옥)는 작은 테스트 배·2명 덱에서 판
  // 수가 적으면 흔들리므로 `sim_runner` 1000판으로 잰다(PROGRESS, ADR-050).
  // 여기서는 차이가 큰 쌍으로 서열이 뒤집히지 않는지만 본다.
  test('난이도가 높은 AI 가 낮은 AI 를 이긴다 (보통 > 쉬움, 어려움 > 쉬움, 지옥 > 보통)', () {
    const games = 40;
    expect(_wins(AiLevel.normal, AiLevel.easy, games), greaterThan(games ~/ 2));
    expect(_wins(AiLevel.hard, AiLevel.easy, games), greaterThan(games ~/ 2));
    expect(_wins(AiLevel.hell, AiLevel.normal, games), greaterThan(games ~/ 2));
  });

  test('프레임마다 나눠 계산해도 한 번에 계산한 것과 같은 턴 묶음이 나온다 (A5.1)', () {
    for (final level in AiLevel.values) {
      final m = newMatch(13, left: const ['uni', 'octo', 'pang']);
      final whole = AiPlanner(m.state, level: level).plan().toJson();
      final split = AiPlanner(m.state, level: level);
      var frames = 0;
      while (!split.step()) {
        frames++;
      }
      expect(split.bundle!.toJson(), whole, reason: '$level');
      expect(frames, greaterThan(0));
    }
  });

  test('난이도 다이얼 표는 BALANCE.md A5.2·A5.5 와 같다', () {
    List<Object> row(AiLevel l) {
      final d = AiDials.of(l);
      return [
        d.angleErrorMdeg,
        d.thinkMs,
        d.pickTopPercent,
        d.waveTiming,
        d.support,
        d.positions,
        d.combo,
        d.windCorrectionPercent,
        d.timeMode,
      ];
    }

    expect(row(AiLevel.easy), [
      8000,
      2500,
      50,
      false,
      SupportUse.never,
      0,
      false,
      50,
      false,
    ]);
    expect(row(AiLevel.normal), [
      4000,
      1500,
      20,
      false,
      SupportUse.timely,
      3,
      false,
      75,
      false,
    ]);
    expect(row(AiLevel.hard), [
      2000,
      800,
      5,
      true,
      SupportUse.timely,
      5,
      true,
      95,
      true,
    ]);
    expect(row(AiLevel.hell), [
      500,
      300,
      0,
      true,
      SupportUse.timely,
      7,
      true,
      100,
      true,
    ]);
    expect(
      [AiDials.positionStepCells, AiDials.timeModeTurn, AiDials.fuelReserve],
      [2, 22, 40],
    );
  });

  test('분열탄 해적이 있으면 AI 가 탭 시점을 골라 FIRE 뒤에 같은 t 의 TAP 을 낸다 (§4.8)', () {
    var taps = 0;
    for (var seed = 1; seed <= 20 && taps == 0; seed++) {
      final m = newMatch(seed, left: const ['uni', 'octo']);
      if (m.state.activeSide != 0) continue;
      final bundle = const AiController(level: AiLevel.hell).turnFor(m.state);
      final cmds = bundle.commands;
      for (var i = 0; i < cmds.length; i++) {
        final c = cmds[i];
        if (c is! TapCommand) continue;
        final fire = cmds[i - 1] as FireCommand;
        expect([c.slot, c.t], [fire.slot, fire.t]);
        expect(c.ticks, greaterThan(0));
        taps++;
      }
    }
    expect(taps, greaterThan(0));
  });
}
