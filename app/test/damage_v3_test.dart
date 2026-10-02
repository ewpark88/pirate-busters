import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/game/view/damage_layer.dart';
import 'package:pirate_busters/game/view/damage_style.dart';
import 'package:pirate_busters/game/view/scorch_painter.dart';

/// 골든은 만든 환경(Windows)에서만 비교한다.
/// 다시 만들기: `flutter test test/damage_v3_test.dart --update-goldens`.
final bool _skipGolden = !Platform.isWindows;

const int _w = 8;
const int _h = 4;

/// 테스트 배: 아래 줄 참나무, 가운데 줄 소나무·철판, 위 줄 참나무 (y 는 위로).
final List<int> _mats = [
  for (var y = 0; y < _h; y++)
    for (var x = 0; x < _w; x++)
      (y == 1 && x >= 5
              ? BlockMaterial.iron
              : (y == 1 ? BlockMaterial.pine : BlockMaterial.oak))
          .index,
];

/// 착탄 [hits] 개를 누적한 칸 코드: 맞은 칸은 부서지고 상하좌우는 2단계,
/// 대각선은 1단계 손상이 쌓인다(그림 확인용 단순 모형, 판정과 무관).
List<int> _codes(List<(int, int)> hits) {
  final codes = List.filled(_w * _h, 0);
  void add(int x, int y, int n) {
    if (x < 0 || x >= _w || y < 0 || y >= _h) return;
    final i = y * _w + x;
    codes[i] = (codes[i] + n).clamp(0, DamageLayer.broken);
  }

  for (final (x, y) in hits) {
    add(x, y, 3);
    for (final (dx, dy) in const [(1, 0), (-1, 0), (0, 1), (0, -1)]) {
      add(x + dx, y + dy, 2);
    }
    for (final (dx, dy) in const [(1, 1), (-1, 1), (1, -1), (-1, -1)]) {
      add(x + dx, y + dy, 1);
    }
  }
  return codes;
}

const List<(int, int)> _hits = [(2, 2), (3, 1), (6, 2), (1, 0)];

Future<List<int>> _png(List<int> codes) async {
  final recorder = ui.PictureRecorder();
  DamageLayer.draw(Canvas(recorder), _w, codes, _mats, 1);
  final image = await recorder.endRecording().toImage(_w * 32, _h * 32);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  return bytes!.buffer.asUint8List();
}

void main() {
  group('피해 표현 v3 (설계서 §10.2·§10.4, ADR-070)', () {
    test('고정 난수가 참고 구현 damage38.py 의 rnd 와 같다', () {
      expect(DamageStyle.rnd(0, 0, 0), closeTo(0.02196269016712904, 1e-12));
      expect(DamageStyle.rnd(3, 5, 50), closeTo(0.8682760579977185, 1e-12));
      expect(DamageStyle.rnd(12, 1, 200), closeTo(0.7155510992743075, 1e-12));
      expect(DamageStyle.rnd(7, 9, 175), closeTo(0.6255367908161134, 1e-12));
      expect(DamageStyle.rnd(-1, 2, 9), closeTo(0.9825542431790382, 1e-12));
    });

    test('색이 에셋 damage_v3.json 과 같다', () {
      final file = File('../art/pb_v0.26_patch/fx/damage_v3/damage_v3.json');
      if (!file.existsSync()) return markTestSkipped('art/ 없음 (git 제외)');
      final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      final colors = json['colors'] as Map<String, dynamic>;
      String hex(Color c) =>
          '#${(c.toARGB32() & 0xffffff).toRadixString(16).padLeft(6, '0')}';
      expect(hex(DamageStyle.interior), colors['interior']);
      expect(hex(DamageStyle.interiorBeam), colors['interiorBeam']);
      expect(hex(DamageStyle.wet), colors['wet']);
      expect(hex(DamageStyle.wetBeam), colors['wetBeam']);
      final wood = colors['wood'] as Map<String, dynamic>;
      for (final (name, p) in [
        ('oak', DamageStyle.oak),
        ('bot', DamageStyle.bot),
        ('pine', DamageStyle.pine),
      ]) {
        final j = wood[name] as Map<String, dynamic>;
        expect(
          [hex(p.base), hex(p.dark), hex(p.fresh), hex(p.inner)],
          [j['base'], j['dark'], j['fresh'], j['inner']],
          reason: name,
        );
      }
      final iron = colors['iron'] as Map<String, dynamic>;
      expect(
        [
          hex(DamageStyle.ironBase),
          hex(DamageStyle.ironHi),
          hex(DamageStyle.ironDark),
          hex(DamageStyle.ironHot),
        ],
        [iron['base'], iron['hi'], iron['dark'], iron['hot']],
      );
    });

    test('흘수선 아래 참나무·소나무는 젖은 색, 코르크는 소나무, 망사는 참나무 색이다', () {
      expect(DamageStyle.woodOf(BlockMaterial.oak, wet: true), DamageStyle.bot);
      expect(
        DamageStyle.woodOf(BlockMaterial.pine, wet: true),
        DamageStyle.bot,
      );
      expect(DamageStyle.woodOf(BlockMaterial.pine), DamageStyle.pine);
      expect(DamageStyle.woodOf(BlockMaterial.cork), DamageStyle.pine);
      expect(DamageStyle.woodOf(BlockMaterial.net), DamageStyle.oak);
    });

    test('이어진 구멍·파괴 칸은 한 덩어리, 떨어진 칸은 다른 덩어리로 그을린다', () {
      const hot = {(1, 1), (2, 1), (2, 2), (5, 0)};
      final out = ScorchPainter.clusters(6, 3, (c, r) => hot.contains((c, r)));
      expect(out, hasLength(2));
      // 칸 번호 순(위 줄부터)으로 처음 만난 칸이 덩어리의 첫 칸이다.
      expect(out.first, [(5, 0)]);
      expect(out.last.toSet(), {(1, 1), (2, 1), (2, 2)});
      expect(out.last.first, (1, 1));
    });

    test('같은 칸 단계면 그림이 같다 (리플레이 동일)', () async {
      final codes = _codes(_hits);
      expect(await _png(codes), await _png(List.of(codes)));
      expect(
        await _png(codes),
        isNot(await _png(_codes(_hits.take(1).toList()))),
      );
    });

    test('위 칸이 부서진 블록은 윗변이 찢기고 아래 칸이 부서진 블록은 그렇지 않다', () async {
      // 세로 1칸 × 3줄: 가운데(y=1)가 부서짐. 위 블록(y=2)은 아랫변, 아래 블록(y=0)은 윗변이 찢긴다.
      const codes = [0, DamageLayer.broken, 0];
      final mats = List.filled(3, BlockMaterial.oak.index);
      final recorder = ui.PictureRecorder();
      DamageLayer.draw(Canvas(recorder), 1, codes, mats, 0);
      final image = await recorder.endRecording().toImage(32, 96);
      final px = (await image.toByteData())!;
      int alpha(int x, int y) => px.getUint8((y * 32 + x) * 4 + 3);
      // 줄 r: 0 = 맨 위(y=2), 1 = 부서진 칸, 2 = 맨 아래(y=0). 톱니 깊이는 1.5px 이상.
      // 찢긴 변은 배 속 색으로 불투명하게 덮고, 그을음은 반투명으로만 번진다.
      expect(alpha(16, 64), 255, reason: '아래 블록 윗변');
      expect(alpha(16, 31), 255, reason: '위 블록 아랫변');
      expect(alpha(16, 95), lessThan(255), reason: '아래 블록 아랫변은 찢기지 않는다');
      expect(alpha(16, 0), lessThan(255), reason: '위 블록 윗변은 찢기지 않는다');
    });

    test('칸 단계와 젖은 줄이 그대로면 다시 녹화하지 않는다', () {
      final layer = DamageLayer();
      final canvas = Canvas(ui.PictureRecorder());
      void paint(List<int> codes, int wet) => layer.paint(
        canvas,
        width: _w,
        codes: codes,
        materials: _mats,
        wetRows: wet,
        origin: Offset.zero,
        cell: 32,
      );
      paint(_codes(_hits), 1);
      paint(_codes(_hits), 1);
      expect(layer.recordings, 1);
      paint(_codes(_hits.take(2).toList()), 1);
      expect(layer.recordings, 2);
      paint(_codes(_hits.take(2).toList()), 2);
      expect(layer.recordings, 3);
      layer.dispose();
    });

    // 비교 페이지 38단계 stage38_h0~h3 처럼 1~4발 누적 모습.
    for (var n = 1; n <= _hits.length; n++) {
      testWidgets('$n발 맞은 배가 골든 그림과 같다', (tester) async {
        final codes = _codes(_hits.take(n).toList());
        await tester.pumpWidget(
          Center(
            child: RepaintBoundary(
              child: CustomPaint(
                size: const Size(_w * 32.0 + 32, _h * 32.0 + 32),
                painter: _ShipPainter(codes),
              ),
            ),
          ),
        );
        await expectLater(
          find.byType(RepaintBoundary).first,
          matchesGoldenFile('goldens/damage_h${n - 1}.png'),
        );
      }, skip: _skipGolden);
    }
  });
}

/// 재질 색 칸 위에 손상 레이어를 얹는다 (하늘 바탕, 아래 줄은 젖음).
class _ShipPainter extends CustomPainter {
  _ShipPainter(this.codes);

  final List<int> codes;

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..drawRect(Offset.zero & size, Paint()..color = const Color(0xFF7FC0EC))
      ..translate(16, 16);
    for (var y = 0; y < _h; y++) {
      for (var x = 0; x < _w; x++) {
        final i = y * _w + x;
        if (codes[i] == DamageLayer.broken) continue;
        final m = BlockMaterial.values[_mats[i]];
        final color = switch (m) {
          BlockMaterial.iron => DamageStyle.ironBase,
          _ => DamageStyle.woodOf(m, wet: y == 0).base,
        };
        canvas.drawRect(
          Rect.fromLTWH(x * 32.0, (_h - 1 - y) * 32.0, 32, 32),
          Paint()..color = color,
        );
      }
    }
    DamageLayer.draw(canvas, _w, codes, _mats, 1);
  }

  @override
  bool shouldRepaint(_ShipPainter old) => old.codes != codes;
}
