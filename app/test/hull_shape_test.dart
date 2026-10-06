import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/battle/battle_session.dart';
import 'package:pirate_busters/data/fleet_store.dart';
import 'package:pirate_busters/game/battle_game.dart';
import 'package:pirate_busters/game/coords.dart';
import 'package:pirate_busters/game/view/hull_trim.dart';
import 'package:pirate_busters/game/view/plank_join.dart';
import 'package:pirate_busters/game/view/ship_view.dart';

import 'test_catalog.dart';

/// 골든은 만든 환경(Windows)에서만 비교한다.
/// 다시 만들기: `flutter test test/hull_shape_test.dart --update-goldens`.
final bool _skipGolden = !Platform.isWindows;

const int _e = ShipGrid.emptyCell;

void main() {
  group('판자 이음 (설계서 §10.2)', () {
    test('같은 나무 재질 이웃 쪽만 잇고, 철판·망사·다른 재질은 잇지 않는다', () {
      // 3×2, y = 0 이 아래 줄: [참 참 소] / [참 철 _]
      final mats = [
        BlockMaterial.oak.index,
        BlockMaterial.oak.index,
        BlockMaterial.pine.index,
        BlockMaterial.oak.index,
        BlockMaterial.iron.index,
        _e,
      ];
      expect(PlankJoin.mask(mats, 3, 0, 0), PlankJoin.right | PlankJoin.up);
      expect(PlankJoin.mask(mats, 3, 1, 0), PlankJoin.left);
      expect(PlankJoin.mask(mats, 3, 2, 0), 0, reason: '이웃이 다른 재질');
      expect(PlankJoin.mask(mats, 3, 1, 1), 0, reason: '철판은 칸마다 따로');
    });

    test('이어지는 변만 테두리 두께만큼 잘라 늘린다', () {
      const src = ui.Rect.fromLTWH(0, 0, 64, 64);
      expect(PlankJoin.trimmed(src, 0), src);
      expect(
        PlankJoin.trimmed(src, PlankJoin.left | PlankJoin.up),
        const ui.Rect.fromLTRB(2, 2, 64, 64),
      );
    });
  });

  group('선체 마감 (설계서 §3.4, §10.2)', () {
    test('슬루프 틀 계단은 양쪽 두 줄씩 네 개이고, 칸이 부서지면 그 판도 없다', () {
      const hull = HullSpec.sloop;
      final all = HullTrim.steps(hull, hull.inFrame);
      expect(all, hasLength(4));
      expect(all.map((s) => (s.y, s.low, s.high, s.left)), [
        (0, 2, 1, true),
        (0, 9, 10, false),
        (1, 1, 0, true),
        (1, 10, 11, false),
      ]);
      final broken = HullTrim.steps(
        hull,
        (x, y) => hull.inFrame(x, y) && !(x == 2 && y == 0),
      );
      expect(broken, hasLength(3), reason: '붙은 칸이 부서지면 같이 사라진다');
    });

    test('틀이 생기기 전에 저장한 설계도는 틀 밖 칸만 빼고 살린다', () {
      final preset = testCatalog.preset('balanced').blueprint.toJson();
      final old = {
        ...preset,
        'cells': [
          ...preset['cells']! as List<Object?>,
          [0, 0, 'oak'],
          [11, 0, 'oak'],
        ],
      };
      expect(Blueprint.problemOfJson(old), isNotNull);
      final fitted = FleetStore.fitToFrame(old);
      expect(Blueprint.problemOfJson(fitted), isNull);
      expect(fitted['cells'], preset['cells']);
    });
  });

  testWidgets('추천 설계도 배는 배 모양 선체·판자 이음·기움대·키로 그린다 (골든)', (
    tester,
  ) async {
    final session = BattleSession(
      testSetup.newMatch(7),
      humanSides: const {0, 1},
      speciesOf: testCatalog.speciesOf,
    );
    rootBundle.clear();
    late ui.Image image;
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
      final grid = session.state.sides[ship.side].grid;
      const m = Coords.cell;
      final w = grid.width * Coords.cell + m * 3;
      final h = grid.height * Coords.cell + m * 2;
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder)
        ..drawColor(const ui.Color(0xFF8CC8EE), ui.BlendMode.src)
        ..translate(grid.width * Coords.cell / 2 + m, h - m);
      ship.render(canvas);
      image = await recorder.endRecording().toImage(w.round(), h.round());
    });
    await expectLater(image, matchesGoldenFile('goldens/hull_balanced.png'));
  }, skip: _skipGolden);
}
