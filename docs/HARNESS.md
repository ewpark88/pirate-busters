# 하네스 (개발·출시 가드레일)

에이전트와 사람이 같은 규칙으로 일하도록, 규칙을 **문서 → 에이전트 훅 → git 훅 → CI → 릴리스** 층에 겹쳐 둔다.
문서로만 있는 규칙은 잊히므로, 검사할 수 있는 규칙은 스크립트로 만들고 여러 층에서 같은 스크립트를 부른다 (ADR-003, ADR-008, ADR-015).

## 1. 층별 구성

| 층 | 파일 | 언제 | 하는 일 |
|---|---|---|---|
| 문서 | `CLAUDE.md` | 매 세션 | 현재 단계, 절대 규칙, 브랜치·커밋·버전 규칙 |
| | `docs/RELEASE.md` | 릴리스 | 버전·태그·체크리스트·서명·핫픽스·롤백 |
| | `docs/DECISIONS.md` | 결정마다 | ADR |
| | `CHANGELOG.md` | 단계 완료·릴리스 | 사용자 관점 변경 |
| 에이전트 | `.claude/settings.json` 권한 | 도구 호출마다 | 설계서 편집 거부, 비밀 파일 읽기 거부, force push·`--no-verify`·훅 끄기 거부, push·tag·의존성 추가는 확인 |
| | `SessionStart` 훅 `tool/hooks/session_start.dart` | 세션 시작 | 현재 단계·브랜치·미커밋 수·문서 동기화·git 훅 상태를 알림 |
| | `PostToolUse` 훅 `tool/hooks/format_on_edit.dart` | 파일 편집 뒤 | `dart format` |
| | `Stop` 훅 `tool/hooks/stop_check.dart` | 턴 끝 | 바뀐 파일이 있으면 아키텍처·결정론, 문서 동기화, ARB 검사. 위반이면 되돌려 고치게 함 |
| | `/step-start`, `/step-verify`, `/doc-sync`, `/adr`, `/release` | 명령 | 단계 착수·검증, 문서 동기화, ADR, 릴리스 절차 |
| | `rules-reviewer` 에이전트 | 단계 검증 때 | 자동 검사가 못 잡는 규칙(단계 범위, 순회 순서, 규칙 위치, 테스트 품질) 검토 |
| git | `.githooks/commit-msg` | 커밋 | Conventional Commits 검사 |
| | `.githooks/pre-commit` | 커밋 | main 직접 커밋 거부, 비밀값, 스테이징된 파일 포맷, 아키텍처·결정론, 문서 동기화, ARB |
| | `.githooks/pre-push` | push | 태그면 릴리스 일치 검사, 그리고 전체 `tool/verify.sh` |
| CI | `.github/workflows/ci.yml` | PR, main push | PR 커밋 메시지, `tool/verify.sh`, debug APK |
| | `.github/dependabot.yml` | 매월 | Actions·pub 갱신 PR (골든 해시가 바뀌면 거절) |
| | PR·이슈 템플릿 | PR·이슈 | 규칙 체크리스트, 리플레이 첨부 |
| 릴리스 | `.github/workflows/release.yml` | 태그 `v*` push | 태그·pubspec·CHANGELOG 일치 → verify → 서명된 AAB → Release 초안 |
| | `tool/release.dart` | 릴리스 | `bump` / `check` / `notes` |

## 2. 검사 스크립트

모두 `tool/` 에 있고, 순수 로직은 `tool/test/` 에서 테스트한다. `tool/verify.sh` 가 전부 부른다.

| 스크립트 | 규칙 | 근거 |
|---|---|---|
| `check_architecture.dart` | 의존 방향, 순수 Dart, 결정론 금지 식별자·실수·`/`, lib 300줄 | ADR-002, ADR-003, 절대 규칙 2·9 |
| `check_doc_sync.dart` | 설계서 + `docs/BALANCE.md` 해시 = 계획서 `기준 문서 동기화:` 표시 (기준 문서만 바뀐 커밋을 막는다. 내용 대조는 `/doc-sync`) | ADR-008, ADR-030, ADR-037 |
| `check_l10n.dart` | `app_ko.arb`·`app_en.arb` 키·플레이스홀더 짝, 빈 값 | 설계서 §14, 절대 규칙 10 |
| `check_secrets.dart` | 키 파일·키 모양 문자열 | `docs/RELEASE.md` §4 |
| `check_commit_msg.dart` | `<type>(<scope>): <요약>`, 허용 type·scope, 72자 | CLAUDE.md 「브랜치·커밋·버전」 |
| `release.dart` | 버전·CHANGELOG·태그 일치 | `docs/RELEASE.md` |

## 3. 처음 설정

```bash
flutter pub get
bash tool/install_hooks.sh      # git config core.hooksPath .githooks
```

GitHub 저장소 설정(사람이 한 번):
- `main` 브랜치 보호: PR 필수, CI `verify` 통과 필수, force push 금지.
- Secrets: `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD` (`docs/RELEASE.md` §4).

## 4. 규칙을 바꿀 때

- 검사를 끄거나 느슨하게 하려면 ADR 을 먼저 남긴다. 테스트를 지우거나 훅을 우회(`--no-verify`)해서 통과시키지 않는다 (절대 규칙 6).
- 새 규칙은 가능한 한 스크립트로 만들어 `verify.sh`·`verify.ps1` 에 넣고, 빠른 것은 `pre-commit`·`Stop` 훅에도 넣는다. 이 표도 같이 고친다.
