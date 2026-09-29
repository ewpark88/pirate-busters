import 'dart:convert';
import 'dart:io';

import 'package:pb_sim/pb_sim.dart';
import 'package:test/test.dart';

import 'golden/golden_scenarios.dart';

/// 골든 리플레이 (개발 계획서 M3): 판 끝 방식마다 하나 + 무작위 4판. 규칙을 일부러
/// 바꿨으면 `dart run test/golden/generate.dart` 로 다시 만들고 커밋 메시지에 이유를 적는다.
void main() {
  // 헤드리스 판은 한 번씩만 돌려 여러 검사에서 같이 쓴다.
  final results = <String, MatchResult>{};
  MatchResult resultOf(GoldenScenario g) => results.putIfAbsent(g.name, g.run);

  for (final g in goldenScenarios) {
    group('골든 ${g.name}', () {
      final file = File('test/golden/${g.name}.json');
      final json = jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
      final want = json['expect']! as Map<String, Object?>;

      test('저장된 리플레이를 재생하면 모든 턴 해시와 결과가 같다', () {
        final replay = Replay.fromJson(json['replay']! as Map<String, Object?>);
        final m = replay.play(pirates: goldenCatalog);
        expect(m.state.outcome.name, want['outcome']);
        expect(m.state.winner, want['winner']);
        expect(m.turnLog, hasLength(want['turns']));
        expect(
          hashMatchState(m.state).toRadixString(16).padLeft(8, '0'),
          want['hash'],
        );
      });

      test('헤드리스로 다시 돌려도 같은 결과·해시가 나온다', () {
        final r = resultOf(g);
        expect(r.outcome.name, want['outcome']);
        expect(r.winner, want['winner']);
        expect(r.turns, want['turns']);
        expect(r.hash.toRadixString(16).padLeft(8, '0'), want['hash']);
      });
    });
  }

  test('골든 판들은 격침(내구도)·격침(침수)·전멸·시간 판정·무승부·항복을 모두 다룬다', () {
    final outcomes = {
      for (final g in goldenScenarios) resultOf(g).outcome,
    };
    expect(
      outcomes,
      containsAll(<MatchOutcome>[
        MatchOutcome.sunk,
        MatchOutcome.floodSunk,
        MatchOutcome.annihilation,
        MatchOutcome.timeDecision,
        MatchOutcome.surrender,
      ]),
    );
    final draws = goldenScenarios.where((g) => resultOf(g).winner == -1);
    expect(draws, isNotEmpty);
  });

  test('무작위 골든 판에는 이동이 섞여 있고 연료·위치가 해시에 들어간다', () {
    final r = resultOf(goldenScenarios.last);
    final moves = r.replay.turns
        .expand((b) => b.commands)
        .whereType<MoveCommand>();
    expect(moves, isNotEmpty);
    final m = r.replay.play(pirates: goldenCatalog);
    final before = hashMatchState(m.state);
    m.state.sides[0].fuel += 1;
    expect(hashMatchState(m.state), isNot(before));
    m.state.sides[0]
      ..fuel -= 1
      ..offset += 100;
    expect(hashMatchState(m.state), isNot(before));
  });
}
