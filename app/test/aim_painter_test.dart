import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:pirate_busters/game/view/aim_labels.dart';
import 'package:pirate_busters/game/view/aim_painter.dart';
import 'package:pirate_busters/game/view/aim_sling.dart';

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

    test('각도·힘 알약은 발사 지점 아래 한 줄에 겹치지 않게 나란히 놓인다', () {
      const from = Offset(10, -40);
      expect(AimLabels.powerAt(from), const Offset(10, -8));
      final (a, p) = AimLabels.rowAt(from, 20, 30);
      expect(a.dy, p.dy);
      expect(a.dy, -8);
      // 각도가 왼쪽, 둘 사이는 틈만큼 떨어지고 줄 가운데에 모인다.
      expect(p.dx - a.dx, closeTo(10 + AimLabels.gap + 15, 1e-9));
      expect((a.dx - 10 + p.dx - 10) / 2, closeTo(-2.5, 1e-9));
    });

    test('점선·숫자를 오류 없이 그린다', () {
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      AimLabels.draw(
        canvas,
        const Offset(10, -40),
        angle: '40°',
        power: '힘 74%',
      );
      AimPainter.trajectory(
        canvas,
        [for (var i = 0; i < 8; i++) Offset(i * 7, -i * 4)],
        const Color(0xFFFFF2DC),
        fadeIn: .3,
      );
      recorder.endRecording().dispose();
    });

    test('힘 링은 10칸이고 힘만큼 앞 칸부터 차며 마지막 칸은 일부만 찬다', () {
      double lit(double p) => [
        for (var i = 0; i < AimSling.segments; i++) AimSling.segmentFill(i, p),
      ].reduce((a, b) => a + b);
      expect(AimSling.segments, 10);
      expect(lit(0), 0);
      expect(lit(.55), closeTo(5.5, 1e-9));
      expect(AimSling.segmentFill(4, .55), 1);
      expect(AimSling.segmentFill(5, .55), closeTo(.5, 1e-9));
      expect(AimSling.segmentFill(6, .55), 0);
      expect(lit(1), 10);
    });
  });
}
