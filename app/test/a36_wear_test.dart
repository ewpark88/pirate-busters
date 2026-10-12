import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/game/view/damage_layer.dart';

/// 골든은 만든 환경(Windows)에서만 비교한다.
final bool _skipGolden = !Platform.isWindows;

final int _oak = BlockMaterial.oak.index;

/// 내구도 [max] 인 참나무 칸의 [hp] 별 코드.
int _code(int hp, int max) => DamageLayer.codeOf(_oak, _oak, hp, max);

Future<ui.Image> _row(List<int> codes) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)
    ..drawColor(const Color(0xFFB98A57), BlendMode.src);
  DamageLayer.draw(canvas, codes.length, codes, [
    for (final _ in codes) _oak,
  ], 0);
  return recorder.endRecording().toImage(codes.length * 32, 32);
}

Future<List<int>> _bytes(List<int> codes) async {
  final image = await _row(codes);
  final data = await image.toByteData();
  return data!.buffer.asUint8List();
}

void main() {
  group('단계 안 손상 (설계서 §10.2, A36)', () {
    test('멀쩡한 칸은 닳음 0, 단계 구간을 내려갈수록 1~3 으로 짙어진다', () {
      const max = 90;
      expect(DamageLayer.wearOf(90, max), 0);
      // 멀쩡 구간 (60, 90]: 위끝 바로 아래부터 1, 구간 끝 가까이 3.
      expect(DamageLayer.wearOf(89, max), 1);
      expect(DamageLayer.wearOf(61, max), 3);
      // 금간 구간 (30, 60]: 구간 위끝(60)은 0, 내려갈수록 는다.
      expect(DamageLayer.wearOf(60, max), 0);
      expect(DamageLayer.wearOf(45, max), 2);
      expect(DamageLayer.wearOf(31, max), 3);
      // 구멍 구간 (0, 30].
      expect(DamageLayer.wearOf(30, max), 0);
      expect(DamageLayer.wearOf(1, max), 3);
    });

    test('같은 단계 안에서 맞을 때마다 닳음은 줄지 않는다', () {
      const max = 120;
      var last = 0;
      var stage = 0;
      for (var hp = max; hp > 0; hp--) {
        final code = _code(hp, max);
        final s = DamageLayer.stageOf(code);
        if (s != stage) {
          stage = s;
          last = 0;
        }
        final w = DamageLayer.wearPart(code);
        expect(w, greaterThanOrEqualTo(last), reason: 'hp $hp');
        last = w;
      }
    });

    test('단계 부분은 판정의 손상 단계와 같다', () {
      const max = 75;
      for (var hp = 1; hp <= max; hp++) {
        expect(
          DamageLayer.stageOf(_code(hp, max)),
          ShipGrid.stageFor(hp, max).index,
        );
      }
      expect(
        DamageLayer.codeOf(ShipGrid.emptyCell, _oak, 0, max),
        DamageLayer.broken,
      );
    });

    test('같은 단계라도 더 닳은 칸은 다르게 그려진다', () async {
      final fresh = await _bytes([_code(59, 90)]);
      final worn = await _bytes([_code(32, 90)]);
      expect(fresh, isNot(worn));
      final again = await _bytes([_code(32, 90)]);
      expect(again, worn, reason: '같은 입력이면 같은 그림');
    });

    test('닳음이 바뀌면 손상 층을 다시 녹화한다', () {
      final layer = DamageLayer();
      addTearDown(layer.dispose);
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      void paint(int hp) => layer.paint(
        canvas,
        width: 1,
        codes: [_code(hp, 90)],
        materials: [_oak],
        wetRows: 0,
        origin: Offset.zero,
        cell: 32,
      );
      paint(59);
      paint(59);
      expect(layer.recordings, 1);
      paint(40);
      expect(layer.recordings, 2);
      recorder.endRecording().dispose();
    });

    testWidgets('단계별 새 칸·닳은 칸 (골든)', (tester) async {
      late ui.Image image;
      await tester.runAsync(() async {
        image = await _row([
          _code(90, 90),
          _code(70, 90),
          _code(61, 90),
          _code(59, 90),
          _code(45, 90),
          _code(31, 90),
          _code(29, 90),
          _code(15, 90),
          _code(2, 90),
        ]);
      });
      await expectLater(image, matchesGoldenFile('goldens/damage_wear.png'));
    }, skip: _skipGolden);
  });
}
