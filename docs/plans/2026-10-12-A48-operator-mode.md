# A48 운영자 모드: 비밀번호 진입·전 스테이지·해적 모션 보기·배/진행 조작 (ADR-099)


## Context
1-1부터 하나씩 깨야 스테이지를 볼 수 있어 테스트가 힘들다. 운영자가 단계와 상관없이 모든 스테이지·모든 해적·배 업그레이드·해적 모션을 바로 확인할 수 있어야 한다.
이미 A23(ADR-073) 개발 도구가 있다: 설정 ‘언어’ 7번 탭 → `devToolsProvider` 토글, 테스트 대전·더미배 연습(`dev/`), 선원 화면 해적 전원 보기, 업그레이드 창 0골드·단계 고르기(A28). 이것을 **운영자 모드**로 키운다.

사용자 결정(2026-10-12):
- 해적 레벨업(R4)은 아직 없으므로 만들지 않는다. 지금 있는 것(해적 전원·플레이어 레벨/코스트·배 업그레이드)만.
- 스테이지는 **자물쇠만 푼다**(별·진행 저장은 건드리지 않음).
- 진입: 언어 글자 7번 탭 → 설정에 ‘운영자 모드’ 버튼이 생김 → 누르면 비밀번호 창 → 맞으면 운영자 모드. ‘사용자 모드로 나가기’ 버튼도 둔다.

개발 도구라 설계서·BALANCE.md·`pb_sim` 은 바꾸지 않는다(절대 규칙 3). 끝난 A23 코드를 고치므로 계획서 12장 끝에 **A48** 으로 넣는다(절대 규칙 11).

## 진입·종료 흐름
1. `dev/dev_flags.dart`
   - `devToolsProvider`(이름 유지, 뜻 = 운영자 모드 켜짐)는 **저장값만** 따른다. `kDebugMode` 강제 켜짐(`devToolsBuild`)을 없앤다 — 나가기 버튼이 디버그에서도 동작하게. 
   - `toggle()` 대신 `enter(String password) → bool`(SHA-256 비교, 맞으면 저장 on), `exit()`(저장 off).
   - `operatorRevealProvider`(세션 한정 bool): 7번 탭으로 버튼을 드러낸다.
   - 비밀번호는 `operatorPassHash`(SHA-256 hex 상수)만 둔다. `crypto` 패키지(이미 lock 에 transitive)를 app 직접 의존으로 추가 → ADR 에 기록.
2. `dev/dev_tools_switch.dart`: 7번 탭이면 토글 대신 `operatorRevealProvider = true` + 토스트(“운영자 버튼이 나타났다”).
3. 새 `dev/operator_entry.dart`: 설정 화면에 붙는 줄.
   - 드러났고 꺼져 있으면 ‘운영자 모드’ 버튼 → 비밀번호 창(가림 입력, `PbDialog` 계열) → 맞으면 토스트·켜짐, 틀리면 토스트.
   - 켜져 있으면 ‘사용자 모드로 나가기’ 버튼.
   - `port/settings_screen.dart` 에 한 줄 추가.

## 운영자 화면 (항구에서 진입)
- `port/port_widgets.dart` `PortTopBar`: 기존 `onTestBattle` 자리를 `onOperator`(운영자 아이콘)로 바꾸고 `port_screen.dart` 가 `OperatorScreen` 을 연다(켜져 있을 때만).
- 새 `dev/operator_screen.dart` (`PbScaffold`, 300줄 이하로 쪼갬):
  - **스테이지**: 해역 1 튜토리얼 t-1~t-3 + 1-1~1-5·1-12 전부 버튼 → `BattlePrepScreen(stage:)` 바로 연다. (`campaignProvider`·`StageSpec`)
  - **해적**: ‘해적 모션 보기’ → `MotionViewerScreen`, ‘테스트 대전·더미배 연습’ → 기존 `TestBattleScreen`.
  - **배**: ‘배 업그레이드 창’ → 기존 `showShipUpgrades`(이미 0골드·단계 고르기), ‘배 전부 최대로’(단계 4·재질·모듈·돛대 최대·선형 레벨 최대를 저장, `ShipUpgrades` 필드로 구성).
  - **진행**(명시 버튼으로만 저장을 바꿈): 골드 +10,000, 플레이어 레벨 최대(코스트 한도), 해적 전원 받기(`addPirate`), 진행 초기화(확인 창, `const PlayerProgress()`).
  - 맨 아래 ‘사용자 모드로 나가기’.

## 운영자 모드에서 풀리는 자물쇠
- `campaign/campaign_map_screen.dart`: 켜져 있으면 튜토리얼+캠페인 노드를 모두 보이고 모두 연다(`open(i)` → true). 저장은 그대로.
- 조선소 열림(`port_screen.dart` `shipyardUnlocked`) 무시.
- 코스트 한도: 새 `dev/operator_limits.dart` 의 `costLimitOf(ref)` = 켜짐이면 `TestBattle.costLimit`(99), 아니면 `progress.costLimit`. `crew_screen.dart`(2곳)·`battle_prep_screen.dart`·`ui/battle_screen.dart:102` 에서 쓴다(파라미터만 바뀌고 판정은 pb_sim 그대로).
- 선원 화면 해적 전원 보기는 기존대로 `devToolsProvider` 를 따른다.
- 판을 깨면 별·골드는 평소처럼 저장된다(그대로 둠).

## 해적 모션 보기
- 새 `dev/motion_preview_game.dart`: `FlameGame`. `PbAnims.fromJsonString(rootBundle…PbAnims.path)` 로 읽고(`port/port_game.dart` 와 같은 방식) `CharacterRig.load(images, catalog.speciesOf(id), team, states: anims.states)` 를 가운데 크게 둔다. `rig.tier` 는 등급 연출(`anims.rarity`).
  - `play(motion)`: 대기(`state=null`), 공격(`anims.attacks[species]`, glint), 피격(`anims.hit`, expr hit), 상태 aim·fall·swim·win·lose(`rig.state`), 반복 재생 켜기.
- 새 `dev/motion_viewer_screen.dart`: 위쪽 해적 40명 줄(기존 `PracticeBar(deck:[선택], onPick:)` 재사용), 동작 칩, 팀 파랑/빨강 전환, `GameWidget`.

## 글자 (ko·en 같은 커밋, 절대 규칙 10)
`operatorMode, operatorEnter, operatorExit, operatorPassword, operatorWrongPassword, operatorOn, operatorOff, operatorRevealed, operatorStages, operatorPirates, operatorShip, operatorProgress, operatorMotions, operatorShipMax, operatorGold, operatorLevelMax, operatorAllPirates, operatorReset, operatorResetAsk, motionIdle, motionAttack, motionHit, motionAim, motionFall, motionSwim, motionWin, motionLose, motionTeamBlue, motionTeamRed, motionLoop`. 기존 `devToolsOn/Off` 는 쓰지 않으면 지운다.

## 문서
- 계획서 12장 끝 `A48` 절(체크리스트·완료 조건), ADR-099(운영자 모드·비밀번호 해시·디버그 강제 켜짐 제거·crypto 추가), PROGRESS·CHANGELOG `[Unreleased]`, docs/plans 색인. 설계서·BALANCE 무변경 → 해시 그대로.
- A23 절에 “A48 에서 운영자 모드로 바뀜” 한 줄.

## 브랜치·공유 트리
- 다른 세션 미커밋 파일(battle_screen.dart 등)이 있으므로 작업 트리를 건드리지 않고 지금 HEAD 에서 `feat/A48-operator-mode` 를 만든다(전후 SendMessage 알림). 커밋은 내 경로만 add, 겹치는 파일(`ui/battle_screen.dart`·CHANGELOG·PROGRESS·DECISIONS·계획서·plans/README)은 HEAD + 내 블록만 인덱스에 올린다. 커밋은 사용자 요청 때만.

## 테스트 (`app/test/operator_mode_test.dart`, 한국어 이름)
- 7번 탭하면 운영자 버튼이 보이고, 틀린 비밀번호는 거절, 맞는 비밀번호면 켜지고 저장된다; 나가기면 꺼진다.
- 켜지면 캠페인 지도의 모든 스테이지(튜토리얼 포함)가 열리고, 꺼지면 원래 규칙.
- 운영자 화면 스테이지 버튼이 전투 준비 화면을 연다.
- 배 전부 최대로·골드·레벨·해적 전원·초기화가 진행을 바꾼다.
- 모션 보기 게임이 해적을 불러오고 동작을 바꿔도 오류가 없다.
- `dev_practice_test.dart`·`test_battle_test.dart` 의 7번 탭/버튼 기대값을 새 흐름에 맞게 고친다(지우지 않음).

## 검증
- `bash tool/verify.sh` 통과(다른 세션 파일 때문에 실패하면 그 세션에 알림).
- `cd app && flutter run` 으로 실제 흐름 확인: 설정 7번 탭 → 버튼 → 비밀번호 → 항구 운영자 버튼 → 1-12 바로 진입, 모션 보기에서 40명 동작, 배 최대·나가기.
- `rules-reviewer` 검토.
