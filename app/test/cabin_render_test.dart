import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pb_ai/pb_ai.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/battle/battle_session.dart';
import 'package:pirate_busters/game/battle_game.dart';
import 'package:pirate_busters/game/coords.dart';
import 'package:pirate_busters/game/sprites.dart';
import 'package:pirate_busters/game/view/cabin_painter.dart';
import 'package:pirate_busters/game/view/ship_view.dart';

import 'test_catalog.dart';

void main() {
  group('선실 해적 (설계서 §10.1·§10.2, ADR-057)', () {
    test('해적 캔버스는 선실 칸 안쪽 방보다 작다', () {
      const cell = Rect.fromLTWH(0, 0, Coords.cell, Coords.cell);
      final room = CabinPainter.inner(cell);
      expect(240 * Coords.pirateScale, lessThanOrEqualTo(room.width));
      expect(
        Coords.pirateHeight + Coords.cabinFloor,
        lessThanOrEqualTo(Coords.cell),
      );
      // 키 약 0.9칸.
      expect(Coords.pirateHeight / Coords.cell, closeTo(0.9, 0.05));
    });

    test('무늬 번호는 칸 위치로 정해지고 네 가지를 모두 쓴다 (§10.2)', () {
      final seen = {
        for (var y = 0; y < 8; y++)
          for (var x = 0; x < 12; x++) BattleSprites.variantOf(x, y),
      };
      expect(seen, {0, 1, 2, 3});
      expect(BattleSprites.variantOf(3, 2), (3 * 7 + 2 * 13 + 6 % 5) % 4);
    });

    testWidgets('대기 중인 해적은 자기 선실 칸 안에 그려지고, 선실 칸에는 안쪽 벽 타일이 있다', (
      tester,
    ) async {
      final session = BattleSession(
        testSetup.newMatch(7),
        humanSides: const {0},
        speciesOf: testCatalog.speciesOf,
        opponent: const AiController(level: AiLevel.easy),
      );
      rootBundle.clear();
      await tester.runAsync(() async {
        // GameWidget 없이 띄운다: flame_test 의 initializeGame 과 같은 순서.
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
        final ships = game.world.children.whereType<ShipView>().toList();
        expect(ships, hasLength(2));
        for (final ship in ships) {
          final side = session.state.sides[ship.side];
          expect(ship.rigs, hasLength(side.crew.size));
          for (var slot = 0; slot < ship.rigs.length; slot++) {
            expect(side.crew.pirates[slot].status, PirateStatus.aboard);
            final cabin = side.cabins[slot];
            final cell = ship.cellRect(cabin.x, cabin.y);
            final body = ship.rigs[slot].toRect();
            expect(
              body.left >= cell.left &&
                  body.right <= cell.right &&
                  body.top >= cell.top &&
                  body.bottom <= cell.bottom,
              isTrue,
              reason: '진영 ${ship.side} 슬롯 $slot: $body 가 $cell 밖',
            );
          }
          // 재질 타일(망사 포함)과 선실 안쪽 벽 타일을 읽어 둔다 (§10.2).
          for (final m in BlockMaterial.values) {
            expect(ship.sprites.tile(m, 1, 2).image.width, 64, reason: m.name);
          }
          expect(
            ship.sprites.tile(BlockMaterial.oak, 3, 0, keel: true).image,
            isNot(ship.sprites.tile(BlockMaterial.oak, 3, 0).image),
          );
          expect(ship.sprites.roomWall(1, 2).image.width, 64);
        }
      });
      expect(tester.takeException(), isNull);
    });
  });
}
