# 조준 작업 커밋 + 배 움직임 연료 반으로

## Context
사용자 요청은 두 가지다. (1) 조준 표시 작업(ADR-076)을 커밋한다. (2) 배의 연료를 반으로 줄인다.
(2)는 "움직임 전체 반"으로 정했다. 탱크·턴 회복·폭풍 보급·연료통 등 연료 양 전부가 칸 수로 반이 된다
(브리건틴: 처음 20칸 → 10칸, 매 턴 약 6칸 → 3칸).

작업 트리는 다른 세션(camera-basewidth-zoom 등)과 같이 쓴다. 다른 세션이 R1a-1 을 `b3ec310` 으로
이미 커밋했다. 그래서 내 경로와 내 덩어리만 커밋한다.

## 1. 조준 작업 커밋 (feat/R1a-sim-modules, b3ec310 위)
- 파일마다 `git diff HEAD` 로 덩어리를 확인하고 **내 덩어리만** 인덱스에 올린다.
  - 다른 세션 변경이 섞인 파일: HEAD 내용에 내 덩어리만 적용한 blob 을 `git hash-object -w` 로 만들어
    `git update-index --cacheinfo` 로 올린다. `shot_view.dart` 는 처음부터 수정돼 있었고, 계획서에는 다른 세션의 A22 블록이 있다.
  - 내 것: `app/lib/game/view/aim_painter.dart`·`aim_sling.dart`(새 파일)·`aim_labels.dart`·`shot_view.dart`,
    `app/lib/battle/session_views.dart`, `app/lib/input/pull_aim.dart`·`field_gestures.dart`,
    `app/test/aim_painter_test.dart`·`pull_aim_test.dart`·`battle_session_test.dart`,
    설계서 §2.2·§10.4 의 20% 두 줄, 계획서의 A12 문구와 해시 줄, `docs/DECISIONS.md` ADR-076,
    `docs/plans/2026-10-02-aim-visual-polish.md`, `docs/plans/README.md` 의 내 한 줄, `.claude/commands/art-doc-sync.md`.
- 계획서 해시: `tool/check_doc_sync.dart` 의 `docsHash` 로 (HEAD 설계서 + 내 덩어리, HEAD BALANCE) 를 계산해 넣는다.
- 커밋: `feat(app): 조준 표시 정밀도 — 실제 발사 방향·놓기 미끄러짐 제거·점선 20%`. 훅은 우회하지 않는다.
- 커밋 뒤에는 작업 트리 계획서 해시를 합친 값으로 다시 맞춰 둔다(`check_doc_sync`).

## 2. 연료 반 (balance 커밋, 사용자 결정)
- **방법:** BALANCE A2.7 의 **1칸당 소모를 2배**로 한다: 슬루프 8 · 유령선 10 · 브리건틴 10 · 프리깃 12 · 갤리온 14.
  - 탱크·회복을 반으로 줄인 것과 칸 수 결과가 똑같다. 탱크 50·회복 +15 로 줄이는 방식은 파도 사냥꾼 −15(→7.5), 레벨당 탱크 +1(→0.5)처럼 반으로 나누면 소수가 되는 값이 생긴다.
    소모를 2배로 하면 연료와 관련된 모든 양(램프 +30, 파도 사냥꾼 −15, AI 비축 40, 연료통 +40, 폭풍 +30)이 자동으로 칸 수 반이 된다.
  - A2.7 아래 설명 문단(“매 턴 약 6칸… 20칸 끝에서 끝까지”)을 “약 3칸, 처음 10칸(이동 구간 절반)”으로 고친다.
  - 설계서 §2.7 에는 수치가 없어 고칠 것이 없다. B부에 연료 계산이 있는지 확인하고, 있으면 다시 계산한다.
- **코드:** `packages/pb_sim/lib/src/ship/hull.dart` 의 선형별 `fuelPerCell`. 선형 정의가 데이터 JSON 에도 있으면(`pb_data`, `app/assets/game/*.json`) 같이 고친다.
- **테스트:** 연료 테스트(`pb_sim/test/motion_test.dart`·`module_test.dart`·`r1a_effects_test.dart`, `pb_ai/test/ai_test.dart`, app 의 `battle_*`·`hud_test`·`platform_test`)에서
  기대값이 바뀌는 것만 새 규칙에 맞게 고친다. 골든 리플레이 해시(`pb_sim/test/golden_test.dart`)는 다시 뽑고, 바뀐 이유를 커밋에 적는다.
- **문서:** 계획서 기준 문서 해시 갱신(`/doc-sync`), ADR-077, CHANGELOG `[Unreleased]` 한 줄.
- 커밋: `balance(sim): 이동 연료 소모 2배 — 배 움직임 반으로`.

## 3. 질문 답변 (돛에 캐릭터 태우기, 코드 변경 없음)
- 지금 규칙상 해적은 **격자 안 선실 칸**에만 탄다(§3.3). 선실은 블록이 있는 칸이면 어디든 놓을 수 있다(`build_check.dart` `_cabinProblem`). 그래서 망사(돛) 블록을 높이 쌓고 그 위에 선실을 두거나, 높은 선실에 망루 옵션(궤적 50%)을 다는 건 지금도 된다.
- 화면에 그리는 돛대·돛·깃발(`module_painter.dart`)은 격자 밖 장식이라 판정이 없다. 그래서 그림의 돛 위에 해적을 태울 수는 없다.
  하려면 설계서에 새 규칙이 필요하다(돛대 위 칸, 공중층 §2.1, 피격·붕괴). 넣는다면 12장 끝의 A단계로 제안한다(절대 규칙 11).

## 검증
- 각 커밋 전에 `bash tool/verify.sh` 를 통과시킨다. 다른 세션이 아직 커밋하지 않은 변경은 작업 트리에 남는다.
  그래서 커밋 뒤 `git stash` 없이 `git diff --cached` 와 `git show --stat` 으로 내 파일만 들어갔는지 확인한다.
- 연료: `motion_test` 에서 브리건틴이 가득 찬 탱크로 10칸, 회복 한 번으로 3칸 가는지 확인한다.
