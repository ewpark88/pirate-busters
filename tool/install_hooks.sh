#!/usr/bin/env bash
# 저장소 git 훅(.githooks)을 켠다. 클론한 뒤 한 번 실행한다.
set -euo pipefail
cd "$(dirname "$0")/.."
git config core.hooksPath .githooks
chmod +x .githooks/* 2>/dev/null || true
echo "git hooks 설치 완료: $(git config core.hooksPath) (commit-msg, pre-commit, pre-push)"
