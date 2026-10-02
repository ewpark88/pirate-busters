import 'package:pb_sim/pb_sim.dart';

/// 전투 통계 (설계서 §13.5): 렌더용 이벤트를 세기만 한다. 판정에는 영향이 없다.
class BattleStats {
  final List<int> shots = [0, 0];
  final List<int> hits = [0, 0];
  final List<int> pirateDamage = [0, 0];
  final List<int> blocksDestroyed = [0, 0];

  /// 마지막으로 끝난 턴에 움직인 거리(1/1000칸, 절댓값 합). 분석 이벤트
  /// `turn_end` 가 쓴다 (개발 계획서 M7).
  final List<int> lastTurnMoved = [0, 0];
  final List<int> _movedThisTurn = [0, 0];

  /// 진영마다 마지막으로 쏜 해적 슬롯. 맞힌 결과를 그 해적에게 돌린다.
  final List<int> _shooter = [-1, -1];

  /// 진영마다 해적 슬롯별 기여 점수: 해적에게 준 피해 + 부순 블록 × [blockPoints].
  final List<Map<int, int>> _score = [{}, {}];

  /// 블록 하나를 부순 기여 점수 (결과 화면 MVP, 설계서 §13.5. 판정과 무관).
  static const int blockPoints = 10;

  /// [side] 의 MVP 해적 슬롯. 기여가 같으면 앞 슬롯, 아무도 맞히지 못했으면 −1.
  int mvpSlot(int side) {
    var best = -1;
    var bestScore = 0;
    final scores = _score[side].entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    for (final e in scores) {
      if (e.value > bestScore) {
        best = e.key;
        bestScore = e.value;
      }
    }
    return best;
  }

  void _credit(int attacker, int points) {
    final slot = _shooter[attacker];
    if (slot < 0) return;
    _score[attacker][slot] = (_score[attacker][slot] ?? 0) + points;
  }

  /// [e] 를 센다. 맞은 배의 상대를 공격자로 본다.
  void record(SimEvent e) {
    if (e.side < 0 || e.side > 1) return;
    final attacker = 1 - e.side;
    if (e.kind == SimEventKind.fire) {
      shots[e.side]++;
      _shooter[e.side] = e.slot;
    } else if (e.kind == SimEventKind.impact) {
      hits[attacker]++;
    } else if (e.kind == SimEventKind.pirateHit) {
      pirateDamage[attacker] += e.value;
      _credit(attacker, e.value);
    } else if (e.kind == SimEventKind.blockDestroyed) {
      blocksDestroyed[attacker]++;
      _credit(attacker, blockPoints);
    } else if (e.kind == SimEventKind.move) {
      _movedThisTurn[e.side] += e.value.abs();
    } else if (e.kind == SimEventKind.turnEnd) {
      lastTurnMoved[e.side] = _movedThisTurn[e.side];
      _movedThisTurn[e.side] = 0;
    }
  }

  /// 명중률(%): 발사 중 배에 맞은 비율. 한 발이 여러 칸에 맞아도 1로 센다.
  int hitPercent(int side) =>
      shots[side] == 0 ? 0 : (hits[side] * 100 ~/ shots[side]).clamp(0, 100);
}
