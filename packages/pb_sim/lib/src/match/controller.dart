import 'package:pb_sim/src/command/command.dart';
import 'package:pb_sim/src/match/match.dart';
import 'package:pb_sim/src/match/match_state.dart';

/// 한 진영의 입력원 (설계서 §5, §7). 사람·AI·네트워크 모두 이 인터페이스로 꽂힌다.
// 어댑터 포트라 한 메서드여도 인터페이스로 둔다 (설계서 §7 컨트롤러 3종).
// ignore: one_member_abstracts
abstract interface class Controller {
  /// [tick] 에 실행할 커맨드. [state] 는 읽기만 한다.
  List<Command> commandsAt(int tick, MatchState state);
}

/// 미리 정한 커맨드를 정해진 틱에 내는 컨트롤러. 테스트와 리플레이 재생용.
class ScriptedController implements Controller {
  ScriptedController(Iterable<Command> commands) {
    for (final c in commands) {
      (_byTick[c.tick] ??= []).add(c);
    }
  }

  // 틱 번호로 조회만 하고 순회하지 않는다 (결정론 규칙 §2.2).
  final Map<int, List<Command>> _byTick = {};

  @override
  List<Command> commandsAt(int tick, MatchState state) =>
      _byTick[tick] ?? const [];
}

/// [ticks] 틱(또는 판이 끝날 때까지) 두 컨트롤러로 [match] 를 진행한다.
///
/// 각 컨트롤러는 자기 진영 커맨드만 낼 수 있다. 다른 진영 커맨드는 버린다.
void runMatch(
  Match match,
  Controller left,
  Controller right, {
  required int ticks,
}) {
  for (var i = 0; i < ticks && !match.isOver; i++) {
    final tick = match.state.tick;
    match.step([
      for (final c in left.commandsAt(tick, match.state))
        if (c.side == 0) c,
      for (final c in right.commandsAt(tick, match.state))
        if (c.side == 1) c,
    ]);
  }
}
