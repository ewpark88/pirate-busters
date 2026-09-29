import 'package:pb_sim/src/hash/state_hasher.dart';
import 'package:pb_sim/src/match/controller.dart';
import 'package:pb_sim/src/match/match.dart';
import 'package:pb_sim/src/match/match_state.dart';
import 'package:pb_sim/src/match/rules.dart';
import 'package:pb_sim/src/pirate/pirate_spec.dart';
import 'package:pb_sim/src/replay/replay.dart';
import 'package:pb_sim/src/ship/blueprint.dart';

/// 헤드리스 한 판의 결과 (개발 계획서 M3). `sim_runner`·골든 테스트가 쓴다.
class MatchResult {
  const MatchResult({
    required this.outcome,
    required this.winner,
    required this.turns,
    required this.hash,
    required this.replay,
  });

  /// 끝난 방식. 컨트롤러가 멈추지 않는 한 [MatchOutcome.ongoing] 이 아니다.
  final MatchOutcome outcome;

  /// 이긴 진영. 무승부면 −1.
  final int winner;

  /// 진행한 턴 수.
  final int turns;

  /// 최종 상태 해시.
  final int hash;

  /// 같은 판을 다시 돌릴 수 있는 리플레이.
  final Replay replay;
}

/// 설계도 2개·덱 2개·컨트롤러 2개로 한 판을 끝까지 돌린다 (개발 계획서 M3).
MatchResult runHeadless({
  required int seed,
  required List<Blueprint> blueprints,
  required List<List<String>> decks,
  required List<int> costLimits,
  required PirateCatalog pirates,
  required Controller left,
  required Controller right,
  MatchRules rules = const MatchRules(),
}) {
  final match = Match.start(
    seed: seed,
    rules: rules,
    blueprints: blueprints,
    decks: decks,
    costLimits: costLimits,
    pirates: pirates,
  );
  runMatch(match, left, right);
  final state = match.state;
  return MatchResult(
    outcome: state.outcome,
    winner: state.winner,
    turns: match.turnLog.length,
    hash: hashMatchState(state),
    replay: Replay.fromMatch(
      blueprints: blueprints,
      decks: decks,
      costLimits: costLimits,
      match: match,
    ),
  );
}
