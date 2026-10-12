import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/battle/battle_session.dart';
import 'package:pirate_busters/battle/playback.dart';

/// 연출 묶음을 낸 해적 (설계서 §10.4). 블록을 안 부순 탄은 마지막 착탄과 같은
/// 프레임에 연출이 끝나 `playback` 이 비므로, 직전 프레임의 탄을 기억해 쓴다
/// (A41 점검: 보급탄 이름표·탄종 이름표가 빠지던 문제). 판정과 무관하다.
class ShooterTracker {
  ShotPlayback? _seen;

  /// 프레임마다 한 번 부른다. 턴 효과로 터진 묶음이면 null.
  PirateSpec? take(BattleSession session) {
    final now = session.playback;
    final p = now is ShotPlayback ? now : _seen;
    _seen = now is ShotPlayback ? now : null;
    if (p == null) return null;
    return session.state.sides[p.side].crew.pirates[p.slot].spec;
  }
}
