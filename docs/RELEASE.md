# 출시 규칙 (Release)

빌드를 사람 손에 넘기는 모든 경우(비공개 테스트, 정식 출시, 핫픽스)에 이 문서를 따른다. 결정 배경은 ADR-015.
에이전트는 `/release <patch|minor|major|X.Y.Z>` 로 이 절차를 밟는다.

## 1. 버전

| 항목 | 규칙 |
|---|---|
| 형식 | `app/pubspec.yaml` 의 `version: X.Y.Z+BUILD` 가 유일한 원본이다 |
| MVP 동안 | `0.<마일스톤>.PATCH` — M1 완료 `0.1.0`, M2 완료 `0.2.0` … 비공개 테스트 빌드는 M7 의 `0.7.x`, 정식 출시는 `1.0.0` (제안) |
| 정식 출시 뒤 | SemVer 식으로 쓴다: 콘텐츠·기능 추가 MINOR, 버그 수정 PATCH, 세이브·리플레이 호환이 깨지면 MAJOR |
| BUILD | 스토어에 올리는 빌드마다 +1. 한 번 올린 번호는 다시 쓰지 않는다 (Play `versionCode`) |
| 올리는 방법 | 손으로 고치지 않고 `dart run tool/release.dart bump …` 를 쓴다. BUILD 는 자동으로 +1 된다 |

리플레이·세이브 형식이 바뀌면 버전과 별개로 형식 안의 `version` 필드를 올리고(ADR-007), CHANGELOG 에 “호환” 항목으로 적는다.

## 2. 브랜치와 태그

- 릴리스는 항상 `main` 에서 자른다. `main` 은 verify 가 통과하는 상태다.
- 태그는 `vX.Y.Z+BUILD` (예: `v0.7.0+12`), 주석 태그(`git tag -a`)만 쓴다.
- 태그를 push 하면 `.github/workflows/release.yml` 이 태그·pubspec·CHANGELOG 일치 검사 → verify → 서명된 AAB 빌드 → GitHub Release **초안**을 만든다.
- 로컬 `pre-push` 훅도 태그 push 때 `tool/release.dart check` 를 돌린다.
- 올린 태그는 지우거나 옮기지 않는다. 잘못됐으면 새 PATCH/BUILD 로 다시 낸다.

## 3. 릴리스 체크리스트

`/release` 가 이 표를 채워 보고한다. “자동”은 CI 가 막고, “사람”은 사용자가 확인한다.

| # | 항목 | 확인 | 적용 시점 |
|---|---|---|---|
| 1 | `bash tool/verify.sh` 통과 (format·analyze·결정론·문서 동기화·ARB·비밀값·test) | 자동 | 항상 |
| 2 | 태그 = `pubspec` 버전, CHANGELOG 에 해당 절 있음 | 자동 | 항상 |
| 3 | 골든 리플레이 해시 전부 일치 (개발 계획서 M7) | 자동 | M7 이후 |
| 4 | 실기기 2대(ARM 저사양, 고사양) 같은 리플레이 해시 일치 | 사람 | M7 이후 매 릴리스 |
| 5 | 모든 화면 한국어·영어 확인, 골든 스크린샷 (설계서 §14.4) | 사람 | 화면이 생긴 뒤 |
| 6 | 크래시 없이 해역 1 끝까지 진행 | 사람 | M7 이후 |
| 7 | 권한(AndroidManifest)·개인정보처리방침·데이터 보안 양식이 실제 수집 항목과 맞음 (Analytics·Crashlytics·AdMob) | 사람 | M7 이후 |
| 8 | 상자 확률을 게임과 스토어에 표기 (확률형 아이템 규제) | 사람 | R4 이후 |
| 9 | 폰트 OFL·음악 CC0 라이선스 목록 갱신, 유료 에셋 없음 | 사람 | 에셋 추가 시 |
| 10 | Remote Config 기본값이 앱 내장값과 같음 | 사람 | M7 이후 |
| 11 | `applicationId` 가 확정값(현재 `com.repo.pirate_busters` 는 임시)이고 첫 업로드 뒤 바꾸지 않음 | 사람 | 첫 업로드 전 |

## 4. 서명 키와 비밀값

- 업로드 키(`*.jks`)와 `app/android/key.properties` 는 **절대 커밋하지 않는다.** `.gitignore`, `tool/check_secrets.dart`(pre-commit·CI), Claude 권한(`Read` 거부)이 막는다.
- 로컬: `app/android/key.properties.example` 을 복사해 `key.properties` 를 만든다. 없으면 release 빌드는 debug 서명이 된다(스토어 업로드 불가).
- CI: GitHub 저장소 Secrets 에 `ANDROID_KEYSTORE_BASE64`(`base64 -w0 upload.jks`), `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD` 를 넣는다.
- Play 앱 서명(Google 이 앱 서명 키 보관)을 켠다. 업로드 키를 잃으면 Play Console 에서 재설정한다.
- 키 파일과 비밀번호는 저장소 밖 두 곳(예: 비밀번호 관리자 + 오프라인 백업)에 보관한다.
- 비밀값이 커밋됐으면: 즉시 키를 폐기·재발급하고, 기록 정리보다 교체를 먼저 한다.

## 5. 절차

1. **준비** — 릴리스할 마일스톤이 `/step-verify` 로 완료 기록됐고 `main` 에 머지됐다. 작업 트리가 깨끗하다.
2. **CHANGELOG** — `[Unreleased]` 에 사용자 관점 변경을 채운다 (Added/Changed/Fixed/Removed/Balance).
3. **검증** — `bash tool/verify.sh`.
4. **버전** — `dart run tool/release.dart bump <patch|minor|major|X.Y.Z>` → `pubspec` 과 CHANGELOG 가 바뀐다.
5. **커밋·태그** — `ALLOW_MAIN_COMMIT=1 git commit -m "chore(release): vX.Y.Z+B"` → `git tag -a vX.Y.Z+B -m "vX.Y.Z+B"`.
6. **push** — `git push origin main --follow-tags`. CI 가 AAB 와 Release 초안을 만든다.
7. **업로드** — Release 초안의 AAB 를 Play Console 에 올린다. 트랙 순서: 내부 테스트 → 비공개 테스트(12명 × 14일, 설계서 §11.2) → 프로덕션 단계적 출시(10% → 50% → 100%).
8. **기록** — Release 초안을 게시하고, `docs/PROGRESS.md` 에 버전·트랙·날짜를 적는다.

## 6. 핫픽스

- 프로덕션 빌드의 치명 버그만 핫픽스로 다룬다. 나머지는 다음 마일스톤 릴리스에 넣는다.
- 해당 태그에서 `fix/<버전>-<이름>` 브랜치를 만들고, 재현 리플레이를 테스트로 먼저 넣은 뒤 고친다.
- `main` 에 머지하고 `bump patch` 로 절차 3~8 을 밟는다.
- 핫픽스로 `pb_sim` 규칙이 바뀌어 골든 해시가 달라지면 리플레이 호환 영향을 CHANGELOG 에 적는다.

## 7. 롤백

- Play 는 같은 `versionCode` 를 다시 쓸 수 없으므로 “되돌리기”는 이전 코드로 BUILD 만 올린 새 빌드를 내는 것이다.
- 단계적 출시 중 크래시율·ANR 이 오르면 먼저 출시를 **중지**하고, 원인을 찾은 뒤 핫픽스나 이전 코드 재빌드를 낸다.
- 수치 문제는 앱을 다시 내지 않고 Remote Config 로 먼저 되돌린다 (설계서 §11.1).
