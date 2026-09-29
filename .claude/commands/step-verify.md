---
description: 현재 단계의 완료 조건을 검증하고 진행 기록을 갱신한다 (예: /step-verify M1)
argument-hint: <단계 ID, 예: M1>
---
단계 $ARGUMENTS 의 완료를 검증한다.

1. `bash tool/verify.sh` 를 실행한다. 실패하면 원인을 고치고 다시 실행한다 (규칙을 끄거나 테스트를 지워서 통과시키지 않는다).
2. `Pirate Busters 개발 계획서.md` 의 $ARGUMENTS 작업 체크리스트와 완료 조건을 하나씩 확인하고, 항목마다 근거(테스트 이름, 명령 출력, 수동 확인 필요 여부)를 표로 보고한다.
3. 기기 확인이 필요한 항목은 “사용자 확인 필요”로 표시하고 확인 방법을 적는다.
4. 모두 충족되면:
   - 개발 계획서의 해당 체크박스에 체크한다.
   - `docs/PROGRESS.md` 에 날짜, 완료 항목, 남은 이슈, 결정 사항을 추가한다.
   - `CLAUDE.md` 의 “현재 단계” 줄을 다음 단계로 바꾼다.
   - `CHANGELOG.md` 의 `[Unreleased]` 에 사용자 관점 변경을 적는다.
5. `rules-reviewer` 에이전트로 변경분을 검토하고 차단 항목을 고친다.
6. 커밋(Conventional Commits)은 사용자가 요청하면 한다. 버전·태그는 `/release` 로 한다.
