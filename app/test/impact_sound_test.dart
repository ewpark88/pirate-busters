import 'package:flutter_test/flutter_test.dart';
import 'package:pirate_busters/audio/sound_service.dart';
import 'package:pirate_busters/game/impact_sound.dart';
import 'package:pirate_busters/game/view/hit_weight.dart';

void main() {
  group('착탄 소리 겹침 (설계서 §10.3, A32)', () {
    test('가벼운 한 방은 작은 쾅과 나무, 묵직한 한 방은 큰 쾅·나무·잔향이다', () {
      expect(impactLayers(const HitWeight(200), iron: false), [
        (Sfx.hit, 0.7),
        (Sfx.wood, 0.6),
      ]);
      expect(impactLayers(const HitWeight(500), iron: false).first, (
        Sfx.hit,
        1.0,
      ));
      expect(impactLayers(const HitWeight(800), iron: false), [
        (Sfx.hitBig, 1.0),
        (Sfx.wood, 0.6),
        (Sfx.rumble, 0.8),
      ]);
    });

    test('철판에 맞으면 나무 대신 철판 소리를 겹친다', () {
      final sfx = [
        for (final (s, _) in impactLayers(const HitWeight(200), iron: true)) s,
      ];
      expect(sfx, [Sfx.hit, Sfx.clang]);
    });

    test('포성은 착탄에 다시 쓰지 않는다', () {
      for (final score in [0, 400, 1000]) {
        for (final iron in [true, false]) {
          expect(
            impactLayers(HitWeight(score), iron: iron).map((l) => l.$1),
            isNot(contains(Sfx.cannon)),
          );
        }
      }
    });
  });

  group('한 프레임 효과음 묶음 (설계서 §10.3, A32)', () {
    test('같은 프레임의 같은 소리는 하나만 내고 다음 프레임에는 다시 낸다', () {
      final m = SfxMixer()..beginFrame();
      expect(m.admit(Sfx.wood, 0.6), 0.6);
      expect(m.admit(Sfx.wood, 0.6), isNull);
      m.beginFrame();
      expect(m.admit(Sfx.wood, 0.6), 0.6);
    });

    test('크기 합은 상한을 넘지 않는다', () {
      final m = SfxMixer()..beginFrame();
      var sum = 0.0;
      for (final s in Sfx.values) {
        sum += m.admit(s, 1) ?? 0;
      }
      expect(sum, lessThanOrEqualTo(SfxMixer.frameBudget + 1e-9));
    });
  });

  group('내려오는 탄의 휘파람 (설계서 §10.3, A32)', () {
    test('높이 오른 탄이 꼭대기를 지나 내려오기 시작할 때 한 번만 낸다', () {
      final w = WhistleCue();
      final path = <double>[-20, -100, -180, -220, -230, -225, -200, -100, -10];
      final fired = [for (final y in path) w.update(y)];
      expect(fired.where((f) => f), hasLength(1));
      expect(fired.indexOf(true), path.indexOf(-225));
    });

    test('낮게 깔린 탄은 내지 않고, 탄이 없어지면 다음 탄에서 다시 낸다', () {
      final w = WhistleCue();
      for (final y in <double>[-20, -60, -80, -60, -10]) {
        expect(w.update(y), isFalse);
      }
      expect(w.update(null), isFalse);
      var fired = false;
      for (final y in <double>[-100, -200, -150]) {
        fired = w.update(y) || fired;
      }
      expect(fired, isTrue);
    });
  });
}
