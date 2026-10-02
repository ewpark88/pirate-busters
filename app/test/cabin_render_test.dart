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
      // 키 약 0.9칸, 발은 칸 위에서 29px (에셋 v0.24 tokens.json `roomSlotPx`).
      expect(Coords.pirateHeight / Coords.cell, closeTo(0.9, 0.05));
      expect(Coords.cell - Coords.cabinFloor, 29);
    });

    test('무늬 번호는 칸 위치로 정해지고 네 가지를 모두 쓴다 (§10.2)', () {
      final seen = {
        for (var y = 0; y < 8; y++)
          for (var x = 0; x < 12; x++) BattleSprites.variantOf(x, y),
      };
      expect(seen, {0, 1, 2, 3});
      expect(BattleSprites.variantOf(3, 2), (3 * 7 + 2 * 13 + 6 % 5) % 4);
    });

    test('칸 가운데가 잠긴 깊이 아래면 젖은 줄이고, 배가 내려앉으면 젖은 줄이 는다', () {
      // 맨 아랫줄(y=0) 가운데는 0.5칸.
      expect(BattleSprites.isWet(0, cellUnit ~/ 2 - 1), isFalse);
      expect(BattleSprites.isWet(0, cellUnit ~/ 2), isTrue);
      expect(BattleSprites.isWet(1, cellUnit), isFalse);
      int wetRows(int draft) => [
        for (var y = 0; y < 8; y++)
          if (BattleSprites.isWet(y, draft)) y,
      ].length;
      expect(wetRows(1600), 2);
      expect(wetRows(2600), 3);
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
            // 캔버스 위 끝(발에서 29.5px)은 그림 키(29px)보다 0.5px 높은 빈
            // 여백이라 1px 까지 칸 위로 나가도 된다 (에셋 v0.24, ADR-062).
            expect(
              body.left >= cell.left &&
                  body.right <= cell.right &&
                  body.top >= cell.top - 1 &&
                  body.bottom <= cell.bottom,
              isTrue,
              reason: '진영 ${ship.side} 슬롯 $slot: $body 가 $cell 밖',
            );
          }
          // 재질 타일(망사 포함)과 선실 안쪽 벽 타일을 읽어 둔다 (§10.2).
          for (final m in BlockMaterial.values) {
            expect(ship.sprites.tile(m, 1, 2).image.width, 64, reason: m.name);
          }
          // 흘수선 아래 참나무·소나무만 젖은 타일이다 (§10.2, ADR-061).
          for (final m in BlockMaterial.values) {
            final wet = ship.sprites.tile(m, 3, 0, wet: true).image;
            final dry = ship.sprites.tile(m, 3, 0).image;
            if (m == BlockMaterial.oak || m == BlockMaterial.pine) {
              expect(wet, isNot(dry), reason: m.name);
              expect(
                wet,
                ship.sprites.tile(BlockMaterial.oak, 3, 0, wet: true).image,
              );
            } else {
              expect(wet, dry, reason: m.name);
            }
          }
          // 등불 선실 타일은 1칸(@2x 64px)이고 네 가지를 모두 읽어 둔다.
          for (var v = 0; v < 4; v++) {
            final room = ship.sprites.get(BattleSprites.roomFile(v)).image;
            expect((room.width, room.height), (64, 64));
          }
          // 젖은 줄 판정은 시뮬레이션의 선실 잠김 판정과 같아야 한다(ADR-061).
          final flood = side.flood;
          for (var f = 0; f <= fullFlood; f += fullFlood ~/ 10) {
            side.flood = f;
            for (var slot = 0; slot < side.crew.size; slot++) {
              expect(
                BattleSprites.isWet(side.cabins[slot].y, side.draft),
                side.isCabinFlooded(slot),
                reason: '침수 $f 슬롯 $slot',
              );
            }
          }
          side.flood = flood;
        }
      });
      expect(tester.takeException(), isNull);
    });
  });
}
