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

  test('난이도가 올라갈수록 AI 대 AI 승률이 오른다 (완료 조건)', () {
    const games = 20;
    expect(_wins(AiLevel.normal, AiLevel.easy, games), greaterThan(games ~/ 2));
    expect(_wins(AiLevel.hard, AiLevel.normal, games), greaterThan(games ~/ 2));
    expect(
      _wins(AiLevel.hell, AiLevel.hard, games),
      greaterThanOrEqualTo(games ~/ 2),
    );
  });
}
