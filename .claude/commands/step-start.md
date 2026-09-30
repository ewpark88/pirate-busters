---
description: 개발 계획서의 단계를 시작한다 (예: /step-start M1)
argument-hint: <단계 ID, 예: M1>
---
단계 $ARGUMENTS 를 시작한다. 아래 순서를 지킨다.

0. `dart run tool/check_doc_sync.dart` 를 실행한다. 실패하면 CLAUDE.md “설계서나 BALANCE.md 가 바뀌면” 절차로 계획서를 먼저 갱신한다.
1. `Pirate Busters 개발 계획서.md` 에서 $ARGUMENTS 섹션(목표, 작업 체크리스트, 완료 조건, 설계서 참조 절)을 읽는다.
2. 참조된 `Pirate Busters 게임 설계서.md` 절, `docs/BALANCE.md` 의 A§ 수치, `docs/MOZZI_REUSE.md` 에서 이번 단계에 가져올 코드와 수치를 확인한다.
3. `docs/PROGRESS.md` 에 선행 단계가 완료로 기록돼 있는지 확인한다. 아니면 멈추고 보고한다.
4. `git switch -c feat/$ARGUMENTS-<short-name>` 브랜치를 만든다 (main 에서 분기).
5. 세부 구현 계획(만들 파일, 테스트 목록, 계획서와 달라지는 점, 설계서에서 불명확한 수치)을 사용자에게 제시하고 승인을 받은 뒤 구현한다.
   - 계획서와 달라지는 결정은 `docs/DECISIONS.md` 에 ADR 로 추가한다.
