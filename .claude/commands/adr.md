---
description: docs/DECISIONS.md 에 새 ADR 을 추가한다 (예: /adr SVG 렌더 패키지 선택)
argument-hint: <결정 제목>
---
`docs/DECISIONS.md` 에 “$ARGUMENTS” ADR 을 추가한다.

1. 마지막 ADR 번호를 찾아 다음 번호를 쓴다. 날짜는 오늘.
2. 형식은 기존 ADR 과 같다: `## ADR-NNN <제목> (YYYY-MM-DD)` 아래 **배경** → **결정** → **대안** → **영향**. 이전 ADR 을 대체하면 영향에 “ADR-xxx 의 … 부분을 대체한다”를 쓴다.
3. 결정 내용이 대화에서 확정되지 않았으면 초안을 보여 주고 사용자 승인을 받은 뒤 쓴다.
4. 규칙이 바뀌는 ADR 이면 `CLAUDE.md`·`docs/HARNESS.md`·검사 스크립트 중 고칠 곳을 함께 제안한다.
