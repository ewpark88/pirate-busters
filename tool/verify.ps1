# 품질 게이트 (PowerShell). tool/verify.sh 와 같은 단계를 실행한다.
# 사용법: powershell -File tool/verify.ps1
$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '..')

function Invoke-Step([string]$name, [scriptblock]$block) {
  Write-Output "`n== $name =="
  & $block
  if ($LASTEXITCODE -ne 0) { throw "$name 실패 (exit $LASTEXITCODE)" }
}

Invoke-Step '1/7 format' { dart format --output=none --set-exit-if-changed app/lib packages tools tool }
Invoke-Step '2/7 analyze' { flutter analyze --fatal-infos --fatal-warnings }
Invoke-Step '3/7 architecture · determinism' { dart run tool/check_architecture.dart }
Invoke-Step '4/7 doc sync' { dart run tool/check_doc_sync.dart }
Invoke-Step '5/7 l10n' { dart run tool/check_l10n.dart }
Invoke-Step '6/7 secrets' { dart run tool/check_secrets.dart }
Invoke-Step '7/7 test tool' { dart test tool/test }
foreach ($pkg in 'packages/pb_sim', 'packages/pb_ai', 'packages/pb_data', 'tools/sim_runner') {
  if (Test-Path "$pkg/test") {
    Invoke-Step "7/7 test $pkg" { Push-Location $pkg; try { dart test } finally { Pop-Location } }
  }
}
if (Test-Path 'app/test') {
  Invoke-Step '7/7 test app' { Push-Location app; try { flutter test } finally { Pop-Location } }
}
Write-Output "`nverify PASSED"
