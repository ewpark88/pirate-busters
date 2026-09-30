import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/battle/battle_session.dart';
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
}
