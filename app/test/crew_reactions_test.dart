import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pirate_busters/game/anim/anim_data.dart';
import 'package:pirate_busters/game/anim/part_component.dart';
import 'package:pirate_busters/game/view/crew_reactions.dart';

void main() {
  group('해적 반응 (설계서 §10.4, A32)', () {
    test('맞은 해적은 밀렸다가 선실 자리로 돌아온다', () {
      final r = CrewReactions();
      final home = Vector2(10, -40);
      final cabin = home.clone();
      r.hit(home, -1);
      expect(home.x, 10 - CrewReactions.knock);
      for (var i = 0; i < 60; i++) {
        r.move(0, home, cabin, 0.1, 1 / 60);
      }
      expect(home.distanceTo(cabin), lessThan(0.1));
    });

    test('바다로 떨어지는 해적은 포물선으로 날아가 수면에 닿을 때 한 번 알린다', () {
      final r = CrewReactions();
      final home = Vector2(0, -40);
      final sea = Vector2(100, 0);
      var landed = 0;
      r.fall(0, home, () => landed++);
      expect(r.falling(0), isTrue);
      var top = home.y;
      var t = 0.0;
      while (r.falling(0)) {
        r.move(0, home, sea, 0.1, 1 / 60);
        top = top < home.y ? top : home.y;
        t += 1 / 60;
      }
      expect(t, closeTo(CrewReactions.fallSec, 0.03));
      expect(top, lessThan(-40), reason: '처음보다 높이 솟는다');
      expect(home, sea);
      expect(landed, 1);
      r.move(0, home, sea, 0.1, 1 / 60);
      expect(landed, 1, reason: '닿은 뒤에는 다시 알리지 않는다');
    });
  });

  testWidgets('피격 동작의 flash 이벤트는 부위를 하얗게 칠했다가 지운다', (tester) async {
    await tester.runAsync(() async {
      final recorder = ui.PictureRecorder();
      ui.Canvas(recorder).drawPaint(ui.Paint());
      final image = await recorder.endRecording().toImage(8, 8);
      final part = PartComponent(
        partId: 'body',
        anim: 'body',
        sprite: Sprite(image),
        offset: Vector2.zero(),
        pivot: Vector2.all(4),
        z: 0,
      );
      final pose = PartPose.sample(null, 0);
      part.applyPose(pose, 1, flash: 0.8);
      expect(part.paint.colorFilter, isNotNull);
      part.applyPose(pose, 1);
      expect(part.paint.colorFilter, isNull);
    });
  });
}
