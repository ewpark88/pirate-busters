# Pirate Busters — 에이전트 작업 가이드

내가 지은 해적선으로 겨루는 1:1 턴제 해상 포격전(턴당 25초, 양쪽 합쳐 최대 30턴). Flutter + Flame, Android 먼저, 1인 개발.
**`Pirate Busters 개발 계획서.md` 의 단계 순서대로만** 진행한다.

**현재 단계: M5 — 해적 12명·기능 모듈·건조 (`pb_data`, `pb_sim`, `app/shipyard`)** (M4 완료, 표정 에셋·손맛 체크포인트 이월. 진행 기록: docs/PROGRESS.md)

## 기준 문서
| 문서 | 역할 |
|---|---|
| `Pirate Busters 게임 설계서.md` | 기능·규칙·구조 상수의 “무엇”. 코드·테스트·커밋에 참조 절(예: `설계서 §7.1`)을 남긴다 |
| `Pirate Busters 개발 계획서.md` | 지금 무엇을 할 차례인지, 마일스톤별 작업과 완료 조건 |
| `docs/DECISIONS.md` | 과거 결정과 이유 (ADR) |
| `docs/MOZZI_REUSE.md` | mozzi(`D:\Projects\mozzi`)에서 가져올 코드 목록 |
| `docs/PROGRESS.md` | 단계별 완료 기록 |
| `docs/BALANCE.md` | **밸런스 수치의 기준.** 규칙은 설계서, 수치(피해·체력·재질·배율·코스트·사다리·세트·침수·연료·사거리·모듈·AI 다이얼·캠페인 배율·레벨업·보상 확률)는 여기 A부. B부는 A부에서 유도한 계산표. 설계서와 함께 해시 검사 대상이다 (ADR-037) |
| `docs/HARNESS.md` | 규칙을 강제하는 훅·검사·CI 구성표 |
| `docs/RELEASE.md` | 출시 규칙: 버전·태그·체크리스트·서명·핫픽스·롤백 |
| `CHANGELOG.md` | 사용자 관점 변경 기록 (단계 완료 때 `[Unreleased]` 에 적는다) |

- **설계서와 BALANCE.md 는 직접 고치지 않는다.** 오류·누락은 사용자에게 알리고 수정을 제안한다. 수치를 바꾸자는 제안은 BALANCE.md A부 기준으로 한다.
- 설계서와 구현이 어긋나면 코드로 우회하지 말고 먼저 사용자에게 묻는다.
- **계획서는 설계서를 따른다 (ADR-008, ADR-030, ADR-037).** 설계서(규칙)와 BALANCE.md(수치)가 기준이다. 계획서에는 밸런스 수치를 적지 않고 `BALANCE.md A§n.n` 을 참조한다. 계획서가 설계서와 다르면 계획서를 고친다. 설계서와 다르게 구현하자는 결정(ADR 등)이 나오면 그 자리에서 설계서 수정을 사용자에게 제안하고, 설계서가 바뀌기 전까지 계획서는 설계서 문구를 유지한다. 두 문서가 어긋난 채로 두지 않는다.
- **설계서나 BALANCE.md 가 바뀌면 같은 커밋에서 개발 계획서도 고친다.** 두 문서는 계속 갱신된다. 변경을 발견하면(`tool/check_doc_sync.dart` 실패, 사용자 알림, git diff) 다른 작업보다 먼저 `/doc-sync` 절차를 따른다:
  1. `git diff` 로 설계서·BALANCE.md 의 바뀐 절을 확인한다.
  2. 계획서에서 그 절(§)을 참조하는 작업·완료 조건·수치·범위를 고친다. 계획서에 아직 없는 설계서 기능은 담당 단계를 정해 넣는다. 새 기능·이벤트·메뉴는 12장 ‘추가 단계’ 끝에 `A<n>` 으로 넣고(절대 규칙 11), 빠진 기능은 지운다.
  3. 이미 끝난 단계나 현재 단계에 영향이 있으면 사용자에게 알리고, 코드 수정이 필요하면 할 일로 제안한다.
  4. 계획서 머리의 `기준 문서 동기화:` 해시(설계서 + BALANCE.md)와 날짜를 갱신하고, 계획 변경이 크면 ADR 을 남긴다. 해시가 안 맞으면 pre-commit·verify·CI 가 실패하므로 기준 문서만 바뀐 커밋은 들어가지 않는다. BALANCE.md A부 값이 바뀌면 B부도 다시 계산한다.

## 저장소 구조와 의존 방향 (ADR-001, ADR-002)
```
packages/pb_sim    순수 Dart 결정론 전투 엔진. 워크스페이스 의존 없음
packages/pb_ai     순수 Dart AI. → pb_sim
packages/pb_data   JSON 로드·검증 → pb_sim 정수 정의. → pb_sim
app/               Flutter + Flame. 렌더·입력·건조·메타. → 전부
tools/sim_runner   AI 대 AI CLI. → 전부
tool/              검사·훅 스크립트
```

## 절대 규칙
1. 현재 단계 범위 밖의 기능을 미리 만들지 않는다. 필요하면 개발 계획서 수정을 먼저 제안한다.
2. **결정론 (설계서 §7.1, ADR-003):** `pb_sim`/`pb_ai` 에서는 `double`, `num`, 실수 리터럴, `/`(→ `~/`), `dart:math`, `Random`, `DateTime` 을 쓰지 않는다. 위치·속도·각도는 ×1000 정수, 삼각함수는 정수 테이블, 난수는 매치 시드 xorshift32, 엔티티는 id 순으로 갱신한다. `Map`/`Set` 순회 순서에 기대지 않는다.
3. 게임 규칙과 판정은 `pb_sim` 에만 둔다. Flame 컴포넌트와 위젯은 시뮬 상태를 그리기만 하고, 입력은 턴 묶음 커맨드(`MOVE`/`FIRE`/`TAP`/`END_TURN`/`SURRENDER`)로만 넘긴다.
4. AI 도 사람과 같은 커맨드만 낸다. 전투 엔진은 상대가 누구인지 모른다.
5. 새 로직에는 테스트를 같이 쓴다. `pb_sim` 은 시드 고정 재현성(해시) 테스트가 필수다. 테스트 이름은 한국어 문장으로 쓴다.
6. 완료라고 말하기 전에 `bash tool/verify.sh`(또는 `tool/verify.ps1`)를 통과시킨다. 린트를 끄거나 테스트를 지워서 통과시키지 않는다.
7. 새 패키지 추가·규칙 변경·계획 변경은 `docs/DECISIONS.md` 에 ADR 로 남긴다.
8. 0원 원칙: 유료 에셋·서버를 쓰지 않는다. 폰트는 OFL, 음악은 CC0 만 쓴다.
9. lib 파일은 300줄 이하 (자동 검사).
10. **한국어·영어 동시 지원 (설계서 §14):** 화면에 보이는 모든 글자는 `app/lib/l10n/app_ko.arb`·`app_en.arb` 에 같은 키로 **같은 커밋에서** 함께 추가한다. 위젯·Flame 컴포넌트에 문장을 직접 쓰지 않는다. 데이터 JSON 에는 글자 대신 문자열 키만 넣는다.
11. **새 기능은 계획서 마지막 단계 뒤에 붙인다 (ADR-024):** 설계서에 새로 들어온 기능·이벤트·메뉴(예: 월간 출석)는 기존 단계(Phase 0 ~ 운영)에 끼워 넣지 않고, 개발 계획서 12장 ‘추가 단계’ 끝에 `A<n>` 단계로 추가한다. 진행 중이거나 끝난 로직과 섞여 같은 작업을 다시 하지 않게 하기 위해서다. 기존 기능의 수치·규칙만 바뀐 경우는 그 기능이 있는 단계에서 고치되, 이미 끝난 단계의 코드를 다시 고쳐야 하면 그 작업도 `A<n>` 단계로 만든다.
12. **계획서는 설계서를 따른다 (ADR-030, ADR-037):** 계획서와 설계서·BALANCE.md 가 다르면 계획서를 맞춘다. 두 문서가 바뀌면 같은 커밋에서 계획서를 고친다(`/doc-sync`). 다르게 하려면 설계서·BALANCE.md 수정을 먼저 제안하고, 계획서·코드만 따로 바꾸지 않는다. 밸런스 수치는 BALANCE.md 에만 두고 계획서에는 참조만 적는다.
13. **설명은 한국어로만 한다:** 사용자에게 하는 보고·진행 알림·질문은 모두 한국어로 쓴다. 중간에 영어로 바꾸지 않는다(코드 식별자·명령어·경로는 그대로).

## 브랜치·커밋·버전
- `main` 은 항상 verify 가 통과하는 상태다. 마일스톤 작업은 `feat/<단계>-<이름>` 브랜치(예: `feat/M1-sim-core`)에서 한다.
- `main` 에 직접 커밋하지 않는다(pre-commit 훅이 막는다). 머지·릴리스 커밋만 `ALLOW_MAIN_COMMIT=1` 로 한다.
- 커밋은 Conventional Commits: `<type>(<scope>): <요약>` (첫 줄 72자 이하, 끝에 마침표 없음). type: feat, fix, refactor, test, docs, chore, build, ci, perf, balance. scope: sim, ai, data, app, render, input, shipyard, meta, tool, docs, release, deps. commit-msg 훅과 CI 가 검사한다.
- 버전: MVP 동안은 `0.<마일스톤>.PATCH` (M1 완료 = `0.1.0`). 스토어에 올릴 때마다 BUILD +1. 버전은 손으로 고치지 않고 `dart run tool/release.dart bump` 로 올린다.
- 커밋·머지·push·태그는 사용자가 요청할 때만 한다. 훅을 우회(`--no-verify`)하거나 끄지 않는다.

## 출시 (docs/RELEASE.md)
- 릴리스는 `main` 에서 `/release <patch|minor|major>` 로만 한다: CHANGELOG → verify → bump → `chore(release): vX.Y.Z+B` 커밋 → 주석 태그 → push 하면 CI 가 서명된 AAB 와 Release 초안을 만든다.
- Play Console 업로드와 트랙 선택은 사용자가 한다. 에이전트는 체크리스트(§3)의 사람 확인 항목을 표로 보고한다.
- 서명 키·`key.properties`·`.env`·`google-services.json` 은 읽지도 커밋하지도 않는다.

## 자주 쓰는 명령
```bash
flutter pub get                          # 루트에서 한 번 (workspace)
bash tool/install_hooks.sh               # 클론 뒤 한 번: git 훅(commit-msg / pre-commit / pre-push) 켜기
bash tool/verify.sh                      # 품질 게이트: format / analyze / architecture·결정론 / doc sync / l10n / secrets / test
dart run tool/check_architecture.dart    # 의존 방향·결정론 규칙만 검사
dart run tool/check_doc_sync.dart        # 설계서·BALANCE.md 변경이 계획서에 반영됐는지 검사
dart run tool/gen_trig_table.dart        # pb_sim 정수 sin 테이블 재생성
dart run tool/release.dart check         # pubspec 버전·CHANGELOG 일치 검사 (bump / notes 도 있다)
(cd packages/pb_sim && dart test)        # 패키지 하나만 테스트
(cd app && flutter run)                  # 앱 실행
```

## 슬래시 명령
- `/step-start <단계>`: 단계 착수 (계획 확인 → 브랜치 → 세부 계획 승인 → 구현)
- `/step-verify <단계>`: 완료 조건 검증, 진행 기록·CHANGELOG 갱신, `rules-reviewer` 검토
- `/doc-sync`: 설계서·BALANCE.md 변경을 계획서에 반영 (ADR-008, ADR-037)
- `/adr <제목>`: 결정 기록 추가
- `/release <patch|minor|major>`: 릴리스 준비 (docs/RELEASE.md)
