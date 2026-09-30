import 'package:flutter/foundation.dart';
import 'package:pirate_busters/input/pull_aim.dart';

/// 판정에 들어가지 않는 화면 쪽 상태: 조준 중인 값, 이동 버튼, 고른 해적.
/// `BattleSession` 이 섞어 쓴다.
mixin SessionUiState on ChangeNotifier {
  /// 사람이 두는 진영.
  Set<int> get humanSides;

  /// 지금 턴이 사람 차례인가.
  bool get isHumanTurn;

  /// 지금 턴 진영.
  int get activeSide;

  /// [slot] 해적을 지금 쏠 수 있는가.
  bool canFire(int slot);

  /// 조준 중인 해적 슬롯과 값. 궤적 미리보기·자동 줌아웃에 쓴다.
  ({int slot, AimShot shot, double stretch})? aim;

  /// 이동 버튼을 누르고 있다. 그동안은 쏠 수 없다 (ADR-027).
  bool moveHeld = false;

  /// 이동 버튼을 누르고 있는 동안 갈 수 있는 끝(1/10칸, 전진 +). 끝 지점 점선용.
  int movePreviewDx = 0;

  void setAim(int slot, AimShot shot, double stretch) {
    if (!canFire(slot)) return;
    aim = (slot: slot, shot: shot, stretch: stretch);
    notifyListeners();
  }

  void clearAim() {
    aim = null;
    notifyListeners();
  }

  void setMovePreview(int dx) {
    movePreviewDx = dx;
    notifyListeners();
  }

  /// 카드로 고른 해적 슬롯 (설계서 §2.2, §13.4, ADR-033). 카메라가 그 해적으로
  /// 줌인한다. 상대 턴에 고르면 다음 내 턴까지 남는다. 쏘거나, 같은 카드를 다시
  /// 누르거나, 빈 바다를 누르거나, 그 진영의 턴이 끝나면 풀린다.
  int? selected;

  /// [selected] 가 어느 진영의 해적인가.
  int selectedSide = 0;

  /// 조작하는 사람 진영: 사람 턴이면 지금 턴 진영, 아니면 사람 쪽.
  int get viewerSide => isHumanTurn ? activeSide : humanSides.first;

  /// [slot] 을 고른다. [toggle] 이면 이미 고른 해적을 다시 고를 때 푼다(카드).
  void select(int? slot, {bool toggle = true}) {
    final side = viewerSide;
    final same = selected == slot && selectedSide == side;
    selected = toggle && same ? null : slot;
    selectedSide = side;
    notifyListeners();
  }

  /// 지금 줌인해야 할 해적: 내 턴이고 고른 해적이 이번 턴 진영이면 그 슬롯.
  int? get focusSlot =>
      isHumanTurn && selected != null && selectedSide == activeSide
      ? selected
      : null;
}
