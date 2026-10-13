import 'package:flutter_test/flutter_test.dart';
import 'package:pb_ai/pb_ai.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/battle/battle_session.dart';
import 'package:pirate_busters/battle/playback.dart';
import 'package:pirate_busters/battle/script_player.dart';
import 'package:pirate_busters/battle/session_views.dart';

import 'test_catalog.dart';

const _ai = AiController(level: AiLevel.easy);

/// AI(0 진영)가 선공이고 첫 턴에 두 발 이상 쏘는 시드.
int _multiShotSeed() {
  for (var seed = 1; seed < 200; seed++) {
    final m = testSetup.newMatch(seed);
    if (m.state.activeSide != 0) continue;
    final fires = _ai.turnFor(m.state).commands.whereType<FireCommand>();
    if (fires.length >= 2) return seed;
  }
  throw StateError('두 발 쏘는 시드가 없다');
}

/// 상대 턴 재생 한 판의 기록.
class _Trace {
  final shots = <({int slot, int firedAt, int endedAt})>[];
  final aimBefore = <int, ({int slot, double progress})>{};
  int minRemaining = 1 << 30;
}

_Trace _playAiTurn(BattleSession s) {
  final t = _Trace();
  Playback? last;
  var firedAt = 0;
  ({int slot, double progress})? aim;
  var guard = 0;
  while (!s.isHumanTurn && !s.isOver && guard++ < 20000) {
    s.update(16);
    final p = s.playback;
    if (last is ShotPlayback && !identical(p, last)) {
      t.shots.add((slot: last.slot, firedAt: firedAt, endedAt: s.turnMs));
    }
    if (p is ShotPlayback && !identical(p, last)) {
      if (aim != null) t.aimBefore[t.shots.length] = aim;
      aim = null;
      firedAt = s.turnMs;
    }
    last = p;
    aim = s.opponentAim ?? aim;
    if (!s.isHumanTurn) {
      t.minRemaining = s.remainingMs < t.minRemaining
          ? s.remainingMs
          : t.minRemaining;
    }
  }
  return t;
}

void main() {
  group('상대 발사 사이 연출 간격 (설계서 §2.1·§2.3·§5.5, A62)', () {
    late int seed;
    late BattleSession s;
    late _Trace trace;

    setUpAll(() {
      seed = _multiShotSeed();
      s = BattleSession(
        testSetup.newMatch(seed),
        humanSides: const {1},
        speciesOf: testCatalog.speciesOf,
        opponent: _ai,
      );
      trace = _playAiTurn(s);
    });

    test('앞 탄 연출이 끝나고 쉼이 지나야 다음 해적이 쏜다', () {
      expect(trace.shots.length, greaterThanOrEqualTo(2));
      for (var i = 1; i < trace.shots.length; i++) {
        final gap = trace.shots[i].firedAt - trace.shots[i - 1].endedAt;
        expect(gap, greaterThanOrEqualTo(ScriptPlayer.settleMs));
      }
    });

    test('쏘기 직전에 그 해적의 조준이 끝까지 차 있다', () {
      for (var i = 0; i < trace.shots.length; i++) {
        final aim = trace.aimBefore[i];
        expect(aim, isNotNull, reason: '$i 번째 발사 전 조준');
        expect(aim!.slot, trace.shots[i].slot);
        expect(aim.progress, greaterThan(0.9));
      }
    });

    test('상대 턴 동안 남은 시간이 0 이 되지 않는다', () {
      expect(trace.minRemaining, greaterThan(0));
    });

    test('시뮬레이션에 들어간 커맨드 시각은 AI 묶음 그대로다', () {
      final planned = _ai.turnFor(testSetup.newMatch(seed).state);
      final played = s.match.turnLog.first;
      expect(played.turn, planned.turn);
      expect(
        [for (final c in played.commands) (c.runtimeType, c.t)],
        [for (final c in planned.commands) (c.runtimeType, c.t)],
      );
    });

    test('상대 조준 중이면 다음 해적이 정해지고, 쉬는 동안 조준은 0 이다', () {
      final p = ScriptPlayer()
        ..bundle = TurnBundle(
          turn: 1,
          side: 1,
          commands: const [FireCommand(t: 500, slot: 2, angle: 30, power: 50)],
        );
      expect(p.aim(1000), (slot: 2, progress: 0.0));
      p.tick(ScriptPlayer.settleMs);
      expect(p.due, isNull);
      p.tick(250);
      expect(p.aim(1000)!.progress, closeTo(0.5, 1e-9));
      p.tick(250);
      expect(p.due, isA<FireCommand>());
    });
  });
}
