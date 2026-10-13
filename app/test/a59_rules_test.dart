import 'package:flutter_test/flutter_test.dart';
import 'package:pb_ai/pb_ai.dart';
import 'package:pirate_busters/battle/battle_setup.dart';
import 'package:pirate_busters/campaign/star_rules.dart';

import 'test_catalog.dart';

void main() {
  final setup = BattleSetup(testCatalog);

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
}
