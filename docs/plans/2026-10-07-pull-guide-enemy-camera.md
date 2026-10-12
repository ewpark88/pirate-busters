# 튜토리얼 당기기 안내 위치 맞춤 + 상대 턴 카메라 (A40 브랜치)

## Context
1. 튜토리얼 `FingerCue.pullBack` 안내(막대 + 움직이는 점)는 화면 고정 비율(`Alignment(-0.12,0.05)→(-0.42,0.32)`)에 그려서 고른 해적의 실제 위치와 맞지 않는다.
2. 카메라 기본 화면은 늘 `viewSide`(AI 전은 0번=내 배)를 기준으로 잡아, 상대 턴에도 내 배를 보여 준다. 상대 턴에는 상대 배를 같은 방식(배 + 앞바다)으로 보여 줘야 한다.

## 1. 당기기 안내를 해적 위치에 맞춘다
- `app/lib/game/battle_game.dart`: 고른 해적 몸 가운데의 화면 좌표를 돌려주는 메서드 추가
  - `Offset? focusPirateScreen()` — `session.focusSlot` 의 rig `absolutePosition - (0, Coords.pirateHeight/2)`(= `nearestPirate` 가 잡는 점, `pirate_pick.dart`)를 `camera.localToGlobal` 로 변환. 없으면 null.
  - 당기는 방향용 `int get aimFacing => facingOf(session.state.activeSide)`.
- `app/lib/ui/hud/tutorial_finger.dart`: `pullAnchor` 콜백(`Offset? Function()`)과 `facing` 을 받는다. `pullBack` 은
  - 시작점 = 해적 몸 가운데(매 프레임 콜백으로 읽어 카메라 줌인 중에도 따라감)
  - 끝점 = 시작점 + (`-facing` × 70, +55) 화면 px (뒤·아래로, `PullAim` 당김 방향과 같음, 최대 160px 안쪽)
  - 콜백이 null 이면(아직 위치 없음) 그리지 않는다. 기존 고정 비율 좌표는 지운다.
- `app/lib/ui/battle_screen.dart:264`: `TutorialFinger(session:, step:, pullAnchor: _game.focusPirateScreen, facing: ...)` 로 넘긴다.

## 2. 상대 턴에는 상대 배를 기준으로
- `battle_game.dart` `_updateCamera`: 기본 화면 기준 진영을 `anchor = session.state.activeSide` 로 바꿔 `myX`·`enemyX`·`facing`·`shipTop` 에 쓴다. `focusFeet` 은 그대로 `viewSide`(상대 턴엔 `focusSlot` 이 null 이라 영향 없음).
  - 핫시트는 원래 activeSide = viewSide 라 동작 같음. 탄 추적·착탄 머묾은 그대로이고, 내 탄 착탄 → 턴 전환 뒤 느린 복귀(returnRate)로 상대 배로 넘어간다.
  - 판이 끝난 뒤(`isOver`)는 지금처럼 `viewSide` 유지.
- 판단 분기를 `cameraSideOf(session, viewSide)` 같은 작은 순수 함수로 빼서 테스트한다.
- `camera_director.dart` 머리 주석의 “상대 턴도 같다”를 “상대 턴에는 상대 배와 그 앞바다” 로 고친다.

## 테스트
- `app/test/` 에: 카메라 기준 진영 — 내 턴 0, 상대 턴 1, 판 끝 viewSide (한국어 이름).
- 튜토리얼 손가락: 앵커가 주어지면 그 점에서 시작해 뒤(−facing)·아래로 향하는지(painter 좌표 계산을 함수로 빼서 확인), 앵커 null 이면 안 그림.

## 확인
- `bash tool/verify.sh` 통과.
- `(cd app && flutter run)` 튜토리얼 1판: 카드 고른 뒤 안내 막대가 해적 몸에서 뒤로 뻗는지, 상대 턴 시작 때 카메라가 상대 배로 옮겨가는지 눈으로 확인.
- 승인 뒤 이 계획 파일을 `docs/plans/2026-10-07-pull-guide-enemy-camera.md` 로 옮기고 색인에 한 줄 추가.
