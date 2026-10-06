/// 히트스톱과 슬로모션 (설계서 §10.4, A32): 연출 시계만 멈추거나 느리게 한다. 렌더만
/// 바뀌고 시뮬레이션 진행·턴 타이머는 그대로 흐른다(판정 틱은 그대로).
class HitStop {
  /// 히트스톱 사이 최소 간격(초): 연사탄이 화면을 계속 멈추지 않게 한다. 더 큰 한
  /// 방이면 간격 안이어도 다시 멈춘다.
  static const double gap = 0.3;

  /// 슬로모션 동안 연출 시계 배율.
  static const double slowScale = 0.3;

  double _left = 0;
  double _since = gap;
  double _last = 0;
  bool _heavy = false;
  double _slowLeft = 0;

  /// 명중했다: 한 방 크기에 비례한 [sec](0.05~0.16초) 동안 멈춘다. [heavy] 면 멈춘
  /// 동안 화면이 떨린다.
  void trigger(double sec, {bool heavy = false}) {
    if (_since < gap && sec <= _last) return;
    _left = sec > _left ? sec : _left;
    _last = sec;
    _heavy = heavy;
    _since = 0;
  }

  /// 격침·선실 직격 같은 결정적인 순간: [sec] 동안 연출을 [slowScale] 배로 느리게 한다
  /// (감정 연출). 멈춤이 끝난 뒤부터 느려진다.
  void slow(double sec) => _slowLeft = sec > _slowLeft ? sec : _slowLeft;

  /// 묵직한 한 방으로 멈춰 있는 중인가: 이때는 흔들림 시계만 흐른다.
  bool get trembling => _left > 0 && _heavy;

  /// 슬로모션 중인가.
  bool get slowing => _slowLeft > 0;

  /// 멈춤·슬로모션을 뺀 연출용 dt. 멈춘 동안에는 0 이다.
  double visualDt(double dt) {
    _since += dt;
    if (_left > 0) {
      _left -= dt;
      return 0;
    }
    if (_slowLeft > 0) {
      _slowLeft -= dt;
      return dt * slowScale;
    }
    return dt;
  }
}
