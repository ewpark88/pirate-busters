// mozzi lib/core/audio/pcm_synth.dart 에서 가져와 고쳤다 (ADR-004): 노이즈 난수를
// dart:math Random(시드)로 바꾸고 noise 에 delay 를 더했다. 렌더 전용(판정 무관).
import 'dart:math' as math;
import 'dart:typed_data';

/// 파형 (샘플 WebAudio OscillatorNode.type).
enum Wave { sine, triangle, square, sawtooth }

/// 효과음 코드 합성 (설계서 §10.3, 개발 계획서 M4). 파일 에셋 없이 WAV 를 만든다.
///
/// 노이즈는 시드 고정 난수라 같은 파라미터면 같은 바이트가 나온다 (테스트 가능).
class PcmSynth {
  PcmSynth({required double durationSec, this.sampleRate = defaultRate})
    : _buf = Float64List((durationSec * sampleRate).ceil());

  static const int defaultRate = 22050;

  /// 엔벌로프 최소값 (WebAudio exponentialRamp 의 0.0001).
  static const double _floor = 0.0001;
  static const double _attackSec = 0.01;

  final int sampleRate;
  final Float64List _buf;

  int get length => _buf.length;

  /// 주파수가 [f0]→[f1] 로 지수 변화하는 음. 10ms 에 [vol] 까지 오르고 [dur] 끝에 사라진다.
  void tone(
    double f0,
    double f1,
    double dur, {
    Wave wave = Wave.sine,
    double vol = .15,
    double delay = 0,
  }) {
    final start = (delay * sampleRate).round();
    final n = (dur * sampleRate).round();
    final end = math.max(f1, 20);
    var phase = 0.0;
    for (var i = 0; i < n && start + i < _buf.length; i++) {
      final t = i / sampleRate;
      final f = f0 * math.pow(end / f0, t / dur);
      phase += f / sampleRate;
      _buf[start + i] += _osc(wave, phase) * _envelope(t, dur, vol);
    }
  }

  /// 대역통과 노이즈: 중심 주파수 [f0]→[f1] 지수 변화, 음량은 [vol] 에서 사라짐.
  /// [delay] 초 뒤에 시작한다.
  void noise(
    double dur,
    double f0,
    double f1, {
    double vol = .12,
    double q = 1.2,
    int seed = 1,
    double delay = 0,
  }) {
    final rng = math.Random(seed);
    final start = (delay * sampleRate).round();
    final n = (dur * sampleRate).round();
    final bp = _Biquad();
    for (var i = 0; i < n && start + i < _buf.length; i++) {
      final t = i / sampleRate;
      bp.bandpass(f0 * math.pow(f1 / f0, t / dur), q, sampleRate);
      final x = rng.nextDouble() * 2 - 1;
      final g = vol * math.pow(_floor / vol, t / dur);
      _buf[start + i] += bp.process(x) * g;
    }
  }

  /// 16bit PCM 모노 WAV 파일 바이트. [gain] 을 곱하고 −1~1 로 자른다.
  Uint8List toWav({double gain = 1}) {
    final data = ByteData(44 + _buf.length * 2);
    void str(int at, String s) {
      for (var i = 0; i < s.length; i++) {
        data.setUint8(at + i, s.codeUnitAt(i));
      }
    }

    str(0, 'RIFF');
    data.setUint32(4, 36 + _buf.length * 2, Endian.little);
    str(8, 'WAVE');
    str(12, 'fmt ');
    data
      ..setUint32(16, 16, Endian.little)
      ..setUint16(20, 1, Endian.little) // PCM
      ..setUint16(22, 1, Endian.little) // 모노
      ..setUint32(24, sampleRate, Endian.little)
      ..setUint32(28, sampleRate * 2, Endian.little)
      ..setUint16(32, 2, Endian.little)
      ..setUint16(34, 16, Endian.little);
    str(36, 'data');
    data.setUint32(40, _buf.length * 2, Endian.little);
    for (var i = 0; i < _buf.length; i++) {
      final v = (_buf[i] * gain).clamp(-1.0, 1.0);
      data.setInt16(44 + i * 2, (v * 32767).round(), Endian.little);
    }
    return data.buffer.asUint8List();
  }

  /// 가장 큰 진폭 (테스트용).
  double get peak => _buf.fold(0, (m, v) => math.max(m, v.abs()));

  static double _envelope(double t, double dur, double vol) {
    if (t < _attackSec) return _floor * math.pow(vol / _floor, t / _attackSec);
    final rest = math.max(1e-6, dur - _attackSec);
    return vol * math.pow(_floor / vol, (t - _attackSec) / rest);
  }

  static double _osc(Wave w, double phase) {
    final p = phase - phase.floorToDouble();
    return switch (w) {
      Wave.sine => math.sin(2 * math.pi * p),
      Wave.triangle => 1 - 4 * (p - .5).abs(),
      Wave.square => p < .5 ? 1 : -1,
      Wave.sawtooth => 2 * p - 1,
    };
  }
}

/// 2차 IIR 필터 (RBJ 쿡북).
class _Biquad {
  double _b0 = 1;
  double _b1 = 0;
  double _b2 = 0;
  double _a1 = 0;
  double _a2 = 0;
  double _x1 = 0;
  double _x2 = 0;
  double _y1 = 0;
  double _y2 = 0;

  void bandpass(double f, double q, int rate) {
    final w = 2 * math.pi * f / rate;
    final alpha = math.sin(w) / (2 * q);
    final a0 = 1 + alpha;
    _b0 = alpha / a0;
    _b1 = 0;
    _b2 = -alpha / a0;
    _a1 = -2 * math.cos(w) / a0;
    _a2 = (1 - alpha) / a0;
  }

  double process(double x) {
    final y = _b0 * x + _b1 * _x1 + _b2 * _x2 - _a1 * _y1 - _a2 * _y2;
    _x2 = _x1;
    _x1 = x;
    _y2 = _y1;
    _y1 = y;
    return y;
  }
}
