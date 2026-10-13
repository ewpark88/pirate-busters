import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

/// 바람 소리 (설계서 §2.4 “바람이 셀수록 바람 소리가 커진다”, §10.3): 바람 루프 하나 (합성 4초, `SfxBank.windLoop`). 환경음이 켜져 있을 때만 들리고,
/// 단계가 바뀌면 [fade] 에 걸쳐 음량을 옮긴다.
class WindLoop {
  WindLoop(this._soloud);

  final SoLoud _soloud;
  AudioSource? _src;
  SoundHandle? _handle;
  bool _on = false;
  int _level = 0;

  /// 단계별 음량 (0·1·2·3단계). 환경음(0.18)보다 작다.
  static const List<double> volumes = [0, .05, .10, .16];
  static const Duration fade = Duration(milliseconds: 800);

  /// 단계 [level] 의 음량.
  static double volumeFor(int level) => volumes[level.abs().clamp(0, 3)];

  Future<void> load(Uint8List wav) async {
    try {
      if (!_soloud.isInitialized) await _soloud.init();
      _src = await _soloud.loadMem('wind_loop.wav', wav);
    } on Object catch (e) {
      debugPrint('바람 소리 초기화 실패: $e');
    }
  }

  /// 환경음 켜기·끄기를 따른다.
  bool get on => _on;
  set on(bool v) {
    _on = v;
    _apply();
  }

  int get level => _level;
  set level(int v) {
    _level = v;
    _apply();
  }

  void _apply() {
    final h = _handle;
    final volume = _on ? volumeFor(_level) : 0.0;
    if (volume == 0) {
      if (h != null) {
        _soloud
          ..fadeVolume(h, 0, fade)
          ..scheduleStop(h, fade);
      }
      _handle = null;
      return;
    }
    final src = _src;
    if (src == null) return;
    final handle = h ?? _soloud.play(src, volume: 0, looping: true);
    _handle = handle;
    _soloud.fadeVolume(handle, volume, fade);
  }
}
