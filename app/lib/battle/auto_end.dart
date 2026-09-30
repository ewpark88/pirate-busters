/// 2발을 다 쏜 뒤 짧은 유예를 두고 턴을 자동으로 끝내는 시계 (설계서 §2.2,
/// ADR-042). 유예 동안 이동할 수 있고(이동 버튼을 누르는 동안은 세지 않는다),
/// 설정에서 끌 수 있다. 턴 종료 커맨드는 세션이 낸다.
class AutoEndClock {
  /// 자동 종료 유예(밀리초, 임시값 ADR-042).
  static const int graceMs = 1500;

  bool enabled = true;
  int _ms = 0;

  /// [dtMs] 만큼 흘렀다. 발사를 다 썼고([done]) 이동 중이 아니면([held] 아님)
  /// 세고, 유예가 지나면 true.
  bool tick(int dtMs, {required bool done, required bool held}) {
    if (!enabled || !done || held) {
      _ms = 0;
      return false;
    }
    _ms += dtMs;
    return _ms >= graceMs;
  }

  void reset() => _ms = 0;
}
