import 'dart:convert';

import 'package:pb_sim/pb_sim.dart';
import 'package:test/test.dart';

import 'aim.dart';
import 'fixtures.dart';

/// 샘플 매치(시드 20260929, 끝까지)의 기대 해시. 의도한 규칙 변경일 때만 갱신하고
/// 커밋 메시지에 이유를 적는다 (개발 계획서 §2.4 DoD 2).
const int _goldenHash = 1852174760;

int _hash(Match m) => hashMatchState(m.state);

Match _runSample(int seed) {
  final match = newSampleMatch(seed);
  runMatch(match, RandomController(7), RandomController(8));
  return match;
}

Replay _replayOf(Match m) => Replay.fromMatch(
  blueprints: [sampleBlueprint(), sampleBlueprint()],
  decks: sampleDecks,
  costLimits: sampleCostLimits,
  match: m,
);

void main() {
  test('같은 턴 묶음 목록(이동 포함)이면 연료·위치까지 최종 해시가 100번 모두 같다', () {
    final first = runSampleHash(seed: 20260929);
    for (var i = 0; i < 100; i++) {
      expect(runSampleHash(seed: 20260929), first);
    }
  });

  test('최종 해시는 기록해 둔 골든 값과 같다', () {
    expect(runSampleHash(seed: 20260929), _goldenHash);
  });

  test('샘플 매치는 발사·착탄·블록 파괴가 실제로 일어난다', () {
    final m = newSampleMatch(20260929);
    final kinds = <SimEventKind>{};
    for (var i = 0; i < 30 && !m.isOver; i++) {
      final s = m.state;
      final c = RandomController(s.activeSide == 0 ? 7 : 8);
      m.playTurn(c.turnFor(s));
      kinds.addAll([for (final e in s.events) e.kind]);
    }
    expect(
      kinds,
      containsAll([
        SimEventKind.fire,
        SimEventKind.impact,
        SimEventKind.splash,
        SimEventKind.blockDestroyed,
      ]),
    );
  });

  test('시드가 다르면 해시가 달라진다', () {
    expect(runSampleHash(seed: 1), isNot(runSampleHash(seed: 2)));
  });

  test('착탄 칸이 달라지면 해시가 달라진다', () {
    final base = aimAt(newSampleMatch(5).state, slot: 0, tx: 11, ty: 2, t: 10);
    int run(int angle) {
      final m = newSampleMatch(5)
        ..apply(FireCommand(t: 10, slot: 0, angle: angle, power: base.power));
      expect(
        m.state.events.where((e) => e.kind == SimEventKind.impact),
        hasLength(1),
      );
      return _hash(m);
    }

    expect(run(base.angle), isNot(run(base.angle + 5000)));
  });

  test('턴 묶음마다 턴 끝 해시가 기록된다', () {
    final m = _runSample(424242);
    expect(m.turnLog, isNotEmpty);
    expect(m.turnLog.every((b) => b.hash != null), isTrue);
    expect(m.turnLog.last.hash, _hash(m));
  });

  test('리플레이를 JSON 으로 저장했다 다시 읽어 돌려도 모든 턴 해시가 같다', () {
    final match = _runSample(424242);
    final replay = _replayOf(match);
    final text = jsonEncode(replay.toJson());
    final loaded = Replay.fromJson(jsonDecode(text) as Map<String, Object?>);

    expect(jsonEncode(loaded.toJson()), text);
    expect(_hash(loaded.play(pirates: sampleCatalog)), _hash(match));
    expect(_hash(replay.play(pirates: sampleCatalog)), _hash(match));
  });

  test('턴 해시가 다른 리플레이는 재생할 때 잡아낸다', () {
    final replay = _replayOf(_runSample(9));
    final t = replay.turns;
    final forged = Replay(
      seed: replay.seed,
      blueprints: replay.blueprints,
      decks: replay.decks,
      costLimits: replay.costLimits,
      turns: [
        TurnBundle(
          turn: t[0].turn,
          side: t[0].side,
          commands: t[0].commands,
          hash: (t[0].hash! + 1) & 0xFFFFFFFF,
        ),
        ...t.skip(1),
      ],
    );
    expect(
      () => forged.play(pirates: sampleCatalog),
      throwsA(isA<TurnHashMismatch>()),
    );
  });

  test('지원하지 않는 리플레이 버전은 거부한다', () {
    final json = _replayOf(newSampleMatch(1)).toJson()..['version'] = 2;
    expect(() => Replay.fromJson(json), throwsFormatException);
  });

  test('규칙 값이 범위 밖인 리플레이는 거부한다(0 나눗셈·한계선 역전·음수 침수 방지)', () {
    const bad = {
      'wavePeriodMs': 0,
      'waterlineDivisor': 0,
      'maxTurns': 0,
      'stormRetreatPull': 25000,
      'stormFloodPercent': -1,
      'sinkAtFullFlood': -1,
      'sunkHullPercent': 101,
    };
    for (final key in bad.keys) {
      final json = _replayOf(newSampleMatch(1)).toJson();
      (json['rules']! as Map<String, Object?>)[key] = bad[key];
      expect(() => Replay.fromJson(json), throwsFormatException, reason: key);
    }
  });
}
