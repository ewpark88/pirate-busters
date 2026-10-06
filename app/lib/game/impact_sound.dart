import 'package:pirate_busters/audio/sound_service.dart';
import 'package:pirate_busters/game/view/hit_weight.dart';

/// 착탄 소리 겹침 (설계서 §10.3, A32): 한 소리가 아니라 쾅 + 맞은 재질 + (묵직하면)
/// 잔향을 겹친다. 쾅은 한 방 크기에 따라 작은·큰 소리와 크기가 다르다.
List<(Sfx, double)> impactLayers(HitWeight weight, {required bool iron}) => [
  switch (weight.level) {
    HitLevel.light => (Sfx.hit, 0.7),
    HitLevel.medium => (Sfx.hit, 1.0),
    HitLevel.heavy => (Sfx.hitBig, 1.0),
  },
  if (iron) (Sfx.clang, 0.8) else (Sfx.wood, 0.6),
  if (weight.isHeavy) (Sfx.rumble, 0.8),
];

/// 한 프레임의 효과음 묶음 (설계서 §10.3, A32): 같은 순간 같은 소리는 하나만 내고,
/// 크기 합에 상한을 둬 여러 소리가 겹쳐도 귀가 아프지 않게 한다. 렌더 전용.
class SfxMixer {
  /// 한 프레임에 낼 수 있는 크기 합.
  static const double frameBudget = 2.4;

  final Set<Sfx> _played = {};
  double _sum = 0;

  /// 새 프레임을 시작한다.
  void beginFrame() {
    _played.clear();
    _sum = 0;
  }

  /// [sfx] 를 [volume] 으로 낼 수 있으면 실제로 낼 크기를, 못 내면 null 을 준다.
  double? admit(Sfx sfx, double volume) {
    if (!_played.add(sfx)) return null;
    final left = frameBudget - _sum;
    if (left <= 0.05) return null;
    final v = volume < left ? volume : left;
    _sum += v;
    return v;
  }
}

/// 내려오는 탄의 휘파람 (설계서 §10.3, A32): 탄이 해수면보다 [minHeight] 이상 높이
/// 올랐다가 꼭대기를 지나 내려오기 시작하면 한 번 알린다. 탄마다 한 번이다.
class WhistleCue {
  /// 휘파람을 낼 최소 높이(월드 px, 약 4칸). 낮게 깔린 직사는 내지 않는다.
  static const double minHeight = 128;

  double? _lastY;
  bool _done = false;

  /// 이번 프레임 탄의 높이 [y](월드 px, 위가 −). 탄이 없으면 null.
  /// 휘파람을 낼 때 true.
  bool update(double? y) {
    final last = _lastY;
    _lastY = y;
    if (y == null) {
      _done = false;
      return false;
    }
    if (_done || last == null) return false;
    // 월드 y 는 위가 음수다: 커지기 시작하면 내려오는 중이다.
    if (y > last && last <= -minHeight) {
      _done = true;
      return true;
    }
    return false;
  }
}
