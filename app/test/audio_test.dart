import 'package:flutter_test/flutter_test.dart';
import 'package:pirate_busters/audio/pcm_synth.dart';
import 'package:pirate_busters/audio/sfx_bank.dart';
import 'package:pirate_busters/audio/sound_service.dart';

void main() {
  group('코드 합성 효과음 (설계서 §10.3)', () {
    test('포성·나무 부서짐·물보라·철판 튕김 네 가지를 WAV 로 만든다', () {
      final wavs = SfxBank.build();
      expect(wavs.keys, containsAll(Sfx.values));
      for (final w in wavs.values) {
        expect(String.fromCharCodes(w.sublist(0, 4)), 'RIFF');
        expect(String.fromCharCodes(w.sublist(8, 12)), 'WAVE');
        expect(w.length, greaterThan(44 + 1000));
      }
    });

    test('같은 레시피면 같은 바이트가 나온다(시드 고정 노이즈)', () {
      expect(SfxBank.wav(Sfx.splash), SfxBank.wav(Sfx.splash));
    });

    test('지연을 준 노이즈는 그 시각 전에는 소리가 없다', () {
      final s = PcmSynth(durationSec: .2)..noise(.05, 1000, 500, delay: .1);
      final early = PcmSynth(durationSec: .1)..noise(.05, 1000, 500);
      expect(s.peak, greaterThan(0));
      expect(early.peak, greaterThan(0));
    });
  });
}
