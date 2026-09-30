#!/usr/bin/env bash
# 품질 게이트. 작업 완료 선언·커밋 전 반드시 통과해야 한다. CI·pre-push 훅도 같은 스크립트를 쓴다.
# 사용법: bash tool/verify.sh
set -euo pipefail
cd "$(dirname "$0")/.."

step() { printf '\n== %s ==\n' "$1"; }

step "1/7 format"
dart format --output=none --set-exit-if-changed app/lib packages tools tool

step "2/7 analyze"
flutter analyze --fatal-infos --fatal-warnings

step "3/7 architecture · determinism"
dart run tool/check_architecture.dart

step "4/7 doc sync (설계서·BALANCE.md ↔ 계획서)"
dart run tool/check_doc_sync.dart

step "5/7 l10n (ko ↔ en ARB)"
dart run tool/check_l10n.dart

step "6/7 secrets"
dart run tool/check_secrets.dart

step "7/7 test"
echo "-- tool"
dart test tool/test
for pkg in packages/pb_sim packages/pb_ai packages/pb_data tools/sim_runner; do
  if [ -d "$pkg/test" ]; then
    echo "-- $pkg"
    (cd "$pkg" && dart test)
  fi
done
if [ -d app/test ]; then
  echo "-- app"
  (cd app && flutter test)
fi

printf '\nverify PASSED\n'
