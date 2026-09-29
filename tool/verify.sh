#!/usr/bin/env bash
# 품질 게이트. 작업 완료 선언·커밋 전 반드시 통과해야 한다. CI 도 같은 스크립트를 쓴다.
# 사용법: bash tool/verify.sh
set -euo pipefail
cd "$(dirname "$0")/.."

step() { printf '\n== %s ==\n' "$1"; }

step "1/5 format"
dart format --output=none --set-exit-if-changed app/lib packages tools tool

step "2/5 analyze"
flutter analyze --fatal-infos --fatal-warnings

step "3/5 architecture · determinism"
dart run tool/check_architecture.dart

step "4/5 doc sync (설계서 ↔ 계획서)"
dart run tool/check_doc_sync.dart

step "5/5 test"
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
