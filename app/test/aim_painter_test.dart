import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:pirate_busters/game/view/aim_labels.dart';
import 'package:pirate_busters/game/view/aim_painter.dart';

void main() {
  group('조준 점선 (설계서 §10.4, ADR-063)', () {
    double gap(Offset a, Offset b) => (b - a).distance;

    test('곧은 선과 꺾인 선 모두 점 사이가 호 길이로 같은 간격이다', () {
      final straight = AimPainter.resample(
        const [Offset.zero, Offset(100, 0)],
        7,
      );
      expect(straight.first, Offset.zero);
      for (var i = 1; i < straight.length; i++) {
        expect(gap(straight[i - 1], straight[i]), closeTo(7, 1e-9));
      }
      // 꺾인 선: 꺾이는 자리를 지나도 호 길이 간격은 그대로다(직선 거리는 짧아질 수 있다).
      final bent = AimPainter.resample(
        const [Offset.zero, Offset(10, 0), Offset(10, 30)],
        5,
      );
      expect(bent.map((p) => (p.dx, p.dy)), [
        (0, 0),
        (5, 0),
        (10, 0),
        (10, 5),
        (10, 10),
        (10, 15),
        (10, 20),
        (10, 25),
        (10, 30),
      ]);
    });

    test('힘 링 바깥부터 찍고, 흐름 값만큼 모든 점이 앞으로 간다', () {
      const path = [Offset.zero, Offset(200, 0)];
      final dots = AimPainter.resample(path, 7, skip: AimPainter.dotSkip);
      expect(dots.first.dx, AimPainter.dotSkip);
      expect(AimPainter.dotSkip, greaterThan(AimPainter.ringRadius));
      final moved = AimPainter.resample(
        path,
        7,
        skip: AimPainter.dotSkip,
        phase: 3,
      );
      for (var i = 0; i < moved.length; i++) {
        expect(moved[i].dx - dots[i].dx, closeTo(3, 1e-9));
      }
    });

    test('앞 점은 진하고 끝 점은 0.45 까지 흐려지며 줄어들기만 한다', () {
      final alphas = [for (var i = 0; i <= 10; i++) AimPainter.dotAlpha(i, 10)];
      expect(alphas.first, 1);
      expect(alphas.last, closeTo(.45, 1e-9));
      for (var i = 1; i < alphas.length; i++) {
        expect(alphas[i], lessThan(alphas[i - 1]));
      }
    });

    test('각도 숫자는 조준 방향(점선) 위가 아니라 호 가운데 쪽, 힘은 발사 지점 아래에 둔다', () {
      const from = Offset.zero;
      for (final facing in const [1, -1]) {
        final dir = AimPainter.direction(facing, 60000);
        final at = AimLabels.angleAt(from, dir);
        expect((at - from).distance, closeTo(30, 1e-9));
        // 수평(0°)과 60° 의 가운데 = 30° 쪽, 보는 쪽을 따른다.
        expect(at.dx.sign, facing.toDouble());
        expect(at.dy, closeTo(-15, 1e-9));
      }
      expect(AimLabels.powerAt(from), const Offset(0, 28));
    });

    test('점선·고무줄·숫자를 양쪽 진영 모두 오류 없이 그린다', () {
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      for (final facing in const [1, -1]) {
        AimLabels.draw(
          canvas,
          const Offset(10, -40),
          AimPainter.direction(facing, 40000),
          angle: '40°',
          power: '힘 74%',
        );
      }
      AimPainter.trajectory(
        canvas,
        [for (var i = 0; i < 8; i++) Offset(i * 7, -i * 4)],
        const Color(0xFFFFF2DC),
        fadeIn: .3,
      );
      recorder.endRecording().dispose();
    });
  });
}
