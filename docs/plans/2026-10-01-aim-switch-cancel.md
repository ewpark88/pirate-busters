# 조준 중 해적 바꾸기: 손가락을 되돌리면 취소되고, 화면에 표시한다

## 배경
- 배 위 해적을 끌어 조준하기 시작하면(`app/lib/input/field_gestures.dart` `_onStart`) 그 해적이 `_slot` 으로 고정되고, 놓으면 바로 발사된다.
- 취소하는 방법은 하나뿐이다. 누른 자리 근처로 되돌려 힘을 `PullAim.minPower` 아래로 낮춘 뒤 놓으면 `release()` 가 null 을 돌려준다(`app/lib/input/pull_aim.dart`). 그런데 화면에 아무 표시가 없어서 사용자는 이 방법을 모른다. 그래서 "마음이 바뀌어도 해적을 바꿀 수 없다"고 느낀다.
- 사용자가 고른 방식: **되돌리면 취소 표시.** 한 번 충분히 당긴 뒤 다시 되돌리면 궤적을 숨기고 '놓으면 취소' 안내를 띄운다. 그 상태로 놓으면 쏘지 않고, 다른 해적을 골라 다시 끌 수 있다.
- 사용자 결정: 현재 브랜치에서 바로 고친다. 설계서는 문구 추가만 제안한다(직접 고치지 않음).

## 변경

### 1. `app/lib/input/pull_aim.dart`
- `bool _armed`: 한 번이라도 힘이 `minPower` 이상이 되면 true. `start()` 에서 false 로 되돌린다.
- `bool get isCancelling => _armed && shot.power < minPower`: 당겼다가 되돌린 상태.
- `bool get isWeak => shot.power < minPower`: 놓아도 쏘지 않는 상태(궤적을 숨길 때 쓴다).
- 이미 있는 `release()` 의 취소 판정(`minPower`)은 그대로 둔다.

### 2. `app/lib/battle/ui_state.dart`
- `aim` 레코드에 `bool cancelling` 을 더한다. `setAim(slot, shot, stretch, {cancelling})` 로 받는다.
- 위젯·컴포넌트는 이 값을 읽어 그리기만 한다(절대 규칙 3).

### 3. `app/lib/input/field_gestures.dart`
- `_onUpdate` 에서 `_s.setAim(_slot, aim.shot, aim.stretch, cancelling: aim.isCancelling)` 으로 넘긴다.
- 발사·취소 흐름은 그대로 둔다. 놓을 때 `release()` 가 null 이면 이미 `clearAim()` 을 부른다. 고른 해적(`selected`)은 남겨서, 같은 해적을 바로 다시 끌 수도 있고 다른 해적이나 카드를 누를 수도 있다.

### 4. `app/lib/game/view/shot_view.dart` `_renderAim`
- 힘이 `PullAim.minPower` 미만이면(`aim.shot.power < PullAim.minPower`) 궤적 점선과 사거리 끝 표시를 그리지 않는다. 쏘지 않을 조준을 보여주지 않기 위해서다.

### 5. `app/lib/ui/hud/battle_hud.dart`
- `session.aim?.cancelling == true` 이면 `_awaitingTap` 안내와 같은 모양(`Align` + `IgnorePointer` + `HudPanel`)으로 `l10n.aimCancel` 을 띄운다.
- 파일이 300줄을 넘으면 `ui/hud/aim_cancel_hint.dart` 로 분리한다.

### 6. l10n: `app/lib/l10n/app_ko.arb`·`app_en.arb` (같은 커밋, 절대 규칙 10)
- `aimCancel`: "놓으면 취소" / "Release to cancel"
- `flutter gen-l10n`(또는 빌드)으로 `app_localizations*.dart` 를 다시 만든다.

### 7. 테스트 (테스트 이름은 한국어 문장)
- `app/test/pull_aim_test.dart`
  - 당긴 적이 없으면 취소 중이 아니다.
  - 충분히 당겼다가 되돌리면 취소 중이고, 놓으면 null 이다.
  - 다시 당기면 취소 중이 풀린다.
- 가능하면 `SessionUiState.setAim` 이 `cancelling` 을 보존하는지 확인하는 테스트도 더한다(기존 세션 테스트 패턴이 있으면 따른다).

### 8. 문서
- `docs/DECISIONS.md` 에 짧은 ADR 을 남긴다. 내용: 조준 취소를 눈에 보이게 하고, 현재 브랜치에서 UX 버그 수정으로 처리한다.
- `CHANGELOG.md` `[Unreleased]` 에 한 줄 적는다.
- **설계서 수정 제안(사용자 승인 필요, 직접 고치지 않음):**
  - §2.2 3번 뒤에 "누른 자리 가까이 되돌리면 '놓으면 취소'가 뜨고, 놓아도 쏘지 않는다. 다른 해적을 다시 고를 수 있다."
  - §13.4 '조준' 줄에도 같은 취지를 한 구절 추가.
  - 승인되면 `/doc-sync` 절차로 계획서 해시를 갱신한다.

## 주의
- 이 폴더는 다른 세션과 공유한다. 커밋할 때 `git add -A` 를 쓰지 않고 위 파일만 담는다. 커밋은 사용자가 요청할 때만 한다.

## 검증
1. `(cd app && flutter test test/pull_aim_test.dart)`
2. `bash tool/verify.sh` 통과(format·analyze·l10n·300줄·test).
3. `(cd app && flutter run)` 으로 수동 확인:
   - 해적을 당긴다 → 궤적이 보인다.
   - 누른 자리로 되돌린다 → 궤적이 사라지고 '놓으면 취소'가 뜬다.
   - 놓는다 → 쏘지 않는다.
   - 다른 해적 카드를 누르거나 배 위 다른 해적을 끈다 → 그 해적으로 조준하고 쏠 수 있다.
