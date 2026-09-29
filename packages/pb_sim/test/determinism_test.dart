import 'dart:convert';

import 'package:pb_sim/pb_sim.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

/// 샘플 매치(시드 20260929, 1,000틱)의 기대 해시. 의도한 규칙 변경일 때만 갱신하고
/// 커밋 메시지에 이유를 적는다 (개발 계획서 §2.4 DoD 2).
const int _goldenHash = 2447913407;

int _hash(Match m) => hashMatchState(m.state);

void main() {
  test('같은 시드와 커맨드로 1,000틱을 돌리면 해시가 매번 같다', () {
    final first = runSampleHash(seed: 20260929);
    for (var i = 0; i < 20; i++) {
      expect(runSampleHash(seed: 20260929), first);
    }
  });

  test('1,000틱 해시는 기록해 둔 골든 값과 같다', () {
    expect(runSampleHash(seed: 20260929), _goldenHash);
  });

  test('시드가 다르면 해시가 달라진다', () {
    expect(runSampleHash(seed: 1), isNot(runSampleHash(seed: 2)));
  });

  test('커맨드가 하나라도 다르면 해시가 달라진다', () {
    Match run(int angle) {
      final m = newSampleMatch(5);
      runMatch(
        m,
        ScriptedController([
          FireCommand(tick: 10, side: 0, slot: 0, angle: angle, power: 5000),
        ]),
        ScriptedController(const []),
        ticks: 100,
      );
      return m;
    }

    expect(_hash(run(45000)), isNot(_hash(run(45001))));
  });

  test('리플레이를 JSON 으로 저장했다 다시 읽어 돌려도 해시가 같다', () {
    const seed = 424242;
    final match = newSampleMatch(seed);
    final script = ScriptedController(sampleScript());
    runMatch(match, script, script, ticks: 1000);
    expect(match.state.sides[0].shots, isNotEmpty);
    expect(match.state.sides[1].shots, isNotEmpty);
    final replay = Replay.fromMatch(
      seed: seed,
      blueprints: [sampleBlueprint(), sampleBlueprint()],
      decks: sampleDecks,
      match: match,
    );

    final text = jsonEncode(replay.toJson());
    final loaded = Replay.fromJson(jsonDecode(text) as Map<String, Object?>);

    expect(jsonEncode(loaded.toJson()), text);
    expect(_hash(loaded.play(ticks: 1000)), _hash(match));
    expect(_hash(replay.play(ticks: 1000)), _hash(match));
  });

  test('항복으로 끝난 판은 리플레이를 끝까지 돌려도 같은 곳에서 끝난다', () {
    final match = newSampleMatch(9);
    final script = ScriptedController([
      ...sampleScript(ticks: 300),
      const SurrenderCommand(tick: 300, side: 0),
    ]);
    runMatch(match, script, script, ticks: matchDurationTicks);
    final replay = Replay.fromMatch(
      seed: 9,
      blueprints: [sampleBlueprint(), sampleBlueprint()],
      decks: sampleDecks,
      match: match,
    );
    final again = replay.play();
    expect(again.state.tick, 301);
    expect(again.state.winner, 1);
    expect(_hash(again), _hash(match));
  });

  test('지원하지 않는 리플레이 버전은 거부한다', () {
    final json = Replay(
      seed: 1,
      blueprints: [sampleBlueprint(), sampleBlueprint()],
      decks: sampleDecks,
      commands: const [],
    ).toJson()..['version'] = 99;
    expect(() => Replay.fromJson(json), throwsFormatException);
  });
}
