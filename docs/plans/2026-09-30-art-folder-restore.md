# art/ 폴더 복구

## Context
`D:\Projects\pirate-busters\art\` 가 없다. 원인:
- 아트 에셋 작업은 별도 worktree `D:\Projects\pirate-busters-assets` (브랜치 `feat/M4-assets`) 에서 했고, `tool/import_assets.dart` 가 그 worktree 기준 상대 경로 `art/` 에 원본을 복사했다.
- `art/` 는 `.gitignore:44` 로 git 제외라서, `feat/M4-assets` 를 머지해도 `app/assets/` 만 넘어오고 `art/` 는 넘어오지 않았다.
- 이후 worktree 가 정리되면서 `D:\Projects\pirate-busters-assets\` 에는 `art/pb_assets_v0.15/` 만 남아 있다 (삭제된 게 아니라 원래 여기 없었다).

## 할 일
1. `D:\Projects\pirate-busters-assets\art` 를 `D:\Projects\pirate-busters\art` 로 옮긴다 (복사 후 원래 폴더는 사용자 확인 뒤 삭제).
2. `git status` 로 `art/` 가 추적되지 않는지(무시되는지) 확인한다.

## Verification
- `D:\Projects\pirate-busters\art\pb_assets_v0.15\README.md`, `tools\flame\pb_anim.dart` 존재 확인.
- `dart run tool/import_assets.dart --check` 통과.
