import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/campaign/stage_spec.dart';

/// 한 판이 끝난 뒤 별 판정에 쓰는 요약 (설계서 §6.1, §13.5 전투 통계).
class MatchSummary {
  const MatchSummary({
    required this.won,
    required this.outcome,
    required this.turns,
    required this.floodPercent,
    required this.hullPercent,
    required this.piratesDown,
    required this.shotsFired,
    this.draw = false,
    this.hits = 0,
    this.damageDealt = 0,
    this.blocksDestroyed = 0,
    this.mvpPirate,
  });

  /// 끝난 판의 상태에서 [side] 기준으로 만든다.
  factory MatchSummary.fromState(
    MatchState state,
    int side, {
    int hits = 0,
    int damageDealt = 0,
    int blocksDestroyed = 0,
    int mvpSlot = -1,
  }) {
    final me = state.sides[side];
    final crew = me.crew.pirates;
    return MatchSummary(
      won: state.winner == side,
      // 무승부는 pb_sim 이 정한다(승자 −1). 앱이 침수 % 로 다시 재지 않는다 (§2.4).
      draw: state.outcome != MatchOutcome.ongoing && state.winner < 0,
      outcome: state.outcome,
      turns: state.turn,
      floodPercent: me.flood * 100 ~/ fullFlood,
      hullPercent: me.grid.initialTotalHp == 0
          ? 0
          : me.grid.totalHp * 100 ~/ me.grid.initialTotalHp,
      piratesDown: me.crew.pirates
          .where((p) => p.status == PirateStatus.down)
          .length,
      shotsFired: me.shotsFired,
      hits: hits,
      damageDealt: damageDealt,
      blocksDestroyed: blocksDestroyed,
      mvpPirate: mvpSlot >= 0 && mvpSlot < crew.length
          ? crew[mvpSlot].spec.id
          : null,
    );
  }

  final bool won;

  /// 무승부 (pb_sim `winner` 가 −1, 설계서 §2.4).
  final bool draw;
  final MatchOutcome outcome;

  /// 판이 끝난 턴 번호 (양쪽 합산, 설계서 §2.4).
  final int turns;
  final int floodPercent;
  final int hullPercent;
  final int piratesDown;
  final int shotsFired;

  /// 배에 맞은 발 수, 해적에게 준 피해, 부순 블록 수 (렌더 이벤트 집계).
  final int hits;
  final int damageDealt;
  final int blocksDestroyed;

  /// 가장 많이 기여한 내 해적 id (결과 화면 MVP, 설계서 §13.5). 없으면 null.
  final String? mvpPirate;

  int get hitPercent =>
      shotsFired == 0 ? 0 : (hits * 100 ~/ shotsFired).clamp(0, 100);
}

/// 별 3개 결과 (설계서 §6.1: 승리 / 정해진 턴 이내 / 스테이지 미션).
class StarResult {
  const StarResult({
    required this.won,
    required this.inTurns,
    required this.mission,
  });

  final bool won;
  final bool inTurns;
  final bool mission;

  /// 별 수 0~3. 승리하지 않으면 0.
  int get count => !won ? 0 : 1 + (inTurns ? 1 : 0) + (mission ? 1 : 0);
}

/// 별 판정 (설계서 §6.1). 미션은 `MissionSpec.knownTypes`.
class StarRules {
  const StarRules();

  StarResult evaluate(StageSpec stage, MatchSummary s) => StarResult(
    won: s.won,
    inTurns: s.won && s.turns <= stage.starTurns,
    mission: s.won && missionDone(stage.mission, s),
  );

  bool missionDone(MissionSpec m, MatchSummary s) => switch (m.type) {
    'no_pirate_down' => s.piratesDown == 0,
    'flood_below' => s.floodPercent <= m.param('percent'),
    'hull_above' => s.hullPercent >= m.param('percent'),
    'win_by_sink' =>
      s.outcome == MatchOutcome.sunk || s.outcome == MatchOutcome.floodSunk,
    'turns_within' => s.turns <= m.param('turns'),
    _ => false,
  };
}
