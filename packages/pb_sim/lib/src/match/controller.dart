import 'package:pb_sim/src/command/command.dart';
import 'package:pb_sim/src/match/match.dart';
import 'package:pb_sim/src/match/match_state.dart';

/// 한 진영의 입력원 (설계서 §5, §7). 사람·AI·네트워크 모두 이 인터페이스로 꽂힌다.
// 어댑터 포트라 한 메서드여도 인터페이스로 둔다 (설계서 §7 컨트롤러 3종).
// ignore: one_member_abstracts
abstract interface class Controller {
  /// 지금 턴([MatchState.turn], [MatchState.activeSide])의 커맨드 묶음.
  /// [state] 는 읽기만 한다.
  TurnBundle turnFor(MatchState state);
}

/// 미리 정한 턴 묶음을 내는 컨트롤러. 테스트와 리플레이 재생용.
/// 묶음이 없는 턴은 빈 묶음(시간 초과)을 낸다.
class ScriptedController implements Controller {
  ScriptedController(Iterable<TurnBundle> bundles) {
    for (final b in bundles) {
      _byTurn[b.turn] = b;
    }
  }

  // 턴 번호로 조회만 하고 순회하지 않는다 (결정론 규칙 §2.2).
  final Map<int, TurnBundle> _byTurn = {};

  @override
  TurnBundle turnFor(MatchState state) =>
      _byTurn[state.turn] ??
      TurnBundle(turn: state.turn, side: state.activeSide, commands: const []);
}

/// 판이 끝날 때까지(또는 [maxTurns] 턴) 두 컨트롤러로 [match] 를 진행한다.
///
/// 각 컨트롤러는 자기 진영 턴만 둘 수 있다. 다른 진영·다른 턴 묶음은 빈 턴으로 친다.
void runMatch(
  Match match,
  Controller left,
  Controller right, {
  int? maxTurns,
}) {
  final state = match.state;
  for (var i = 0; !match.isOver && (maxTurns == null || i < maxTurns); i++) {
    final side = state.activeSide;
    final bundle = (side == 0 ? left : right).turnFor(state);
    final valid = bundle.side == side && bundle.turn == state.turn;
    match.playTurn(
      valid
          ? bundle
          : TurnBundle(turn: state.turn, side: side, commands: const []),
    );
  }
}
