import 'package:flutter_test/flutter_test.dart';
import 'package:pb_ai/pb_ai.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/battle/battle_setup.dart';

import 'test_catalog.dart';

/// MVP 종료 게이트 ‘크래시 없이 해역 1을 끝까지 클리어할 수 있음’ (개발 계획서 4장,
/// 설계서 §6.1, §11.1). 실제 데이터로 해역 1 스테이지를 차례로 돈다. 내 쪽은 시작
/// 덱에 확정 보상 해적을 차례로 더하고(§4.6), 손에 익은 사람 대신 어려움 AI 가 둔다.
/// 상대는 스테이지의 난이도·성격이다. 판마다 끝까지 돌고, 몇 시드 안에 이겨야 한다.
void main() {
  test(
    '해역 1 의 모든 스테이지를 오류 없이 끝까지 두고, 몇 판 안에 이길 수 있다',
    () {
      final sea = testCampaign.sea(1);
      final owned = [...BattleSetup.starterDeck];
      var cleared = 0;
      for (final (i, stage) in sea.stages.indexed) {
        // 플레이어 레벨은 판마다 대략 하나씩 오른다고 본다(코스트 한도, §4.5).
        final limit = costLimitForLevel(1 + i);
        final deck = <String>[];
        var cost = 0;
        for (final id in owned.reversed) {
          final c = testCatalog.pirates.byId(id).cost;
          if (deck.length < 4 && cost + c <= limit) {
            deck.add(id);
            cost += c;
          }
        }
        var won = false;
        for (var seed = 1; seed <= 6 && !won; seed++) {
          final match = testSetup.newStageMatch(
            seed,
            stage,
            deck: deck,
            costLimit: limit,
          );
          runMatch(
            match,
            const AiController(level: AiLevel.hard),
            AiController(level: stage.aiLevel, personality: stage.personality),
          );
          expect(match.isOver, isTrue, reason: '${stage.id} seed $seed');
          won = match.state.winner == 0;
        }
        expect(won, isTrue, reason: '${stage.id} 를 6판 안에 이기지 못했다');
        cleared++;
        final reward = stage.rewardPirate;
        if (reward != null && !owned.contains(reward)) owned.add(reward);
      }
      expect(cleared, sea.stages.length);
    },
    timeout: const Timeout(Duration(minutes: 10)),
  );
}
