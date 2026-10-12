import 'package:flutter_test/flutter_test.dart';
import 'package:pb_ai/pb_ai.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/battle/battle_setup.dart';
import 'package:pirate_busters/campaign/star_rules.dart';

import 'test_catalog.dart';

void main() {
  final setup = BattleSetup(testCatalog);

  group('A59 튜토리얼 3 펌프 몫 (설계서 §13.1, ADR-105)', () {
    test('튜토리얼 3 은 내 배(진영 0)에 시작 구멍 기믹이 걸려 펌프 몫이 빠진다', () {
      final rules = setup
          .newStageMatch(7, testCampaign.stage('t-3'))
          .state
          .rules;
      expect(gimmickOf(rules, 0), BossGimmick.woundedStart);
      expect(gimmickOf(rules, 1), BossGimmick.none);
    });
  });

  group('A59 별 턴은 내 턴 수 (설계서 §6.1, BALANCE.md A6.1)', () {
    test('끝난 판에서 진영마다 실제로 둔 턴 수와 같다(끝난 뒤 넘어간 턴은 빼고)', () {
      for (final seed in [1, 2, 3, 4, 5]) {
        final m = setup.newStageMatch(seed, testCampaign.stage('1-1'));
        final ais = [
          const AiController(level: AiLevel.normal),
          const AiController(level: AiLevel.easy),
        ];
        while (!m.isOver) {
          m.playTurn(ais[m.state.activeSide].turnFor(m.state));
        }
        for (final side in [0, 1]) {
          final played = m.turnLog.where((b) => b.side == side).length;
          expect(
            MatchSummary.ownTurnsOf(m.state, side),
            played,
            reason: 'seed $seed side $side',
          );
        }
        expect(MatchSummary.lastTurnOf(m.state), m.turnLog.length);
      }
    });
  });

  group('A59 1-5 방패 배치 (설계서 §5.4, A43 점검 제안 5)', () {
    test('1-5 적 배 선실 위는 그물 지붕이라 공중탄이 선실로 바로 들어가지 않는다', () {
      final b = setup.enemyBlueprintOf(testCampaign.stage('1-5'));
      for (final c in b.cabins) {
        final roof = b.cells.where(
          (cell) => cell.x == c.x && cell.y == c.y + 1,
        );
        expect(roof, isNotEmpty, reason: '선실 (${c.x}, ${c.y})');
        expect(roof.first.material, BlockMaterial.net);
      }
    });
  });
}
