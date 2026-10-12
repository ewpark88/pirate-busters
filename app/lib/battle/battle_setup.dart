import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/campaign/stage_spec.dart';
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

  /// 실제로 출전하는 덱: 저장된 [deck] 을 배 [hull] 의 선실 수만큼 앞에서 자르고,
  /// 코스트 한도 [limit] 를 넘으면 뒤에서 뺀다. 그래도 맞지 않으면 시작 덱. 전투 준비
  /// 화면과 전투가 같은 덱을 쓰게 한다 (A41 점검: 큰 배에서 작은 배로 바꾼 경우).
  List<String> sailDeck(List<String>? deck, HullSpec hull, int limit) {
    final out = [
      for (final id in deck ?? starterDeck)
        if (catalog.pirates.has(id)) id,
    ].take(hull.cabinSlots).toList();
    int cost() => out.fold(0, (a, id) => a + catalog.pirates.byId(id).cost);
    while (out.length > 1 && cost() > limit) {
      out.removeLast();
    }
    final ok = deckProblem(hull, catalog.pirates, out, limit) == null;
    return ok ? out : starterDeck;
  }

  /// AI 상대의 덱 후보: 일반 4명. 플레이어 덱과 같은 인원만큼 앞에서부터 태운다.
  /// 캠페인 적 덱은 M7 (§6.1).
  static const List<String> aiDeck = [
    'p06_pang',
    'p16_suri',
    'p26_polly',
    'p11_finn',
  ];

  /// 플레이어 레벨 1 출전 코스트 한도 (설계서 §4.5). 레벨은 R4 메타에서 붙는다.
  static final int costLimit = costLimitForLevel(1);

  /// 추천 설계도 중 기본으로 쓰는 것.
  static const String defaultPreset = 'balanced';

  Blueprint get defaultBlueprint => catalog.preset(defaultPreset).blueprint;

  /// 스테이지의 적 설계도: 전용 설계도가 있으면 그것, 없으면 추천 설계도.
  Blueprint enemyBlueprintOf(StageSpec stage) =>
      stage.enemyBlueprint ??
      catalog.preset(stage.enemyPreset, stage: stage.enemyStage).blueprint;

  /// 적 설계도의 돛대에 [mastLevel] 을 찍는다.
  static Blueprint enemyShip(Blueprint b, int mastLevel) => mastLevel == 1
      ? b
      : Blueprint(
          b.hull,
          b.cells,
          cabins: b.cabins,
          modules: [
            for (final m in b.modules)
              ModuleCell(
                m.x,
                m.y,
                m.kind,
                level: m.kind.isMast ? mastLevel : 1,
              ),
          ],
        );

  /// 새 판. [seed] 로 선공·바람이 정해진다. 왼쪽(0)이 플레이어.
  Match newMatch(
    int seed, {
    Blueprint? blueprint,
    List<String> deck = starterDeck,
    Blueprint? enemyBlueprint,
    List<String>? enemyDeck,
    MatchRules rules = const MatchRules(),
    int? costLimit,
    int? enemyCostLimit,
  }) => Match.start(
    seed: seed,
    rules: rules,
    blueprints: [
      blueprint ?? defaultBlueprint,
      enemyBlueprint ?? defaultBlueprint,
    ],
    decks: [deck, enemyDeck ?? aiDeck.take(deck.length).toList()],
    costLimits: [
      costLimit ?? BattleSetup.costLimit,
      enemyCostLimit ?? BattleSetup.costLimit,
    ],
    pirates: catalog.pirates,
  );

  /// 캠페인 스테이지 판 (설계서 §6.1): 적 설계도·덱·파도·바람은 스테이지 데이터에서.
  Match newStageMatch(
    int seed,
    StageSpec stage, {
    Blueprint? blueprint,
    List<String>? deck,
    int? costLimit,
  }) => prepareStage(
    seed,
    stage,
    blueprint: blueprint,
    deck: deck,
    costLimit: costLimit,
  ).match;

  /// [newStageMatch] 와 같되 리플레이(§7.2)를 만들 입력을 같이 돌려준다. [tune] 으로
  /// 규칙을 덮어쓸 수 있다(원격 설정).
  PreparedMatch prepareStage(
    int seed,
    StageSpec stage, {
    Blueprint? blueprint,
    List<String>? deck,
    int? costLimit,
    MatchRules Function(MatchRules rules)? tune,
  }) {
    final mine = blueprint ?? defaultBlueprint;
    final limit = costLimit ?? BattleSetup.costLimit;
    final chosen = sailDeck(deck, mine.hull, limit);
    // 보스 기믹은 상대(진영 1)에 건다 (설계서 §5.4, BALANCE.md A5.4). 튜토리얼 3 은
    // 수리를 보여 주려고 내 배(진영 0)가 구멍 난 채 시작한다 (§15.2, ADR-092).
    final wounded = stage.tutorialStep == 3;
    final base = MatchRules(
      waveLevel: stage.waveLevel,
      maxWind: stage.maxWind,
      gimmick: wounded
          ? BossGimmick.woundedStart.index
          : BossGimmick.byId(stage.gimmick).index,
      gimmickSide: wounded ? 0 : 1,
    );
    // 적 배: 스테이지의 확장 단계·돛대 레벨 (설계서 §3.1·§3.3, BALANCE.md A3.1·A3.2).
    final enemy = enemyBlueprintOf(stage);
    final blueprints = [mine, enemyShip(enemy, stage.enemyMastLevel)];
    final decks = [chosen, stage.enemyDeck];
    final limits = [limit, BattleSetup.costLimit];
    final match = Match.start(
      seed: seed,
      rules: tune == null ? base : tune(base),
      blueprints: blueprints,
      decks: decks,
      costLimits: limits,
      pirates: catalog.pirates,
    );
    return PreparedMatch(
      match,
      blueprints: blueprints,
      decks: decks,
      costLimits: limits,
    );
  }

  /// 저장한 설계도·덱으로 새 판. 없거나 규칙에 맞지 않으면(코스트 초과 등) 기본값.
  Match newMatchFor(int seed, {Blueprint? blueprint, List<String>? deck}) {
    final hull = (blueprint ?? defaultBlueprint).hull;
    return newMatch(
      seed,
      blueprint: blueprint,
      deck: sailDeck(deck, hull, costLimit),
    );
  }
}

/// 판과 그 판을 만든 입력. 리플레이 = 시드 + 설계도 + 덱 + 매치 파라미터 + 턴 묶음 (§7.2).
class PreparedMatch {
  const PreparedMatch(
    this.match, {
    required this.blueprints,
    required this.decks,
    required this.costLimits,
  });

  final Match match;
  final List<Blueprint> blueprints;
  final List<List<String>> decks;
  final List<int> costLimits;

  Replay replay() => Replay.fromMatch(
    blueprints: blueprints,
    decks: decks,
    costLimits: costLimits,
    match: match,
  );
}
