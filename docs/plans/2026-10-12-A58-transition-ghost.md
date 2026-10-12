# 화면 전환 잔상 다시 잡기 (A42 후속)

## Context
A42 에서 `KitPageTransitions` 를 fade-through(이전 화면이 먼저 사라지고 새 화면이 뒤에 나타남)로 바꿨지만 사용자가 실기기에서 아직 잔상을 본다. 코드를 따라가 보니 fade-through 가 **작동하지 않는 경로**와 **겹쳐 보이는 틈**이 남아 있다.

1. **`fullscreenDialog: true` 경로 (확인된 원인).** Flutter 3.44 `MaterialRouteTransitionMixin.canTransitionTo` 는 다음 화면이 fullscreenDialog 면 `false` 를 돌려준다(`material/page.dart:162`). 그러면 아래 화면의 `secondaryAnimation` 이 움직이지 않아 `outgoing()` 이 늘 1 → 이전 화면이 100% 그대로 보이는 위에 새 화면이 투명에서 나타나 두 화면이 겹친다. 닫을 때도 같다.
   - `app/lib/story/cutscene_screen.dart:39` `CutsceneScreen.show` (프롤로그: 항구 → 컷신 → 항구)
   - `app/lib/campaign/stage_flow.dart:107` 보스 뒤 컷신(전투 → 컷신 pushReplacement)
2. **컷 사이 크로스페이드.** `cutscene_screen.dart:77` `AnimatedSwitcher` 기본 전환은 두 컷을 같이 진하게 겹쳐 그린다(자막·인물이 겹친 잔상). 설계서 §15.4 "컷 전환은 0.3초 페이드"는 지키고 겹침만 없앤다.
3. **전환 가운데 빈 틈.** 두 화면이 다 옅어지는 순간 아무것도 안 그린 자리에 Android 창 바탕(`NormalTheme` = `?android:colorBackground`, 라이트 모드면 흰색)이 비친다. 앱 바탕색을 루트에 깔아 막는다. 또 `inFrom 0.35 < outUntil 0.4` 로 0.05 구간이 겹치므로 같은 값으로 맞춘다.

렌더 전용, 설계서·BALANCE.md 는 바꾸지 않는다. 끝난 A42 코드를 다시 고치므로 계획서 12장 끝에 새 `A<n>` 단계(구현 때 비어 있는 다음 번호, A54~A57 은 다른 세션이 써서 A58)로 넣는다(절대 규칙 11).

## 변경
- `app/lib/story/cutscene_screen.dart`
  - `show()` 의 `fullscreenDialog: true` 제거(앱바가 없어 닫기 아이콘 차이도 없음, 건너뛰기 버튼은 그대로).
  - `AnimatedSwitcher` 에 fade-through 전환: `transitionBuilder` 로 나가는 컷은 앞 절반에 사라지고 들어오는 컷은 뒤 절반에 나타나게(`KitPageTransitions.incoming/outgoing` 과 같은 방식). `layoutBuilder` 는 기본 Stack 유지. 저사양(`KitMotion.reducedOf`)이면 바로 바뀐다.
- `app/lib/campaign/stage_flow.dart:107` `fullscreenDialog: true` 제거.
- `app/lib/ui/kit/kit_motion.dart`: `inFrom` 을 `outUntil`(0.4)과 같게 해 겹침 0 — 한 상수로 묶는다(`split`). 주석에 "fullscreenDialog 경로는 이전 화면이 안 사라지므로 쓰지 않는다" 한 줄.
- `app/lib/app/app.dart` `builder`: 맨 바깥에 `ColoredBox(color: AppColors.background)` 를 깔아 전환 틈에 창 바탕이 비치지 않게.
- (선택, 같은 이유) `android/app/src/main/res/values*/styles.xml` `NormalTheme` 창 바탕을 앱 바탕색으로 — ColoredBox 로 충분하면 생략.

## 테스트 (`app/test/screen_fit_test.dart` 의 A42 묶음에 추가)
- `incoming(t) * outgoing(t) == 0` (모든 t) 로 강화.
- 위젯 테스트: 항구 대신 간단한 두 화면 앱(`appTheme()` + `KitMotion(reduced:false)`)에서 `CutsceneScreen.show` 로 열 때 전환 중간 프레임에 아래 화면의 `Opacity` 가 1 보다 작아진다(이전 화면이 사라진다) — `pump(전환 시간 × 0.5)` 뒤 아래 화면 조상 `Opacity.opacity` 확인.
- 위젯 테스트: 컷을 넘길 때 중간 프레임에 두 컷 진하기 합이 겹치지 않는다(둘 다 0.05 넘게 보이는 순간 없음).
- 앱 전체 `grep fullscreenDialog` 가 0 이 되게(다른 화면에 다시 생기지 않게 테스트 대신 주석으로 남김).

## 문서
- 계획서 12장 끝에 `A58 화면 전환 잔상 2차` 단계(작업·완료 조건, 실기기 확인 남음). 계획서 해시는 그대로(설계서 미변경).
- `docs/PROGRESS.md`, `docs/STATUS.md`, `CHANGELOG.md [Unreleased]` 수정 항목 한 줄, ADR 은 규칙 변경이 아니라 생략(A42 ADR-093 후속으로 PROGRESS 에 적음).

## 진행·커밋 (공유 작업 트리 규칙)
- 다른 세션 미커밋 파일이 많다: checkout 하지 않고 `git branch feat/A58-transition-ghost` 만 만든 뒤, 내 경로만 add, 공유 문서는 내 블록만 인덱스에 올려 커밋. main 병합은 `git commit-tree` + `update-ref`, push 는 백그라운드(ADR-098).

## 검증
- `(cd app && flutter test test/screen_fit_test.dart)` → `bash tool/verify.sh` 통과.
- 사람 확인(보고에 적음): 갤럭시 S24 에서 처음 실행 프롤로그 열기·닫기, 보스 승리 뒤 컷신, 항구↔지도↔전투↔결과 전환, 라이트 모드 기기에서 흰 번쩍임 없음. 이 경로 밖(예: 특정 화면)에서 잔상이 남으면 어느 화면인지 알려 달라고 한다.
