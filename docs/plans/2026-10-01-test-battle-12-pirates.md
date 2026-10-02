# 테스트 대전: 해적 12명을 등급별로 골라 AI 와 바로 붙기

## Context
실기기에서 해적을 몇 명밖에 못 써 봤다(사용자). 지금 막히는 이유:
- 편성 화면(`crew/crew_screen.dart:130`)은 12명을 다 보여 주지만, 코스트 한도가 Lv1 고정 15라서(`battle_setup.dart:27`) 넣을 수 있는 조합이 제한된다. 덱이 규칙에 안 맞으면 전투에서 아무 표시 없이 시작 덱(옥토·톡)으로 바뀐다(`battle_setup.dart:86`, `:112`).
- AI 와 바로 붙는 길이 없다. 캠페인 스테이지(적 덱 고정)와 핫시트(사람 둘, 상대 덱 `aiDeck` 고정)뿐이다.
- 데이터: 일반 10명, 희귀 1명(펠리), 영웅 1명(우니). 전설·신화는 아직 없다.

목표: 개발용 **테스트 대전** 화면을 만든다. 등급별로 묶인 12명 중 내 덱과 상대 덱을 마음대로 골라(코스트 무시), AI 난이도를 정하고 바로 전투한다.

## 범위·규칙
- 개발 도구라 게임 기능(설계서)이 아니다. 계획서 A9 ‘앱·문서 몫’ 에 항목 추가 + ADR-052(“개발용 테스트 대전, `DEV_TOOLS` 빌드 플래그로만 보인다”). 설계서는 고치지 않는다.
- 스토어 빌드에 안 보이게: `const bool devTools = bool.fromEnvironment('DEV_TOOLS') || kDebugMode;`. 테스트용 설치는 `--dart-define=DEV_TOOLS=true` 로 빌드.
- 전투 규칙은 그대로 pb_sim. 앱은 덱·코스트 한도·난이도만 넘긴다(절대 규칙 3).
- 화면 글자는 ko·en ARB 같은 커밋(절대 규칙 10).

## 구현
1. `app/lib/dev/dev_flags.dart`: `devTools` 상수.
2. `app/lib/dev/test_battle_screen.dart` (300줄 이하):
   - 등급별 구역(일반 / 희귀 / 영웅 …, `catalog.pirates.byId(id).rarity` 순)으로 `PirateTile`(`crew/` 기존 위젯) 재사용.
   - 위쪽 탭 “내 덱 / 상대 덱” 전환, 각 최대 4명(슬루프 선실 수 = 설계도 hull 의 선실 수), 다시 누르면 빠짐. 등급 구역 머리에 “이 등급 넣기” 버튼 없이 단순 탭만.
   - 상대 덱 비우면 “무작위 4명”(시드로 고름).
   - AI 난이도 4개(쉬움·보통·어려움·지옥) 선택칩, 시작 버튼 → `BattleScreen(test: TestBattle(deck, enemyDeck, level))`.
   - 마지막 선택은 `fleet` 상자에 `testDeck`·`testEnemy` 키로 남겨 다음에 그대로(편하게 반복 테스트).
3. `battle/battle_setup.dart`: `newTestMatch(seed, {blueprint, deck, enemyDeck})` — 양쪽 코스트 한도 `devCostLimit = 99`, 상대 설계도는 기본 추천 설계도.
4. `ui/battle_screen.dart`: 선택 인자 `TestBattle? test` 를 받아 `_start` 에서 `newTestMatch` 사용, AI 난이도는 `test.level`. 끝나면 결과 화면 없이 다시 하기/나가기(기존 핫시트 흐름과 같게). 300줄 넘으면 `_start` 를 분리.
5. `port/port_widgets.dart` `PortTopBar`: `devTools` 일 때만 벌레 아이콘 버튼(`Icons.bug_report`) → 테스트 대전. `port_screen.dart` 에 연결.
6. ARB: `devTestBattle`(테스트 대전 / Test battle), `devMyDeck`, `devEnemyDeck`, `devRandomEnemy`, `devStart`, 등급 이름은 기존 키가 있으면 재사용.
7. 계획서 A9 항목 + ADR-052, CHANGELOG 은 개발용이라 적지 않음(사용자 화면 아님), PROGRESS A9 절에 한 줄.

## 테스트
- `app/test/test_battle_test.dart`: 화면이 등급 구역별로 12명을 보여 준다, 탭하면 내 덱에 들어가고 4명 넘게는 안 들어간다, 코스트 15 넘는 덱(우니+펠리+일반 2)으로 시작해도 그 덱 그대로 판이 열린다(`newTestMatch` → `match.state.sides[0]` 해적 id 확인).
- `devTools` 가 false 면 항구에 버튼이 없다(위젯 테스트, 플래그를 인자로 주입).

## 검증
- `bash tool/verify.sh`
- `flutter build apk --release --dart-define=DEV_TOOLS=true` → `adb install -r` (기기 R3CX90JQLEB 연결 확인됨), 항구 벌레 아이콘 → 우니·펠리 포함 덱으로 AI 전 시작 확인.
