import 'dart:io';
import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/game/sprites.dart';
import 'package:pirate_busters/game/view/backdrop.dart';
import 'package:pirate_busters/game/view/backdrop_view.dart';
import 'package:pirate_busters/game/view/limit_marks.dart';
import 'package:pirate_busters/game/view/shot_view.dart';

Backdrop _data() => Backdrop.fromJson(
  File(Backdrop.regionsPath).readAsStringSync(),
  File(Backdrop.modesPath).readAsStringSync(),
);

void main() {
  group('해역 배경 (설계서 §10.2, ADR-063)', () {
    test('겹은 하늘에서 빛까지 그리는 순서대로이고 전장은 바다 겹을 쓰지 않는다', () {
      final data = _data();
      expect(data.layers.last.id, 'sea');
      expect(data.layersFor(lowEnd: false, sea: true), hasLength(7));
      expect(data.layersFor(lowEnd: false).map((l) => l.id), [
        'sky',
        'clouds',
        'far',
        'haze',
        'mid',
        'glow',
      ]);
      expect(data.layersFor(lowEnd: false).map((l) => l.parallax), [
        0,
        0.08,
        0.18,
        0.18,
        0.4,
        0.4,
      ]);
      expect(data.horizon, 420);
      expect((data.width, data.height), (1400, 640));
    });

    test('색 행렬은 먼 섬·가까운 섬 겹에만, 구름색은 어두운 모드의 구름에만 씌운다', () {
      final data = _data();
      for (final l in data.layers) {
        expect(
          data.filterFor(l, SeaMode.hard) != null,
          l.id == 'far' || l.id == 'mid',
          reason: l.id,
        );
        expect(
          data.filterFor(l, SeaMode.hell, region: 'tropic') != null,
          l.id == 'far' || l.id == 'mid' || l.id == 'clouds',
          reason: l.id,
        );
        expect(
          data.filterFor(l, SeaMode.normal, region: 'tropic') != null,
          l.id == 'far' || l.id == 'mid',
        );
      }
    });

    test('저사양 모드는 구름·안개·빛 겹을 빼고 섬과 하늘은 남긴다', () {
      final data = _data();
      expect(data.layersFor(lowEnd: true).map((l) => l.id), [
        'sky',
        'far',
        'mid',
      ]);
      final lowEnd = ValueNotifier(false);
      final view = BackdropView(data: data, region: 'tropic', lowEnd: lowEnd);
      expect(view.drawn, hasLength(6));
      lowEnd.value = true;
      expect(view.drawn, hasLength(3));
    });

    test('행렬 오프셋 열은 0~255 단위로 바꾼다', () {
      final m = Backdrop.flutterMatrix([
        1, 0, 0, 0, 0.02, //
        0, 1, 0, 0, 0.5,
        0, 0, 1, 0, 0,
        0, 0, 0, 1, 0,
      ]);
      expect(m[4], closeTo(5.1, 1e-9));
      expect(m[9], closeTo(127.5, 1e-9));
      expect(m[0], 1);
    });

    test('겹을 이어 붙인 첫 장은 화면 왼쪽 끝을 덮고 시차만큼 늦게 움직인다', () {
      final data = _data();
      final far = data.layers.firstWhere((l) => l.id == 'far');
      for (final camX in [-3000.0, -10.0, 0.0, 777.0, 5000.0]) {
        final left = camX - 1264;
        final x = data.tileStart(far, camX, left);
        expect(x, lessThanOrEqualTo(left));
        expect(x + data.width, greaterThan(left));
      }
      // 카메라가 100 움직이면 먼 섬은 월드에서 82 따라와 화면에서는 18 만 밀린다.
      final a = data.tileStart(far, 0, -5000);
      final b = data.tileStart(far, 100, -5000);
      expect((b - a) % data.width, closeTo(82, 1e-9));
    });

    test('해역 1 모드별 하늘색이 있고 어두운 모드일수록 빛 겹이 진하다', () {
      final data = _data();
      for (final mode in SeaMode.values) {
        expect(data.tone('tropic', mode).sky, hasLength(3));
      }
      expect(Backdrop.glowOpacity(SeaMode.normal), 0.35);
      expect(Backdrop.glowOpacity(SeaMode.hell), 1);
      expect(Backdrop.skyPicture(SeaMode.normal), isTrue);
      expect(Backdrop.skyPicture(SeaMode.hell), isFalse);
    });

    test('쓰는 해역의 겹 그림이 모두 있다', () {
      final data = _data();
      for (final region in ['tropic', 'gold', 'storm']) {
        for (final l in data.layers) {
          final f = 'assets/images/${Backdrop.file(region, l.id)}';
          expect(File(f).existsSync(), isTrue, reason: f);
        }
      }
    });
  });

  test('이동 한계 표식 그림이 있고 수면에 닿는 점이 그림 안에 있다 (설계서 §2.6)', () {
    for (final (file, anchor, w, h) in [
      (BattleSprites.limitForward, LimitMarks.forwardAnchor, 260, 110),
      (BattleSprites.limitBack, LimitMarks.backAnchor, 80, 110),
    ]) {
      expect(File('assets/images/$file').existsSync(), isTrue, reason: file);
      expect(BattleSprites.files, contains(file));
      expect(anchor.x, inInclusiveRange(0, w));
      expect(anchor.y, inInclusiveRange(0, h));
    }
    expect(BattleSprites.files, contains(BattleSprites.limitSplash));
  });

  test('후퇴 한계 부표·물살은 뱃머리가 한계에 닿았을 때의 고물 자리다 (설계서 §2.6)', () {
    // 오른쪽을 보는 배(+1): 고물은 뱃머리에서 왼쪽으로 배 길이만큼.
    expect(ShotView.sternAt(5000, 1, 12), 5000 - 12 * cellUnit);
    // 왼쪽을 보는 배(−1): 오른쪽으로.
    expect(ShotView.sternAt(-5000, -1, 12), -5000 + 12 * cellUnit);
  });

  testWidgets('저사양 모드로 바꿔도 전장 배경이 오류 없이 그려지고 겹 수가 준다', (tester) async {
    final lowEnd = ValueNotifier(false);
    await tester.runAsync(() async {
      final game = FlameGame()..onGameResize(Vector2(900, 414));
      // Flame 테스트 도우미와 같은 내부 수명 주기 호출이다.
      // ignore: invalid_use_of_internal_member
      await game.load();
      // Flame 테스트 도우미와 같은 내부 수명 주기 호출이다.
      // ignore: invalid_use_of_internal_member
      game.mount();
      final view = await BackdropView.load(
        game.images,
        rootBundle,
        lowEnd: lowEnd,
      );
      await game.world.add(view);
      game.update(0);
      await game.ready();
      for (final low in [false, true]) {
        lowEnd.value = low;
        final recorder = PictureRecorder();
        game.render(Canvas(recorder));
        final image = await recorder.endRecording().toImage(90, 41);
        expect(image.width, 90);
        expect(view.drawn, hasLength(low ? 3 : 6));
      }
    });
    expect(tester.takeException(), isNull);
  });

  test('가까운 섬 겹(등대)만 하늘색 안개로 흐려 원경으로 보인다 (설계서 §10.2, A40)', () {
    expect(Backdrop.hazeOf('mid'), inExclusiveRange(0, 1));
    for (final id in ['sky', 'clouds', 'far', 'haze', 'glow', 'sea']) {
      expect(Backdrop.hazeOf(id), 0, reason: id);
    }
  });
}
