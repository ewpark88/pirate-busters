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
    // 유폭: 깊은 쿵 두 번 + 길게 우르릉 + 터지는 파열음.
    Sfx.boom =>
      (PcmSynth(durationSec: 1.4)
            ..tone(70, 26, 1.2, vol: .5)
            ..tone(110, 40, .5, wave: Wave.triangle, vol: .2, delay: .12)
            ..noise(1.3, 320, 40, vol: .38, q: .6, seed: 11)
            ..noise(.2, 3000, 800, vol: .2, seed: 12)
            ..noise(.5, 900, 150, vol: .18, q: .8, seed: 13, delay: .15))
          .toWav(gain: masterGain),
    // 격침: 낮게 꺼지는 신음 + 물이 차오르는 꾸르륵.
    Sfx.sink =>
      (PcmSynth(durationSec: 2.2)
            ..tone(140, 45, 2, wave: Wave.triangle, vol: .2)
            ..noise(2, 700, 120, vol: .22, q: .7, seed: 14)
            ..tone(520, 260, .12, vol: .06, delay: .5)
            ..tone(460, 230, .12, vol: .06, delay: .9)
            ..tone(400, 200, .12, vol: .05, delay: 1.3))
          .toWav(gain: masterGain),
    // 승리 악구: 솔-도-미-솔 올라가는 나팔.
    Sfx.win => _phrase(const [392, 523.25, 659.25, 783.99], .16, Wave.square),
    // 패배 악구: 내려가는 단조.
    Sfx.lose => _phrase(
      const [392, 349.23, 311.13, 261.63],
      .24,
      Wave.triangle,
    ),
    // 버튼 누름: 짧은 딸깍.
    Sfx.click =>
      (PcmSynth(durationSec: .08)
            ..tone(1400, 900, .05, wave: Wave.triangle, vol: .14)
            ..noise(.02, 4000, 2500, vol: .05, seed: 15))
          .toWav(gain: masterGain),
    // 착탄 쾅(작은): 짧은 쿵 + 파열음.
    Sfx.hit =>
      (PcmSynth(durationSec: .5)
            ..tone(120, 40, .4, vol: .4)
            ..noise(.35, 900, 120, vol: .3, q: .7, seed: 16))
          .toWav(gain: masterGain),
    // 착탄 쾅(큰): 깊은 쿵 + 긴 파열음.
    Sfx.hitBig =>
      (PcmSynth(durationSec: .9)
            ..tone(85, 28, .8, vol: .5)
            ..noise(.8, 600, 60, vol: .36, q: .6, seed: 17)
            ..noise(.12, 2600, 900, vol: .16, seed: 18))
          .toWav(gain: masterGain),
    // 잔향: 낮게 길게 우르릉.
    Sfx.rumble =>
      (PcmSynth(durationSec: 1.4)
            ..tone(48, 30, 1.3, wave: Wave.triangle, vol: .3)
            ..noise(1.3, 220, 40, vol: .26, q: .6, seed: 19))
          .toWav(gain: masterGain),
    // 붕괴 우지끈: 삐걱이다 쩍 갈라짐.
    Sfx.creak =>
      (PcmSynth(durationSec: .7)
            ..tone(180, 140, .35, wave: Wave.square, vol: .05)
            ..noise(.2, 1500, 400, vol: .24, q: 2, seed: 20, delay: .3))
          .toWav(gain: masterGain),
    // 해적 피격: 둔탁한 퍽.
    Sfx.pirateHit =>
      (PcmSynth(durationSec: .3)
            ..tone(160, 70, .2, vol: .3)
            ..noise(.08, 1200, 400, vol: .14, seed: 21))
          .toWav(gain: masterGain),
    // 바다 추락: 풍덩.
    Sfx.plunge =>
      (PcmSynth(durationSec: .8)
            ..tone(300, 90, .25, vol: .14)
            ..noise(.7, 1100, 200, vol: .26, q: .8, seed: 22, delay: .05))
          .toWav(gain: masterGain),
    // 쓰러짐: 띵 하고 울리는 종.
    Sfx.ko =>
      (PcmSynth(durationSec: .8)
            ..tone(660, 640, .7, vol: .12)
            ..tone(990, 960, .5, vol: .06))
          .toWav(gain: masterGain),
    // 내려오는 탄의 휘파람: 높은 음에서 미끄러져 내려온다.
    Sfx.whistle => (PcmSynth(
      durationSec: .9,
    )..tone(1700, 650, .85, vol: .07)).toWav(gain: masterGain),
  };

  /// 음 [hz] 를 [step] 초 간격으로 이어 부는 짧은 악구. 마지막 음은 길게 끈다.
  static Uint8List _phrase(List<double> hz, double step, Wave wave) {
    final synth = PcmSynth(durationSec: step * hz.length + .5);
    for (final (i, f) in hz.indexed) {
      final last = i == hz.length - 1;
      synth
        ..tone(
          f,
          f,
          last ? .6 : step * 1.1,
          wave: wave,
          vol: .1,
          delay: i * step,
        )
        ..tone(f * 2, f * 2, last ? .4 : step, vol: .03, delay: i * step);
    }
    return synth.toWav(gain: masterGain);
  }
}
