import 'dart:io';

import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pb_ai/pb_ai.dart';
import 'package:pirate_busters/battle/battle_session.dart';
import 'package:pirate_busters/game/anim/anim_data.dart';
import 'package:pirate_busters/game/anim/rig_expressions.dart';
import 'package:pirate_busters/game/battle_game.dart';
import 'package:pirate_busters/game/view/ship_view.dart';

import 'test_catalog.dart';

void main() {
  group('표정과 상태 동작 (설계서 §10.1)', () {
    test('anims.json 에 상태 동작 5개가 있고 저마다 표정이 정해져 있다', () {
      final anims = PbAnims.fromJsonString(
        File('assets/data/anims.json').readAsStringSync(),
      );
      expect(
        anims.states.keys,
        containsAll(['aim', 'fall', 'swim', 'win', 'lose']),
      );
      expect(anims.states['aim']!.expr, 'aim');
      expect(anims.states['fall']!.expr, 'hit');
      expect(anims.states['win']!.expr, 'win');
      expect(anims.states['lose']!.expr, 'lose');
      for (final clip in anims.states.values) {
        expect(clip.duration, greaterThan(0));
        expect(RigExpressions.names, contains(clip.expr));
      }
    });

    testWidgets('피격·조준·승리·패배 때 표정이 바뀌고 끝나면 기본으로 돌아온다', (tester) async {
      final session = BattleSession(
        testSetup.newMatch(7),
        humanSides: const {0},
        speciesOf: testCatalog.speciesOf,
        opponent: const AiController(level: AiLevel.easy),
      );
      rootBundle.clear();
      await tester.runAsync(() async {
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
        final ship = game.world.children.whereType<ShipView>().first;
        final rig = ship.rigs.first;
        final head = rig.children.whereType<SpriteComponent>().firstWhere(
          (c) => c.priority == 6,
        );
        final normalHead = head.sprite!.image;
        expect(rig.expression, RigExpressions.normal);

        // 피격: 맞는 동작 동안 피격 표정, 끝나면 기본.
        ship.playHit(0);
        rig.update(0.05);
        expect(rig.expression, 'hit');
        expect(head.sprite!.image, isNot(normalHead), reason: '머리 부위가 바뀐다');
        rig
          ..update(5)
          ..update(0.05);
        expect(rig.expression, RigExpressions.normal);
        expect(head.sprite!.image, normalHead);

        // 공격.
        ship.playAttack(0);
        rig.update(0.05);
        expect(rig.expression, 'attack');
        rig.update(5);

        // 조준, 승리, 패배, 낙하는 상태 동작이 표정을 정한다.
        for (final (state, expr) in const [
          ('aim', 'aim'),
          ('win', 'win'),
          ('lose', 'lose'),
          ('fall', 'hit'),
          ('swim', RigExpressions.normal),
        ]) {
          rig
            ..state = state
            ..update(0.05);
          expect(rig.expression, expr, reason: state);
        }
        rig
          ..state = null
          ..update(0.05);
        expect(rig.expression, RigExpressions.normal);
      });
      expect(tester.takeException(), isNull);
    });
  });
}
