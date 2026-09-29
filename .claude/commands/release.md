---
description: 릴리스를 준비한다 — 버전·CHANGELOG·검증·태그 (예: /release minor)
argument-hint: <patch|minor|major|X.Y.Z>
---
`docs/RELEASE.md` 절차로 릴리스 $ARGUMENTS 를 준비한다. 각 단계에서 실패하면 멈추고 보고한다.

1. 사전 조건: 현재 브랜치가 `main` 이고 작업 트리가 깨끗한지, 릴리스할 마일스톤이 `docs/PROGRESS.md` 에 완료로 기록됐는지 확인한다. 아니면 멈추고 보고한다.
2. `CHANGELOG.md` 의 `[Unreleased]` 가 비어 있으면 지난 태그 이후 `git log` 로 초안을 써서 사용자에게 보여 준다(Added/Changed/Fixed/Balance, 사용자 관점 문장).
3. `bash tool/verify.sh` 를 통과시킨다.
4. `dart run tool/release.dart bump $ARGUMENTS` 로 `app/pubspec.yaml` 버전·BUILD 와 CHANGELOG 를 갱신한다.
5. `docs/RELEASE.md` §3 체크리스트(골든 해시, 실기기 해시, 두 언어 화면, 권한·개인정보 등) 중 이번 단계에 해당하는 항목을 표로 보고하고, 사람이 해야 하는 항목은 “사용자 확인 필요”로 표시한다.
6. 사용자가 승인하면: `chore(release): vX.Y.Z+B` 커밋 → `git tag -a vX.Y.Z+B -m "vX.Y.Z+B"` → push 여부를 묻는다. push 하면 `.github/workflows/release.yml` 이 AAB 를 빌드하고 GitHub Release 초안을 만든다.
7. Play Console 업로드와 트랙 선택은 사용자가 한다. 업로드 뒤 `docs/PROGRESS.md` 에 릴리스 기록을 남긴다.
