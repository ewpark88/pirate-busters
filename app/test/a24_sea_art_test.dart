import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pirate_busters/battle/battle_session.dart';
import 'package:pirate_busters/game/battle_game.dart';
import 'package:pirate_busters/game/view/hull_trim.dart';
import 'package:pirate_busters/game/view/hull_water.dart';
import 'package:pirate_busters/game/view/sea_shape.dart';
import 'package:pirate_busters/game/view/sea_theme.dart';
import 'package:pirate_busters/game/view/sea_view.dart';

import 'test_catalog.dart';

/// 골든은 Windows 글꼴·렌더로 만든다(다른 OS 는 건너뛴다).
final bool _skipGolden = !Platform.isWindows;

const List<ShipOnSea> _ships = [
  (x: -800, half: 190, heave: -4, facing: 1, moving: false),
  (x: 800, half: 190, heave: 6, facing: -1, moving: false),
];

void main() {
  group('잠긴 선체 (설계서 §10.2, A24)', () {
    test('배가 기울지 않으면 수면은 흘수 깊이의 수평선이다', () {
      for (final lx in [-100.0, 0.0, 100.0]) {
        expect(HullWater.surfaceAt(lx, w0: -40, angle: 0, sx: 1), -40);
      }
    });

    test('배가 기울면 로컬 수면이 반대로 기울어 화면에서는 수평을 지킨다', () {
      const a = 0.05;
      for (final sx in [1.0, -1.0]) {
        for (final lx in [-120.0, 80.0]) {
          final ly = HullWater.surfaceAt(lx, w0: -40, angle: a, sx: sx);
          // 로컬 → 화면 y: sin(a)·sx·lx + cos(a)·ly 가 늘 w0 이다.
          expect(math.sin(a) * sx * lx + math.cos(a) * ly, closeTo(-40, 1e-9));
        }
      }
    });

    test('잠긴 칸이 없으면 아무것도 그리지 않는다', () {
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      final hull = ui.Path()..addRect(const ui.Rect.fromLTWH(0, -64, 64, 64));
      HullWater.draw(
        canvas,
        hull: hull,
        bounds: hull.getBounds(),
        waterAt: (_) => 10,
        t: 0,
      );
      // 그리기 명령이 없으면 그림 경계가 비어 있다.
      expect(recorder.endRecording().approximateBytesUsed, lessThan(200));
    });

    test('장식 색은 진영마다 다르다', () {
      expect(TrimStyle.ofSide(0).accent, isNot(TrimStyle.ofSide(1).accent));
    });
  });

  group('너울·물마루 (설계서 §10.2, A24)', () {
    test('너울은 배 자리에서 0이라 배와 물이 어긋나지 않는다', () {
      for (final s in _ships) {
        for (final dx in [-s.half, 0.0, s.half]) {
          expect(SeaShape.swell(s.x + dx, 3, _ships, 1), 0);
        }
      }
    });

    test('먼 바다에는 너울이 있고 폭풍이면 커진다', () {
      double peak(double scale) => [
        for (var x = -3000.0; x < -1500; x += 7)
          SeaShape.swell(x, 0, _ships, scale).abs(),
      ].reduce(math.max);
      expect(peak(1), greaterThan(SeaShape.amp * .9));
      expect(peak(1.5), closeTo(peak(1) * 1.5, 1e-9));
    });

    test('물마루는 수면이 가장 높은 곳(화면 y 최소)이다', () {
      final sea = SeaShape(ships: () => _ships, scale: () => 1)..update(2);
      for (final x in sea.crests(-3600, -1800)) {
        final h = SeaShape.swell(x, sea.t, _ships, 1);
        expect(h, closeTo(-SeaShape.amp * SeaShape.calm(_ships, x), 1e-6));
      }
    });

    test('두 배 사이 수면은 두 배의 파도 높이를 잇는다', () {
      expect(SeaShape.lerp(_ships, -800), -4);
      expect(SeaShape.lerp(_ships, 800), 6);
      expect(SeaShape.lerp(_ships, 0), 1);
    });
  });

  test('저사양이면 움직이는 배 뒤 항적을 끄고 물갈림만 남긴다 (설계서 §12)', () {
    final moving = [(x: 0.0, half: 190.0, heave: 0.0, facing: 1, moving: true)];
    SeaView make({required bool low}) => SeaView(
      front: true,
      theme: SeaTheme.tropicalDay,
      shape: SeaShape(ships: () => moving, scale: () => 1)..update(0),
      lowEnd: ValueNotifier(low),
    );
    final full = make(low: false);
    final low = make(low: true);
    for (var i = 0; i < 30; i++) {
      full.update(1 / 30);
      low.update(1 / 30);
    }
    expect(full.wakeCount, greaterThan(low.wakeCount + 40));
  });

  testWidgets('전투 한 장면: 잠긴 선체·수면선·너울 (골든)', (tester) async {
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
      for (var i = 0; i < 20; i++) {
        game.update(1 / 20);
      }
      game.lowEnd.value = true; // 포말 난수·셰이더 없이 그라데이션으로 고정
      final recorder = ui.PictureRecorder();
      game.render(ui.Canvas(recorder));
      image = await recorder.endRecording().toImage(960, 440);
    });
    await expectLater(image, matchesGoldenFile('goldens/battle_sea.png'));
  }, skip: _skipGolden);
}
