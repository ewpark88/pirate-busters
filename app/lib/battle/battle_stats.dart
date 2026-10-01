import 'package:pb_sim/pb_sim.dart';

/// 전투 통계 (설계서 §13.5): 렌더용 이벤트를 세기만 한다. 판정에는 영향이 없다.
class BattleStats {
  final List<int> shots = [0, 0];
  final List<int> hits = [0, 0];
  final List<int> pirateDamage = [0, 0];
  final List<int> blocksDestroyed = [0, 0];

  /// [e] 를 센다. 맞은 배의 상대를 공격자로 본다.
  void record(SimEvent e) {
    if (e.side < 0 || e.side > 1) return;
    final attacker = 1 - e.side;
    if (e.kind == SimEventKind.fire) {
      shots[e.side]++;
    } else if (e.kind == SimEventKind.impact) {
      hits[attacker]++;
    } else if (e.kind == SimEventKind.pirateHit) {
      pirateDamage[attacker] += e.value;
    } else if (e.kind == SimEventKind.blockDestroyed) {
      blocksDestroyed[attacker]++;
    }
  }

  /// 명중률(%): 발사 중 배에 맞은 비율. 한 발이 여러 칸에 맞아도 1로 센다.
  int hitPercent(int side) =>
      shots[side] == 0 ? 0 : (hits[side] * 100 ~/ shots[side]).clamp(0, 100);
}
