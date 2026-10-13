import 'package:flutter_test/flutter_test.dart';
import 'package:pirate_busters/audio/sfx_bank.dart';
import 'package:pirate_busters/audio/shanty_music.dart';
import 'package:pirate_busters/audio/sound_service.dart';
import 'package:pirate_busters/game/view/explosion_fx.dart';
import 'package:pirate_busters/settings/settings_store.dart';

void main() {
  group('폭발 (설계서 §10.4, A13)', () {
    test('불덩이 그림은 뜨거움 → 불 → 식음 → 속불 연기 → 연기 순으로 한 번씩 바뀐다', () {
      final frames = [
        for (var t = 0.0; t < Fireball.life; t += .01) Fireball.frameAt(t),
      ];
      expect(frames.first, 0);
      expect(frames.last, ExplosionFx.fireballFrames.length - 1);
      for (var i = 1; i < frames.length; i++) {
        expect(frames[i] - frames[i - 1], inInclusiveRange(0, 1));
      }
      expect(frames.toSet(), {0, 1, 2, 3, 4});
    });

    test('불덩이는 빠르게 커지고 0.4초부터 흐려져 수명 끝에 사라진다', () {
      expect(Fireball.scaleAt(.1), greaterThan(Fireball.scaleAt(0) + .4));
      expect(Fireball.scaleAt(.5), greaterThan(Fireball.scaleAt(.3)));
      expect(Fireball.alphaAt(.2), 1);
      expect(Fireball.alphaAt(Fireball.life), 0);
      expect(Fireball.alphaAt(.5), inExclusiveRange(0, 1));
    });
  });

  group('소리 (설계서 §10.3, ADR-068)', () {
    test('새 효과음(유폭·격침·승패 악구·버튼)도 만들어지고 같은 바이트가 나온다', () {
      for (final s in Sfx.values) {
        final a = SfxBank.wav(s);
        expect(a.length, greaterThan(44), reason: s.name);
        expect(SfxBank.wav(s), a, reason: '${s.name} 결정적');
      }
    });

    test('배경음악은 항구·전투 두 곡이고, 몇 초 길이의 루프가 늘 같은 바이트로 나온다', () {
      final all = ShantyMusic.build();
      expect(all.keys, Music.values);
      for (final m in Music.values) {
        final wav = all[m]!;
        // 22050Hz 16비트 모노: 4초 ~ 20초.
        final seconds = (wav.length - 44) / (22050 * 2);
        expect(seconds, inInclusiveRange(4, 20), reason: m.name);
        expect(ShantyMusic.wav(m), wav, reason: '${m.name} 결정적');
      }
    });

    test('음악 켜기 설정은 기본 켬이고 끈 값을 기억한다', () async {
      final store = MemorySettingsStore();
      expect(store.music, isTrue);
      await store.setMusic(on: false);
      expect(store.music, isFalse);
    });
  });
}
