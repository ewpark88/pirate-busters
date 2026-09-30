import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/data/game_catalog.dart';

/// 전투 판 구성 (개발 계획서 M5). 해적과 추천 설계도는 게임 데이터에서 온다.
///
/// 플레이어는 처음에 시작 해적 2명(옥토·톡)으로 출전한다 (설계서 §4.6). 선원 편성
/// 화면에서 고른 덱과 저장한 설계도가 있으면 그것을 쓴다.
class BattleSetup {
  const BattleSetup(this.catalog);

  final GameCatalog catalog;

  /// 시작 해적 (설계서 §4.2, §4.6).
  static const List<String> starterDeck = ['p01_octo', 'p36_tok'];

  /// 허수아비의 덱: 일반 2명 (개발 계획서 M4 허수아비, ADR-029).
  static const List<String> dummyDeck = ['p06_pang', 'p16_suri'];

  /// 플레이어 레벨 1 출전 코스트 한도 (설계서 §4.5, BALANCE.md A4.5).
  static const int costLimit = 15;

  /// 추천 설계도 중 기본으로 쓰는 것.
  static const String defaultPreset = 'balanced';

  Blueprint get defaultBlueprint => catalog.preset(defaultPreset).blueprint;

  /// 새 판. [seed] 로 선공·바람이 정해진다. 왼쪽(0)이 플레이어.
  Match newMatch(
    int seed, {
    Blueprint? blueprint,
    List<String> deck = starterDeck,
    Blueprint? enemyBlueprint,
    List<String> enemyDeck = dummyDeck,
    MatchRules rules = const MatchRules(),
  }) => Match.start(
    seed: seed,
    rules: rules,
    blueprints: [
      blueprint ?? defaultBlueprint,
      enemyBlueprint ?? defaultBlueprint,
    ],
    decks: [deck, enemyDeck],
    costLimits: const [costLimit, costLimit],
    pirates: catalog.pirates,
  );
}
