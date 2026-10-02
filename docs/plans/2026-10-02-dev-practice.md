# 개발 도구: 빌드 앱 숨은 스위치 + 더미배 폭탄투하 연습 (A23 제안, ADR-073)

## Context
- 테스트 대전·해적 전원 편성(ADR-053)은 `devTools` 상수(`kDebugMode || DEV_TOOLS`)에 묶여 있다. 그래서 사용자가 설치한 release 빌드에서는 안 보이고, 해적 전원을 시험해 볼 수 없다.
- 반격하지 않는 표적 배(더미배)에 해적을 바꿔 가며 폭탄투하를 연습하고 싶다.
- 사용자가 고른 것: **숨은 스위치**, **반격 없는 배**(전투 규칙은 그대로), **턴마다 아무 해적이나**.
- 게임 기능이 아니라 개발 도구라서 설계서는 고치지 않는다(ADR-053 선례). 새 기능이므로 계획서 12장 끝에 **A23** 으로 넣고 ADR-073 을 남긴다(절대 규칙 7·11).

## 제약과 절충 (확인 필요)
- 전투 엔진(pb_sim)에서 출전 해적은 선실 4칸(`HullSpec.sloop.cabinSlots`)에 고정되고, 판 도중에 바꾸는 커맨드가 없다. 판 중간 교체를 넣으려면 규칙(설계서)을 바꿔야 한다(절대 규칙 3).
- 그래서 **"턴마다 아무 해적이나"는 앱에서만 처리한다.** 연습 화면 위쪽 줄에 해적 12명을 모두 띄우고, 하나를 누르면 그 해적을 맨 앞 선실에 넣은 덱으로 **연습판을 바로 새로 시작**한다(시작 시간 1초 안). 이때 **더미배 손상은 처음 상태로 돌아간다.** 손상을 이어 가려면 pb_sim 규칙을 바꿔야 해서 이번에는 하지 않는다.
- 덱 안에 있는 해적끼리는 교체 없이 그 판에서 계속 쏜다. 판이 끝나면(더미배 침몰·30턴) 결과 화면 대신 같은 덱으로 자동 재시작한다.

## 구현

### 1. 숨은 스위치 (`devTools` 상수 → 상태)
- `app/lib/dev/dev_flags.dart`: `devToolsBuild` 상수(지금 식 그대로)와 `devToolsProvider`(Riverpod `Notifier<bool>`)를 둔다. 초기값 = `devToolsBuild || settings.devTools`. `toggle()` 은 설정에 저장한다.
- `app/lib/settings/settings_store.dart`: `devTools` get/set 을 `HiveSettingsStore`(키 `dev_tools`)와 `MemorySettingsStore` 에 추가한다(기존 `lowEnd` 패턴).
- `app/lib/port/settings_screen.dart`: 패널을 `DevToolsSwitch` 로 감싸 버튼이 아닌 곳(‘언어’ 글자)을 **7번 연속 탭**하면 토글한다(골든을 깨지 않게 화면 모양은 그대로). 켜지거나 꺼질 때 스낵바로 `devToolsOn`/`devToolsOff` 를 띄운다.
- `app/lib/port/port_screen.dart:130`: `devTools` → `ref.watch(devToolsProvider)`.
- `app/lib/crew/crew_screen.dart:18`: `showAll` 을 `bool?` 로 바꾸고 null 이면 `ref.watch(devToolsProvider)` 를 쓴다(테스트의 `showAll: false/true` 는 그대로 동작한다).

### 2. 더미배 연습
- `app/lib/dev/test_battle.dart`: `TestBattle` 에 `dummy` 필드와 `withLead(String id)`(id 를 0번 슬롯에 넣고, 이미 덱에 있으면 앞으로 옮기고, 넘치면 끝을 뺀다)를 추가한다.
- `app/lib/ui/battle_screen.dart:101`: `test?.dummy == true` 이면 상대를 `ScriptedController(const [])`(pb_sim `controller.dart:16`, 매 턴 빈 묶음 → 바로 `END_TURN`)로 만든다. AI 도 사람과 같은 커맨드만 낸다는 규칙(절대 규칙 4)을 그대로 지킨다. 더미배 설계도는 기본 추천 설계도, 덱은 기존 `randomDeck`(한 명 이상 있어야 하므로)을 쓴다.
- `app/lib/dev/practice_bar.dart`(새 파일): 연습판일 때 전투 화면 위에 겹치는 가로 해적 줄(12명, `PirateTile` 축소판, 덱 안 해적 표시). 탭하면 `Navigator.pushReplacement(BattleScreen(test: test.withLead(id), seed: 다음))`.
- 판이 끝났을 때 `battle_screen` 의 `_checkOver` 에서 연습판이면 결과 처리·분석 기록 대신 같은 덱으로 다시 시작한다. battle_screen 은 300줄 제한 안에서 분기만 넣고 나머지는 `dev/` 에 둔다.
- `app/lib/dev/test_battle_screen.dart`: 시작 버튼 옆에 **더미배 연습** 버튼을 둔다(내 덱만 있으면 된다. 상대 덱·난이도는 무시한다).

### 3. 글자 (ko·en 같은 커밋, 절대 규칙 10)
`devToolsOn`, `devToolsOff`, `devPractice` → `app_ko.arb`·`app_en.arb`, `flutter gen-l10n`.

### 4. 문서
- `docs/DECISIONS.md` ADR-073: 숨은 스위치(release 빌드도 켤 수 있음, 출시 전에 ADR-029·053 과 함께 뺄지 다시 본다), 더미배 = 빈 턴 컨트롤러, 해적 교체 = 새 판(손상 초기화) 절충.
- 계획서 12장 끝에 A23 (작업·완료 조건). 기준 문서 해시는 바뀌지 않는다.
- `docs/plans/README.md` 색인 한 줄, 이 계획 파일 이름은 `2026-10-02-dev-practice.md`.
- 끝날 때 PROGRESS·CHANGELOG `[Unreleased]`.

## 작업 트리 주의
- 다른 세션이 같은 폴더에서 A15·A16(메타 화면, `settings_screen`·`port_screen`·`ui/kit/`)을 작업 중이다. 브랜치 `feat/A23-dev-practice` 로 바꾸기 전에 알리고, `git add` 는 내가 고친 경로만 한다. `settings_screen.dart`·`port_screen.dart` 는 겹치므로 수정 범위를 몇 줄로 최소화한다.

## 테스트
- `app/test/dev_practice_test.dart`(한국어 테스트 이름):
  - 설정 화면 ‘언어’ 글자를 7번 누르면 스위치가 켜지고 다시 7번이면 꺼진다.
  - 개발 도구가 켜지면 편성 화면에 해적 전원이 보인다.
  - `withLead` 는 고른 해적을 0번 슬롯에 넣고 4명을 넘지 않는다.
  - 더미배 연습에서 상대 턴은 쏘지 않고 바로 넘어간다(세션을 몇 턴 진행시키고 상대 발사 0).
  - 연습 줄에서 해적을 누르면 그 해적이 맨 앞인 새 판이 열린다.
- 기존 `a9_screens_test`·`screens_test`·골든이 그대로 통과하는지 본다.

## 검증
1. `bash tool/verify.sh` 통과.
2. `cd app && flutter build apk --release` 로 만든 앱을 설치 → 설정 ‘언어’ 글자 7번 탭 → 항구 벌레 아이콘 → 테스트 대전 → 더미배 연습 → 해적 줄에서 12명을 차례로 바꿔 가며 쏴 본다(사용자 실기기 확인).
3. `rules-reviewer` 검토.
