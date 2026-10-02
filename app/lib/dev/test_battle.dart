import 'package:pb_ai/pb_ai.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/battle/battle_setup.dart';

/// 개발용 테스트 대전 설정 (ADR-053): 코스트 한도 없이 고른 덱끼리 AI 와 붙는다.
/// [dummy] 면 반격하지 않는 더미배를 상대로 폭탄투하를 연습한다 (ADR-073).
class TestBattle {
  const TestBattle({
    required this.deck,
    required this.enemyDeck,
    this.level = AiLevel.normal,
    this.dummy = false,
  });

  /// 더미배 연습: 상대는 매 턴 아무것도 하지 않고 턴을 넘긴다(빈 턴 묶음).
  /// 규칙은 그대로라 침몰·턴 한도로 판이 끝나면 같은 덱으로 다시 시작한다.
  final bool dummy;

  /// 내 덱(선실 순서).
  final List<String> deck;

  /// 상대 덱. 비었으면 시드로 무작위 4명.
  final List<String> enemyDeck;

  final AiLevel level;

  /// 테스트 대전의 코스트 한도. 등급과 상관없이 아무 조합이나 넣는다.
  static const int costLimit = 99;

  /// [id] 를 맨 앞 선실에 넣은 연습 설정. 이미 덱에 있으면 앞으로 옮기고,
  /// 선실이 넘치면 끝 해적을 뺀다. 판 도중 교체 규칙이 없어 새 판으로 시작한다.
  TestBattle withLead(String id) => TestBattle(
    deck: [
      id,
      ...deck.where((d) => d != id),
    ].take(HullSpec.sloop.cabinSlots).toList(),
    enemyDeck: enemyDeck,
    level: level,
    dummy: dummy,
  );

  /// 상대 컨트롤러. 더미배면 빈 턴만 내고(절대 규칙 4: 커맨드로만 둔다),
  /// 아니면 null 을 돌려 화면이 AI 를 만든다.
  Controller? get dummyController =>
      dummy ? ScriptedController(const []) : null;

  /// 판 하나. 상대 설계도는 기본 추천 설계도.
  Match start(BattleSetup setup, int seed, {Blueprint? blueprint}) =>
      setup.newMatch(
        seed,
        blueprint: blueprint,
        deck: deck,
        enemyDeck: enemyDeck.isEmpty
            ? randomDeck(setup.catalog.data.pirates.map((p) => p.id), seed)
            : enemyDeck,
        costLimit: costLimit,
        enemyCostLimit: costLimit,
      );

  /// [ids] 에서 [seed] 로 서로 다른 4명을 고른다.
  static List<String> randomDeck(Iterable<String> ids, int seed) {
    final pool = ids.toList();
    final rng = XorShift32(seed);
    final out = <String>[];
    while (out.length < HullSpec.sloop.cabinSlots && pool.isNotEmpty) {
      out.add(pool.removeAt(rng.nextInt(pool.length)));
    }
    return out;
  }
}
