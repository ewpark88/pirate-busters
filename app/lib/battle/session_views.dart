import 'package:pb_ai/pb_ai.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/battle/battle_session.dart';
import 'package:pirate_busters/battle/playback.dart';
import 'package:pirate_busters/battle/shot_path.dart';

/// 세션 상태로 계산만 하는 보기 (판정은 pb_sim 함수를 그대로 쓴다).
extension BattleSessionViews on BattleSession {
  /// 지금 쏘면 날아갈 궤적(미리보기).
  ShotPath previewShot(int slot, int angle, int power) => ShotPath.predict(
    state,
    slot: slot,
    angle: angle,
    power: power,
    ms: realMs(state, effectiveMs(state, turnMs)),
  );

  /// 지금 쏘면 조준 각도에 더해지는 배 기울기(밀리도, 파도 + 침수, 설계서 §2.5).
  /// 조준 표시의 호·새총·각도 숫자를 실제 발사 방향에 맞추는 데 쓴다.
  int get launchTilt => tiltAtMs(
    state,
    state.activeSide,
    realMs(state, effectiveMs(state, turnMs)),
  );

  /// 지금 [dx](1/10칸)를 누르면 실제로 갈 거리(1/1000칸). 시뮬레이션의 [moveReach].
  int reach(int dx) {
    final at = effectiveMs(state, turnMs);
    return moveReach(
      state.sides[state.activeSide],
      state.rules,
      state.turn,
      dx,
      state.rules.turnTimeFor(state.turn) - at,
    );
  }

  /// 상대가 쏘기 전 조준 자세를 보여주는 시간: AI 는 난이도별 생각 연출 시간
  /// (BALANCE.md A5.2), 그 밖에는 1.2초.
  int get aimShowMs {
    final ai = opponent;
    return ai is AiController ? AiDials.of(ai.level).thinkMs : 1200;
  }

  /// 남은 턴 시간(밀리초). 탄 비행 연출 중에는 줄지 않는다.
  int get remainingMs {
    final shot = playback;
    final flightLeft = shot is ShotPlayback
        ? shot.durationMs - shot.elapsedMs
        : 0;
    // 탭을 기다리는 분열탄은 아직 계산 전이라 비행 시간이 멈춤에 들어가 있지 않다.
    final pending = shot is ShotPlayback && shot.awaitingTap
        ? shot.flightMs
        : 0;
    final paused = state.pausedMs + pending - flightLeft;
    final used = turnMs - paused;
    final left = state.rules.turnTimeFor(state.turn) - used;
    return left < 0 ? 0 : left;
  }
}
