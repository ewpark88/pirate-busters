import 'package:pb_ai/src/dials.dart';
import 'package:pb_ai/src/planner.dart';
import 'package:pb_sim/pb_sim.dart';

/// AI 컨트롤러 (설계서 §5): 사람과 같은 커맨드만 낸다. 전투 엔진은 상대가 누구인지
/// 모른다. 한 턴 전체를 [AiPlanner] 로 미리 평가한 뒤 턴 묶음을 돌려준다.
class AiController implements Controller {
  const AiController({
    required this.level,
    this.personality = Personality.bombard,
    this.losses = 0,
  });

  final AiLevel level;
  final Personality personality;

  /// 플레이어 연패 수 (연패 보정, BALANCE.md A5.2).
  final int losses;

  /// 앱처럼 프레임마다 나눠 계산할 때 쓰는 계획기.
  AiPlanner planner(MatchState state) => AiPlanner(
    state,
    level: level,
    personality: personality,
    losses: losses,
  );

  @override
  TurnBundle turnFor(MatchState state) => planner(state).plan();
}
