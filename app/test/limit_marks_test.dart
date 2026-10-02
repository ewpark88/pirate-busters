import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pb_ai/pb_ai.dart';
import 'package:pirate_busters/battle/battle_session.dart';
import 'package:pirate_busters/game/battle_game.dart';
import 'package:pirate_busters/game/view/limit_marks.dart';
import 'package:pirate_busters/game/view/ship_view.dart';
import 'package:pirate_busters/game/view/shot_view.dart';

import 'test_catalog.dart';

void main() {
  testWidgets('이동 한계 표식은 배보다 뒤, 탄은 배보다 앞에 그린다 (설계서 §2.6, ADR-071)', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final session = BattleSession(
        testSetup.newMatch(1),
        humanSides: const {0},
        speciesOf: testCatalog.speciesOf,
        opponent: const AiController(level: AiLevel.easy),
      );
      final game = BattleGame(session)..onGameResize(Vector2(960, 440));
      // Flame 테스트 도우미와 같은 내부 수명 주기 호출이다.
      // ignore: invalid_use_of_internal_member
      await game.load();
      // Flame 테스트 도우미와 같은 내부 수명 주기 호출이다.
      // ignore: invalid_use_of_internal_member
      game.mount();
      // ignore: cascade_invocations, mount 은 위의 ignore 가 필요해 캐스케이드로 못 묶는다.
      game.update(0);
      await game.ready();
      final world = game.world.children;
      final marks = world.whereType<LimitMarks>().single;
      final ship = world.whereType<ShipView>().first;
      final shot = world.whereType<ShotView>().single;
      expect(marks.priority, lessThan(ship.priority));
      expect(shot.priority, greaterThan(ship.priority));
      session.dispose();
    });
  });
}
