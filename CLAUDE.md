# Pirate Busters — 에이전트 작업 가이드

내가 지은 해적선으로 겨루는 1:1 턴제 해상 포격전(턴당 25초, 양쪽 합쳐 최대 30턴). Flutter + Flame, Android 먼저, 1인 개발.
**`Pirate Busters 개발 계획서.md` 의 단계 순서대로만** 진행한다.

**현재 단계: M2 — 턴 루프·탄도·타격·붕괴 (`pb_sim`)** (M1 완료. 진행 기록: docs/PROGRESS.md)

## 기준 문서
| 문서 | 역할 |
|---|---|
| `Pirate Busters 게임 설계서.md` | 기능·규칙·수치의 “무엇”. 코드·테스트·커밋에 참조 절(예: `설계서 §7.1`)을 남긴다 |
| `Pirate Busters 개발 계획서.md` | 지금 무엇을 할 차례인지, 마일스톤별 작업과 완료 조건 |
| `docs/DECISIONS.md` | 과거 결정과 이유 (ADR) |
| `docs/MOZZI_REUSE.md` | mozzi(`D:\Projects\mozzi`)에서 가져올 코드 목록 |
| `docs/PROGRESS.md` | 단계별 완료 기록 |

- **설계서는 직접 고치지 않는다.** 오류·누락은 사용자에게 알리고 수정을 제안한다.
- 설계서와 구현이 어긋나면 코드로 우회하지 말고 먼저 사용자에게 묻는다.
- **설계서가 바뀌면 개발 계획서도 같이 고친다 (ADR-008).** 설계서는 계속 갱신된다. 변경을 발견하면(`tool/check_doc_sync.dart` 실패, 사용자 알림, git diff) 다른 작업보다 먼저:
  1. `git diff` 로 설계서의 바뀐 절을 확인한다.
  2. 계획서에서 그 절(§)을 참조하는 작업·완료 조건·수치·범위를 고친다. 새 기능은 알맞은 단계에 넣고, 빠진 기능은 지운다.
  3. 이미 끝난 단계나 현재 단계에 영향이 있으면 사용자에게 알리고, 코드 수정이 필요하면 할 일로 제안한다.
  4. 계획서 머리의 `설계서 동기화:` 해시와 날짜를 갱신하고, 계획 변경이 크면 ADR 을 남긴다.

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

## 브랜치·커밋·버전
- `main` 은 항상 verify 가 통과하는 상태다. 마일스톤 작업은 `feat/<단계>-<이름>` 브랜치(예: `feat/M1-sim-core`)에서 한다.
- 커밋은 Conventional Commits: `<type>(<scope>): <요약>`. type: feat, fix, refactor, test, docs, chore, build, ci, perf, balance. scope: sim, ai, data, app, render, input, shipyard, meta, tool, docs.
- 버전: MVP 동안은 `0.<마일스톤>.PATCH` (M1 완료 = `0.1.0`). 스토어에 올릴 때마다 BUILD +1.
- 커밋·머지·push 는 사용자가 요청할 때만 한다.

## 자주 쓰는 명령
```bash
flutter pub get                          # 루트에서 한 번 (workspace)
bash tool/verify.sh                      # 품질 게이트: format / analyze / architecture·결정론 / doc sync / test
dart run tool/check_architecture.dart    # 의존 방향·결정론 규칙만 검사
dart run tool/check_doc_sync.dart        # 설계서 변경이 계획서에 반영됐는지 검사
dart run tool/gen_trig_table.dart        # pb_sim 정수 sin 테이블 재생성
(cd packages/pb_sim && dart test)        # 패키지 하나만 테스트
(cd app && flutter run)                  # 앱 실행
```

## 슬래시 명령
- `/step-start <단계>`: 단계 착수 (계획 확인 → 브랜치 → 세부 계획 승인 → 구현)
- `/step-verify <단계>`: 완료 조건 검증, 진행 기록 갱신
