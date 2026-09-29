# 결정 기록 (ADR)

새 패키지 추가, 규칙 변경, 계획 변경은 여기에 남긴다. 형식: 배경 → 결정 → 대안 → 영향.

## ADR-001 모노레포는 Dart pub workspace (2026-09-29)
- **배경:** 설계서 §7.3 의 패키지 구조(`pb_sim`, `pb_ai`, `pb_data`, `app`, `sim_runner`)를 한 저장소에서 관리해야 한다.
- **결정:** Dart 3.12 에 내장된 pub workspace 를 쓴다. 루트 `pubspec.yaml` 이 멤버를 나열하고, lock 파일은 루트에 하나만 둔다.
- **대안:** melos. 설치할 도구가 하나 늘고, 지금 규모에서는 workspace 로 충분하다.
- **영향:** `flutter pub get` 은 루트에서 한 번만 실행한다. 테스트는 패키지 디렉터리에서 `dart test` 로 돌린다(`tool/verify.sh`).

## ADR-002 패키지 의존 방향: pb_sim 이 중심 (2026-09-29)
- **결정:** `pb_sim` 은 워크스페이스 패키지에 의존하지 않는다. `pb_ai`, `pb_data` 는 `pb_sim` 에만 의존한다. `app`, `sim_runner` 가 모두를 조립한다. `tool/architecture/rules.dart` 가 검사한다.
- **이유:** 전투 엔진이 도메인이고, 데이터(JSON)는 어댑터다(mozzi `domain ← data` 와 같은 방향). `pb_data` 가 JSON 을 `pb_sim` 의 정수 정의로 바꾸므로 `pb_sim` 은 JSON 을 모른다.
- **영향:** 개발 계획서 §2.1 의 의존 방향 표기를 이 결정에 맞게 고쳤다.

## ADR-003 결정론을 자동으로 검사 (2026-09-29)
- **결정:** `pb_sim`, `pb_ai` 의 lib 에서 `dart:math`, `dart:async` import, `double`/`num`/`toDouble`/`Random`/`DateTime`/`Stopwatch`/`identityHashCode` 식별자, 실수 리터럴, `/` 연산자를 금지한다. 주석과 문자열은 검사하지 않는다.
- **이유:** 설계서 §7.1, §12 “시뮬레이션 패키지에서 double 사용을 린트로 금지”. Dart 의 `int / int` 는 `double` 을 만들기 때문에 `/` 도 막는다(`~/` 사용).
- **대안:** `custom_lint` 플러그인. 의존성과 설정이 늘어나므로, mozzi 처럼 스크립트 검사로 시작한다.
- **한계:** `Map` 순회 순서 같은 규칙은 자동으로 못 잡는다 → 리뷰와 골든 해시 테스트로 잡는다.

## ADR-004 mozzi 코드는 복사 후 수정 (2026-09-29)
- **결정:** 공용 패키지로 분리하지 않고 필요한 파일을 복사해 고친다. 목록은 `docs/MOZZI_REUSE.md`.
- **이유:** mozzi 코드는 `double` 기반이고 GDD 수치와 엮여 있어 그대로 공유할 수 없다. 두 게임 모두 진행 중이라 공용 패키지의 API 를 고정하기 이르다.
- **대안:** 공용 패키지 `mozzi_kit`. 두 게임에서 안정되면(정식 출시 이후) 다시 검토한다.

## ADR-005 로컬 저장소는 Hive CE (2026-09-29)
- **결정:** 설계서 §7.4 의 “Isar 또는 Hive” 중 `hive_ce` 를 쓴다. M7 에서 추가한다.
- **이유:** mozzi 와 같은 패키지다. Isar 는 원 저장소 유지보수가 멈췄다.

## ADR-006 Android 먼저 (2026-09-29)
- **결정:** MVP 와 정식 출시는 Android 로 한다. iOS 는 출시 이후 검토한다.
- **이유:** 비공개 테스트가 Play 기준이고(설계서 §11.2), 계정은 Google Play Games Services(§7.4)다. mozzi 와 같은 방침이다.
- **영향:** `app` 은 android 플랫폼만 생성했다. applicationId 는 `com.repo.pirate_busters`.
