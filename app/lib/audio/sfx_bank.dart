import 'dart:typed_data';

import 'package:pirate_busters/audio/pcm_synth.dart';
import 'package:pirate_busters/audio/sound_service.dart';

/// 코드 합성 효과음 레시피 (설계서 §10.3, 개발 계획서 M4). mozzi SfxBank 의 구성.
abstract final class SfxBank {
  static const double masterGain = 2.2;

  /// 모든 효과음 WAV.
  static Map<Sfx, Uint8List> build() => {for (final s in Sfx.values) s: wav(s)};

  static Uint8List wav(Sfx s) => switch (s) {
    // 포성: 낮은 쿵 + 짧은 폭음.
    Sfx.cannon =>
      (PcmSynth(durationSec: .7)
            ..tone(95, 34, .6, vol: .42)
            ..noise(.55, 420, 60, vol: .34, q: .7, seed: 3)
            ..noise(.09, 2400, 900, vol: .16, seed: 4))
          .toWav(gain: masterGain),
    // 나무 부서짐: 우지끈 세 번.
    Sfx.wood =>
      (PcmSynth(durationSec: .45)
            ..noise(.12, 1900, 700, vol: .26, q: 2, seed: 5)
            ..noise(.1, 1500, 500, vol: .2, q: 2, seed: 6, delay: .07)
            ..noise(.14, 1100, 300, vol: .16, q: 1.6, seed: 7, delay: .15)
            ..tone(210, 110, .14, wave: Wave.square, vol: .04))
          .toWav(gain: masterGain),
    // 물보라: 넓은 쏴아 + 높은 튐.
    Sfx.splash =>
      (PcmSynth(durationSec: .75)
            ..noise(.7, 1300, 260, vol: .24, q: .8, seed: 8)
            ..noise(.3, 3200, 1500, vol: .08, q: 1.4, seed: 9, delay: .04))
          .toWav(gain: masterGain),
    // 철판 튕김: 어긋난 배음의 쨍 + 딸깍.
    Sfx.clang =>
      (PcmSynth(durationSec: .6)
            ..tone(830, 790, .55, vol: .12)
            ..tone(1337, 1310, .45, vol: .08)
            ..tone(2113, 2090, .3, vol: .05)
            ..noise(.04, 5000, 3000, seed: 10))
          .toWav(gain: masterGain),
  };
}
