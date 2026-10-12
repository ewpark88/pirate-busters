import 'package:pb_sim/src/match/match_state.dart';

/// 진영이 지금 할 수 있는 행동 조회 (설계서 §2.2 쏠 해적 없음 자동 넘김, ADR-102).
/// 판정은 [SideState.canFire] 와 이동 규칙을 그대로 쓰고, 상태는 바꾸지 않는다.
extension SideActions on SideState {
  /// 쏠 수 있는 해적이 하나라도 있는가(쉬는 턴·이번 턴 발사·선실 잠김·봉쇄 제외).
  bool get anyCanFire {
    for (var slot = 0; slot < crew.size; slot++) {
      if (canFire(slot)) return true;
    }
    return false;
  }

  /// 연료가 남고 묶이지 않아 이동할 수 있는 상태인가 (설계서 §2.6·§2.7).
  /// 구간 끝에 닿아 한쪽으로 못 가는 경우는 보지 않는다.
  bool get canMove => fuel > 0 && !moveLocked;
}
