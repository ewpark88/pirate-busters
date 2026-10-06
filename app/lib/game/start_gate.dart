/// 전투 시작 문 (A33, 플레이 점검 버그 6): 전장 그림이 처음 그려지는 동안(웹은
/// 그림 준비로 첫 몇 초가 느리다) 판 시계를 세워 둔다. 프레임이 [steadyFrames] 번
/// 이어서 [steadyDt] 초 안에 나오면 열린다. 느린 기기에서도 [maxWaitSec] 뒤에는 연다.
class StartGate {
  static const int steadyFrames = 3;
  static const double steadyDt = 0.05;
  static const double maxWaitSec = 8;

  int _steady = 0;
  double _waited = 0;
  bool _open = false;

  bool get isOpen => _open;

  /// 한 프레임([dt] 초)을 지나고, 판 시계를 돌려도 되면 true.
  bool tick(double dt) {
    if (_open) return true;
    _waited += dt;
    _steady = dt <= steadyDt ? _steady + 1 : 0;
    return _open = _steady >= steadyFrames || _waited >= maxWaitSec;
  }
}
