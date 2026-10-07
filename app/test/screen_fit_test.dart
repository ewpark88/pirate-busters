import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:pirate_busters/game/camera_director.dart';
import 'package:pirate_busters/game/coords.dart';
import 'package:pirate_busters/ui/kit/kit_motion.dart';
import 'package:pirate_busters/ui/kit/nine_slice.dart';

void main() {
  group('9조각 바탕 (설계서 §13 공통, A42)', () {
    // 버튼 그림 536×200, 가운데 (64, 56)~(472, 140), 배율 4.
    const src = Size(536, 200);
    const slice = Rect.fromLTRB(64, 56, 472, 140);

    test('모서리는 배율만큼 줄인 크기로, 9칸이 상자를 빈틈없이 채운다', () {
      const box = Rect.fromLTWH(10, 20, 200, 40);
      final parts = NineSliceDecoration.plan(src, slice, 4, box);
      expect(parts, hasLength(9));
      final (_, topLeft) = parts.first;
      expect(topLeft.width, 16, reason: '64px / 4');
      expect(topLeft.height, 14, reason: '56px / 4');
      final (_, bottomRight) = parts.last;
      expect(bottomRight.right, box.right);
      expect(bottomRight.bottom, box.bottom);
      expect(bottomRight.width, 16, reason: '(536 − 472) / 4');
      expect(bottomRight.height, 15, reason: '(200 − 140) / 4');
      for (final (_, d) in parts) {
        expect(box.contains(d.topLeft), isTrue, reason: '상자 밖으로 나가지 않는다');
        expect(d.right, lessThanOrEqualTo(box.right));
        expect(d.bottom, lessThanOrEqualTo(box.bottom));
      }
    });

    test('상자가 모서리 합보다 작으면 모서리를 비율대로 줄여 상자 안에 넣는다', () {
      const box = Rect.fromLTWH(0, 0, 20, 20);
      final parts = NineSliceDecoration.plan(src, slice, 4, box);
      for (final (_, d) in parts) {
        expect(d.right, lessThanOrEqualTo(20 + 1e-9));
        expect(d.bottom, lessThanOrEqualTo(20 + 1e-9));
        expect(d.width, greaterThanOrEqualTo(0));
      }
    });
  });

  group('화면 전환 (설계서 §13 공통, A42)', () {
    test('이전 화면이 먼저 사라지고 새 화면이 뒤에 나타나 두 화면이 겹치지 않는다', () {
      expect(KitPageTransitions.incoming(0), 0);
      expect(KitPageTransitions.incoming(1), 1);
      expect(KitPageTransitions.outgoing(0), 1);
      expect(KitPageTransitions.outgoing(1), 0);
      for (var i = 0; i <= 20; i++) {
        final t = i / 20;
        // 같은 진행에서 두 화면이 함께 진하게 보이는 일이 없다(잔상).
        expect(
          KitPageTransitions.incoming(t) * KitPageTransitions.outgoing(t),
          lessThan(0.05),
          reason: '$t',
        );
      }
    });
  });

  group('기본 화면 높이 (설계서 §2.1, A42)', () {
    const aspect = 384 / 832; // 갤럭시 S24 가로

    double waterline(CameraDirector c) {
      final (center, w) = c.target(
        myX: 0,
        enemyX: 900,
        facing: 1,
        aspect: aspect,
      );
      final halfH = w * aspect / 2;
      return (0 - (center.y - halfH)) / (2 * halfH);
    }

    test('작은 배는 수면이 아래쪽 HUD(위에서 약 75%)보다 위에 온다', () {
      final c = CameraDirector()..shipTop = -5 * Coords.cell;
      expect(waterline(c), closeTo(CameraDirector.idleWaterline, 1e-6));
      expect(waterline(c), lessThan(0.75));
    });

    test('큰 배와 배 정보가 없을 때는 예전 높이로 돛대 끝을 보인다', () {
      expect(
        CameraDirector().idleYFor(CameraDirector.baseWidth, aspect),
        CameraDirector.idleY,
      );
      final tall = CameraDirector()..shipTop = -14 * Coords.cell;
      expect(
        tall.idleYFor(CameraDirector.baseWidth, aspect),
        CameraDirector.idleY,
      );
    });
  });
}
