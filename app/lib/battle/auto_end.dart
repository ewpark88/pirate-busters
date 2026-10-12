import 'package:pb_sim/pb_sim.dart';

/// 사람 턴을 자동으로 끝내는 시계 (설계서 §2.2, ADR-042·102). 턴 종료 커맨드는
/// 세션이 낸다.
///
/// - 2발을 다 쏘거나, 한 발 쏜 뒤 더 쏠 해적이 없으면 짧은 유예 뒤 끝낸다. 설정에서
///   끌 수 있다([enabled]).
/// - 턴 시작부터 쏠 해적이 하나도 없으면 안내([noShooter])를 띄우고 설정과 상관없이
///   넘긴다. 이동할 수 있으면 이동 유예, 못 하면 짧은 유예 뒤다.
///
/// 이동 버튼을 누르는 동안은 세지 않는다.
class AutoEndClock {
  /// 자동 종료 유예(밀리초, BALANCE A2.3, ADR-080).
  static const int graceMs = 1000;

  /// 쏠 해적이 없을 때 이동할 수 있으면 주는 유예(밀리초, BALANCE A2.3, ADR-102).
  static const int moveGraceMs = 3000;

  bool enabled = true;
  int _ms = 0;
  int _idleMs = 0;

  /// 이번 턴은 시작부터 쏠 해적이 없다. 안내 배너가 본다.
  bool noShooter = false;

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

  /// 사람 턴 한 프레임: [state] 의 지금 진영을 보고 턴을 끝낼 때면 true.
  /// [canMove] 는 연료·묶임·구간 끝까지 본 이동 가능 여부다.
  bool due(
    int dtMs,
    MatchState state, {
    required bool held,
    required bool canMove,
  }) {
    final fired = state.firesThisTurn;
    final stuck =
        fired < state.rules.firesPerTurn &&
        !state.sides[state.activeSide].anyCanFire;
    if (stuck && fired == 0) {
      noShooter = true;
      if (held) return false;
      _idleMs += dtMs;
      return _idleMs >= (canMove ? moveGraceMs : graceMs);
    }
    final done = fired >= state.rules.firesPerTurn || stuck;
    return tick(dtMs, done: done, held: held);
  }

  void reset() {
    _ms = 0;
    _idleMs = 0;
    noShooter = false;
  }
}
