import 'package:pb_ai/pb_ai.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/battle/battle_setup.dart';

/// 개발용 테스트 대전 설정 (ADR-053): 코스트 한도 없이 고른 덱끼리 AI 와 붙는다.
class TestBattle {
  const TestBattle({
    required this.deck,
    required this.enemyDeck,
    this.level = AiLevel.normal,
  });

  /// 내 덱(선실 순서).
  final List<String> deck;

  /// 상대 덱. 비었으면 시드로 무작위 4명.
  final List<String> enemyDeck;

  final AiLevel level;

  /// 테스트 대전의 코스트 한도. 등급과 상관없이 아무 조합이나 넣는다.
  static const int costLimit = 99;

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
