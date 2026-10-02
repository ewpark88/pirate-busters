import 'dart:math' as math;
import 'dart:typed_data';

import 'package:pirate_busters/audio/pcm_synth.dart';
import 'package:pirate_busters/audio/sound_service.dart';

/// 배경음악 코드 합성 (설계서 §10.3, ADR-068). 저작권이 끝난 민요 선율을 효과음과
/// 같은 [PcmSynth] 로 짧은 루프로 만든다. 만든 소리는 프로젝트 저작물(CC0)이다.
///
/// - 항구: *Sailor's Hornpipe* (영국 민요, 18세기) 느린 편곡, 삼각파.
/// - 전투: *Drunken Sailor* (선원 민요, 19세기 기록) 빠른 편곡, 사각파 + 북.
abstract final class ShantyMusic {
  /// 모든 곡 WAV.
  static Map<Music, Uint8List> build() => {
    for (final m in Music.values) m: wav(m),
  };

  static Uint8List wav(Music m) => switch (m) {
    Music.port => _render(
      _hornpipe,
      beat: .2,
      lead: Wave.triangle,
      drums: false,
    ),
    Music.battle => _render(
      _drunkenSailor,
      beat: .15,
      lead: Wave.square,
      drums: true,
    ),
  };

  /// 선율: (MIDI 음 번호, 8분음표 수). 0 은 쉼표. 마디마다 베이스 음을 붙인다.
  static const List<(int, int)> _drunkenSailor = [
    // What shall we do with a drunk-en sai-lor (D 도리안)
    (69, 2), (69, 1), (69, 1), (69, 2), (69, 1), (69, 1),
    (69, 2), (62, 2), (65, 2), (69, 2),
    (67, 2), (67, 1), (67, 1), (67, 2), (67, 1), (67, 1),
    (67, 2), (60, 2), (64, 2), (67, 2),
    (69, 2), (69, 1), (69, 1), (69, 2), (69, 1), (69, 1),
    (69, 2), (71, 2), (72, 2), (74, 2),
    (72, 2), (69, 2), (67, 2), (64, 2), (62, 4), (0, 4),
  ];

  static const List<(int, int)> _hornpipe = [
    // Sailor's Hornpipe 첫 가락 (D 장조)
    (74, 1), (73, 1), (74, 1), (69, 1), (66, 1), (69, 1), (62, 1), (66, 1),
    (69, 1), (74, 1), (78, 1), (81, 1), (79, 1), (78, 1), (76, 1), (74, 1),
    (73, 1), (71, 1), (73, 1), (69, 1), (64, 1), (69, 1), (61, 1), (64, 1),
    (69, 1), (73, 1), (76, 1), (79, 1), (78, 1), (76, 1), (74, 1), (73, 1),
    (74, 1), (73, 1), (74, 1), (69, 1), (66, 1), (69, 1), (62, 1), (66, 1),
    (67, 1), (71, 1), (74, 1), (79, 1), (78, 1), (76, 1), (74, 1), (71, 1),
    (69, 1), (73, 1), (76, 1), (73, 1), (74, 2), (62, 2),
    (74, 4), (0, 4),
  ];

  static double _hz(int midi) => 440 * math.pow(2, (midi - 69) / 12).toDouble();

  /// 선율을 [beat] 초(8분음표) 박자로 그린다. 네 박(8분음표 8개)마다 베이스를 친다.
  static Uint8List _render(
    List<(int, int)> tune, {
    required double beat,
    required Wave lead,
    required bool drums,
  }) {
    final eighths = tune.fold<int>(0, (a, n) => a + n.$2);
    final synth = PcmSynth(durationSec: eighths * beat);
    var at = 0;
    for (final (note, len) in tune) {
      if (note > 0) {
        final f = _hz(note);
        synth.tone(
          f,
          f,
          len * beat * .95,
          wave: lead,
          vol: .07,
          delay: at * beat,
        );
      }
      at += len;
    }
    for (var bar = 0; bar * 8 < eighths; bar++) {
      final start = bar * 8;
      // 마디 첫 음보다 두 옥타브 아래를 베이스로 (선율을 따라 화음이 바뀐다).
      final barNote = _noteAt(tune, start) ?? 62;
      final bass = _hz(barNote - 24);
      for (final off in [0, 4]) {
        if (start + off >= eighths) break;
        synth.tone(
          bass,
          bass,
          beat * 3.5,
          wave: Wave.triangle,
          vol: .08,
          delay: (start + off) * beat,
        );
      }
      if (!drums) continue;
      for (var i = 0; i < 8 && start + i < eighths; i += 2) {
        synth.noise(
          beat * .6,
          i.isEven && i % 4 == 0 ? 180 : 2600,
          i % 4 == 0 ? 60 : 1800,
          vol: i % 4 == 0 ? .16 : .05,
          seed: 20 + i,
          delay: (start + i) * beat,
        );
      }
    }
    return synth.toWav(gain: 1.6);
  }

  /// 8분음표 [index] 자리에서 울리는 선율 음. 쉼표면 null.
  static int? _noteAt(List<(int, int)> tune, int index) {
    var at = 0;
    for (final (note, len) in tune) {
      if (index < at + len) return note > 0 ? note : null;
      at += len;
    }
    return null;
  }
}
