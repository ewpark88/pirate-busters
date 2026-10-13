# A62 상대(AI) 발사 사이 연출 간격·조준 해적 비추기


## Context
AI 턴에 첫 발사 연출이 끝나면 둘째 발사가 곧바로 나가서, 사용자는 어느 해적이 어떤 공격을 했는지 알아보기 어렵다.

원인 (`app/lib/battle/battle_session.dart`):
- `update()` 는 탄이 날아가는 동안에도 `turnMs` 를 계속 올린다(L109).
- `_playScript()` 가 다음 커맨드를 거르는 조건은 `c.t > turnMs` 하나뿐이다(L205).
- AI 묶음의 시각은 `pb_ai/lib/src/turn_choice.dart` `_commands()` 에서 `발사 시각 + thinkMs` 로 정해진다. 여기에는 비행 시간이 빠져 있다.
- 그래서 비행·파괴 연출(보통 2초 넘음)이 `thinkMs`(쉬움 2.5초 ~ 지옥 0.3초)보다 길면, 둘째 발사는 연출이 끝나는 바로 그 프레임에 나간다.
- `opponentAim` 도 `c.t - turnMs` 로 계산하므로 이미 음수가 되어 있다. 그래서 조준 링(`FoeAimMark`), 몸 젖힘(`leanOf`), “상대 조준 중” 배너(`FoeAlert`)가 한 프레임도 보이지 않는다.
- 카메라는 내 턴에만 해적을 비춘다(`focusSlot`). 두 배가 멀면 상대 해적이 화면 밖이다.

설계서 근거:
- §2.1: 착탄 뒤 카메라가 돌아오며, 상대 턴 재생도 같다.
- §2.3: 상대의 조준 과정을 그대로 보여준다.
- §5.5: 해적을 고르고 당기는 조준 동작을 생각 연출 시간(BALANCE A5.2) 동안 보여준다.

지금 코드는 이 셋을 지키지 못하고 있다. 이번 작업은 설계서를 고치는 일이 아니라 구현 버그를 고치는 일이다.

결과는 바뀌지 않는다. 엔진에는 커맨드의 원래 `c.t` 가 그대로 들어가므로 전투 결과·리플레이·해시는 그대로다. 손대는 곳은 앱의 재생 속도와 카메라뿐이다.

## 단계·브랜치
- 계획서 12장 끝에 **A62** 를 넣는다(A61 은 기뢰 연출). 브랜치는 `feat/A62-ai-shot-pacing`.
- 공유 작업 트리에는 다른 세션의 A61 변경(battle_cues 등)이 있다. 내 경로만 `git add` 한다.

## 구현

### 1. AI 재생 시계: `app/lib/battle/ai_script_player.dart` (새 파일)
`battle_session.dart` 가 이미 300줄이다. 그래서 AI 재생에 쓰는 상태(`_script`, `_planner`, `_scriptIndex`)와 `_playScript` 로직을 이 새 클래스로 옮긴다.

**`scriptMs`:** AI 묶음의 시각을 재는 시계다.
- 이 시계는 아래 두 조건이 모두 맞을 때만 흐른다.
  - `playback == null`
  - 쉼(`settleLeftMs`)이 끝났다
- 그래서 비행·파괴 연출과 그 뒤 쉼은 AI 의 “생각 시간”을 깎지 않는다.
- 다음 커맨드는 `c.t <= scriptMs` 일 때 낸다. 커맨드에 넣는 `t` 는 원래 `c.t` 그대로다.
- 턴 끝(`EndTurnCommand`)은 지금처럼 `turnMs` 로 낸다.

**`settleLeftMs`:** 탄 연출이 끝난 직후와 상대 턴이 시작될 때 건다. 이 동안 카메라가 착탄 지점에서 다음 조준 해적에게로 옮겨 간다.
- 상수는 `aiSettleMs` 이고 값은 카메라 `returnSec`(1.2초)에 맞춘다.
- 연출 상수라서 BALANCE.md 대상은 아니다. 카메라 상수처럼 앱 코드에 둔다.

**`opponentAim`:**
- 다음 커맨드가 FIRE 이고 연출이 없으면, 쉼 동안에도 `(slot, progress 0)` 을 돌려준다. 그래야 카메라가 먼저 그 해적으로 간다.
- 쉼이 끝나면 `progress` 는 `1 - (c.t - scriptMs) / aimShowMs` 다. 조준 창은 `max(aimShowMs, c.t - 직전 쉼이 끝난 시각)` 으로 잡아, 젖힘이 늘 0에서 1로 차오르게 한다.

**`turnMs`:** 지금처럼 계속 흐르게 둔다. 파도·돛·물결 그림이 이 시계를 쓰기 때문이다.

`BattleSession` 은 `update`·`_finishPlayback`·`_syncTurnClock` 에서 이 플레이어를 부르기만 한다. 세션 파일은 300줄 아래로 줄어든다.

### 2. 남은 시간 표시: `app/lib/battle/session_views.dart`
`remainingMs` 를 고친다.
- 상대 AI 턴에는 `턴 시간 − scriptMs` 를 보인다.
- 이렇게 해야 늘어난 연출 때문에 상단 타이머가 AI 턴 중에 0 이 되지 않는다.
- 사람 턴은 지금 그대로다.

### 3. 카메라가 조준 중인 상대 해적을 비춘다
**`app/lib/battle/ui_state.dart`:**
- `focusSlot` 을 넓혀, 상대 턴에는 `opponentAim?.slot` 을 돌려준다(해적이 배 위에 있을 때만).
- 대상 진영은 `activeSide` 다. 고칠 이름은 `focusSide` 이고, 내 턴에는 viewerSide 가 된다.

**`app/lib/game/battle_game.dart` L238:**
- `focusFeetOf(_ships[focusSide], session.focusSlot)` 로 고친다.
- 줌인 방향이 그 배를 따르도록 `director.focusFacing = facingOf(focusSide)` 를 넘긴다.

**`app/lib/game/camera_director.dart`:**
- `focusFacing` 필드를 더한다(없으면 `facing`).
- focus 분기(L244-256)에서 쓴다.

L286 의 `pirateScreen(...)` 은 내 턴 손가락 조준용이다. 내 턴에만 쓰이는지 확인하고 그대로 둔다.

### 4. 문서
- 계획서 12장 A62: 작업·완료 조건, 설계서 §2.1·§2.3·§5.5 와 BALANCE A5.2 참조.
- STATUS.md 숫자, CHANGELOG `[Unreleased]`, PROGRESS.md 를 고친다.
- 계획 변경이 작아 ADR 은 따로 쓰지 않는다. 다만 “AI 재생 시계는 연출 중 멈춘다”는 결정은 A62 항목에 적는다.

## 재사용
- `FoeAimMark`, `leanOf`, `FoeAlert`: `opponentAim` 이 제대로 나오면 그대로 쓴다.
- `focusFeetOf`(`app/lib/game/pirate_pick.dart`), `CameraDirector.focusFeet`.
- `AiDials.of(level).thinkMs` 를 쓰는 `aimShowMs`.

## 테스트 (`app/test/a62_ai_shot_pacing_test.dart`, 이름은 한국어 문장)
`a34_turn_tension_test.dart` 의 세션 구동 방식을 본뜬다.
- AI 가 두 발 이상 쏘는 턴에서 두 발사 사이(앞 연출 끝 → 다음 발사)가 `aiSettleMs + 그 발의 생각 간격` 이상이다.
- 각 발사 전에 `opponentAim` 이 그 발사 슬롯으로 보이고, `progress` 가 0 → 1 로 오른다(마지막 프레임에 1 근처).
- 같은 시드에서 고치기 전과 후의 최종 `state` 해시가 같다(엔진 결과 불변).
- AI 턴 동안 `remainingMs > 0` 이다.
- 상대 턴 조준 중 `focusSlot == opponentAim.slot`, `focusSide == activeSide` 이다.

기존 테스트 `a34_turn_tension_test` 등이 깨지면 원인을 보고 기대값만 맞춘다(테스트를 지우지 않는다).

## 검증
1. `bash tool/verify.sh` 를 통과시킨다. 다른 세션의 battle_cues 301줄 문제는 그 세션 몫이다. 겹치면 사용자에게 알린다.
2. `(cd app && flutter run)` 이나 web 으로 AI 대전을 열어 확인한다.
   - AI 연속 발사 때 착탄 → 카메라가 상대 해적으로 이동 → 빨간 조준 링이 좁아지고 몸을 젖힘 → 발사 순서로 보이는지.
   - 난이도 쉬움과 지옥 모두에서 확인한다.
3. 커밋 → 브랜치 push → 최신 main 병합 후 verify → main 병합·push.
4. 실기기 손맛(간격 길이 체감)은 보고에 사람 확인 항목으로 남긴다.
