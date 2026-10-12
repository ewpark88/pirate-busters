# 물수제비탄 개편 · 연사 집중/산발 분리 · 쉬는 턴 표시와 자동 턴 넘김 — 계획

> 계획 모드에서 작성(2026-10-12), 사용자 승인. 계획서 12장 A51~A53, ADR-102.

## Context

사용자 요청 세 가지 (2026-10-12):

1. **물수제비탄(수리·핑구·셀던·돌피·오르카)이 사실상 100% 명중한다.** 원인(코드 조사):
   - 짧게 떨어진 탄도 수면에서 다시 뜬다(`hit_effects.dart:206-215`, 세로 ×0.55·가로 ×0.85). 일반 2회만으로도 배 앞 약 0.69R 안에 떨어진 탄이 배까지 간다.
   - 마지막 튕김은 수면 바로 위를 거의 수평으로 날아 선체 옆면(흘수선~갑판)을 피할 수 없다.
   - 입사각 조건이 없어 가파르게 떨어져도 튕긴다.
   - BALANCE A2.6 의 "멀면 튕김이 모자라 빗나감"이 구현되지 않았다(`armShot` 은 사다리 값 고정, `ammo_rules.dart:113`).
   - 한 번이라도 튕기면 맞은 칸과 상관없이 ×1.5(`hit_effects.dart:145`).
   - A43 플레이 감사(`docs/quality/2026-10-12-a43-play-audit.md:47,60`)에서도 같은 거리·쉬움 난이도에서 수리만 맞혔다.
   → **사용자 선택: 탄종은 유지하고 튕김 조건을 강화한다.**
2. **연사를 집중형/산발형으로 나눈다.** 지금은 `_fanOffset` 고정 부채꼴 하나뿐(`ammo_rules.dart:98`). 연사 해적은 히포(일반 3발, 4°)와 라이언(영웅 12발, 12°) 둘이다.
   → **사용자 선택: 히포 = 집중, 라이언 = 산발.**
3. **쉬는 턴을 해적 머리 위에 보이고, 쏠 해적이 하나도 없으면 자동으로 턴을 넘긴다.** 지금 쉬는 턴은 HUD 카드(`pirate_cards.dart:87-115`)에만 보이고, 전장의 해적 그림(`ship_view.dart:170-210`)에는 없다. 자동 종료는 "2발 다 쏨"일 때만(`battle_session.dart:127-131`) 걸려 25초를 기다리게 된다.
   → **사용자 선택: 이동할 수 있으면 짧게 이동 기회를 준 뒤 넘기고, 이동도 못 하면 바로 넘긴다.**

세 가지 모두 설계서·BALANCE.md 의 규칙·수치를 바꾸므로, CLAUDE.md 규칙대로 **기준 문서 수정을 먼저 제안·승인받고** `/doc-sync` 로 계획서에 반영한 뒤 구현한다. 모두 끝난 단계(M3·M4·M6 등)의 코드를 고치므로 계획서 12장 끝에 새 단계로 넣는다(절대 규칙 11). A50 은 조선소 계획이 쓰고 있으므로 **A51·A52·A53** (착수 때 번호 다시 확인).

## 0. 착수 전 정리

- 작업 트리에 다른 세션의 병합 충돌(`UU` CHANGELOG·계획서·DECISIONS·PROGRESS·plans/README)이 남아 있다. 그 세션 작업이 `main` 에 들어간 뒤 최신 `main` 에서 브랜치를 딴다. 공유 작업 트리 규칙(내 경로만 `git add`)을 지킨다.
- 단계마다 브랜치: `feat/A51-skip-rework`, `feat/A52-burst-patterns`, `feat/A53-rest-badge-autopass`. 끝나면 verify → 커밋 → push → main 병합 → main push (ADR-098).
- 세 단계는 서로 독립이다. 체감이 크고 위험이 작은 **A53 → A52 → A51** 순서로 진행한다(A51 은 밸런스 측정이 필요해 가장 길다).

## 1. 기준 문서 수정 제안 (사용자 승인 후 반영)

설계서·BALANCE.md 는 직접 고치지 않는다. 아래 문안을 보여 주고 승인받은 뒤 같은 커밋에서 계획서·해시를 맞춘다(`/doc-sync`, ADR 1건: ADR-102 "물수제비 튕김 조건·연사 패턴·자동 턴 넘김").

| 문서 § | 바꿀 내용 |
|---|---|
| 설계서 §2.2 턴 종료 | "쏠 수 있는 해적이 하나도 없으면 안내 문구를 띄우고 자동으로 턴을 넘긴다. 이동할 수 있으면 이동 유예(BALANCE A2.3) 뒤에 넘긴다. 이번 턴에 이미 쏜 뒤 더 쏠 해적이 없으면 2발 뒤와 같은 유예로 끝난다." |
| 설계서 §2.8·§4.1·§4.8 물수제비 | "얕은 각도로 수면에 닿을 때만 튕기고, 가파르면 첨벙. 튕길 때마다 크게 느려진다. 멂이면 튕김 −1. ×1.5 는 흘수선 칸에 맞을 때만." |
| 설계서 §4.2·§4.3·§4.8 연사 | 연사 패턴 키 `pattern: focus|scatter`. 집중 = 모든 발이 같은 각도로 한 점을 연타, 산발 = 발마다 매치 시드 난수로 각도·세기가 흔들림. 히포 '집중 쌍권총', 라이언 '산발 가시 부채꼴'. |
| 설계서 §13.4 | "쉬는 해적은 전장의 머리 위에도 남은 쉬는 턴 수를 보이고, 쉬는 턴이 풀리는 내 턴 시작에 '준비' 연출을 한다." |
| BALANCE A2.3 | 자동 넘김 이동 유예 **3.0초** (제안값, 임시). |
| BALANCE A2.6·A4.8 물수제비 | 튕김 입사각 상한 **25°**(정수: `|vy|×1000 ≤ |vx|×466`), 튕김 감쇠 세로 **×0.45**·가로 **×0.70**(지금 0.55·0.85), 멂 튕김 **−1**(최소 1). 모두 임시값(ADR-035 방식). |
| BALANCE A4.3 | 흘수선 ×1.5 조건을 "튕긴 뒤 흘수선 줄 칸에 맞을 때"로 명시. B3 계산표 재계산. |
| BALANCE A4.8 연사 | 집중: 퍼짐 0. 산발: 각도 ±spreadDeg/2 균등 난수, 세기 ±**8%** 균등 난수. 라이언 spreadDeg 12 유지, 히포 spreadDeg 0. |

수치를 고르는 근거: A51 에서 sim_runner 명중률 계측을 먼저 넣고, 제안값으로 "보통 AI 의 물수제비 명중률이 직사·곡사 계열과 ±10%p 안"이 나오는지 확인한 뒤 확정값을 BALANCE 에 올린다(밸런스 커밋 `balance(sim): …`).

## 2. A53 쉬는 턴 표시 · 자동 턴 넘김 (`sim` 조회 + `app`)

**pb_sim (규칙 판정만, 조회 함수)**
- `match/match_state.dart` `SideState` 에 `bool get anyCanFire`(모든 슬롯 `canFire`)와 `bool get canMove`(연료 > 0 && !moveLocked — 지금 `move_controls.dart:55-61` 의 조건과 `match.dart:173` `_move` 검사를 한곳으로) 추가. 커맨드·판정 흐름은 바꾸지 않는다: 시뮬은 지금처럼 스스로 턴을 닫지 않고, END_TURN 은 컨트롤러가 낸다(`match.dart:256` 주석 방침 유지). AI 는 이미 쏠 해적이 없으면 스스로 END_TURN 을 낸다 — 테스트로 확인만.

**app — 자동 넘김**
- `battle/battle_session.dart` `_autoEndDue`(:127) 확장:
  - 내 턴 시작에 `!anyCanFire` → 안내 표시 + `canMove` 면 이동 유예(BALANCE A2.3, `auto_end.dart` `AutoEndClock` 재사용, 유예 값만 다르게) 뒤 `EndTurnCommand`, 못 움직이면 안내가 보이는 짧은 시간(1.0초, 기존 유예) 뒤 바로.
  - 턴 중간에 한 발 쏜 뒤 더 쏠 해적이 없으면 기존 '2발 뒤'와 같은 1.0초 유예로 끝냄(안내 문구 없음).
  - 이 자동 넘김은 '2발 뒤 자동 턴 종료' 설정과 별개로 늘 켠다(할 수 있는 일이 없는 턴이므로).
  - 사람 턴에만 안내를 띄운다(AI 턴·관전에는 없음). 둘이서(hotseat) 모드는 두 사람 모두에게.
- 안내 배너: `ui/hud/boss_banner.dart` 패턴을 따라 `ui/hud/no_shooter_banner.dart` 새로 만듦. l10n 키 `noPirateCanFire`:
  - ko: "공격할 수 있는 해적이 없습니다. 턴을 상대방에게 넘깁니다"
  - en: "No pirate can attack. Passing the turn to your opponent."
- 튜토리얼 스테이지에서 강제로 기다리게 하는 단계가 있는지 착수 때 확인(있으면 그 판은 자동 넘김을 끈다).

**app — 머리 위 쉬는 턴 표시**
- 새 컴포넌트 `game/view/rest_badge.dart`: 쉬는 해적 머리 위에 모래시계 아이콘 + 남은 쉬는 턴 숫자(양쪽 배 모두). `ship_view.dart` rig 갱신(:170-210)에서 슬롯별로 붙이고, 쓰러진 해적(alpha 0)·바다에 빠진 해적에는 숨긴다.
- 숫자 계산은 HUD 카드와 같아야 하므로 `pirate_cards.dart:87-93` 의 계산(이번 턴 쏜 해적은 `cooldown - 1`)을 `battle/rest_turns.dart` 의 함수 하나로 빼서 둘이 같이 쓴다.
- 쉬는 턴이 0 이 되는 **내 턴 시작**에 배지가 튀어 오르며 '준비!' 문구(l10n 키 `pirateReady`: ko "준비!", en "Ready!")로 바뀌고 0.8초 뒤 사라진다. `fx_text.dart` `emphasis` 를 재사용.
- 숫자가 줄어드는 순간(턴 끝 `onTurnEnd`, `battle_game.dart:193`)에 짧은 눌림 애니메이션.

**테스트**
- pb_sim: "모든 해적이 쉬면 anyCanFire 는 거짓이다", "연료가 없거나 묶이면 canMove 는 거짓이다", "AI 는 쏠 해적이 없으면 END_TURN 을 낸다".
- app: "쏠 해적이 없고 움직일 수 없으면 1초 안에 상대 턴이 된다", "움직일 수 있으면 이동 유예 뒤에 상대 턴이 된다", "안내 배너가 사람 턴에만 보인다", "머리 위 쉬는 턴 숫자가 카드 숫자와 같다", "쉬는 턴이 풀린 턴 시작에 준비 표시가 나온다". 기존 `auto_end` 테스트 회귀 확인.

## 3. A52 연사 집중·산발 (`sim` + `data` + `app`)

- `pb_sim/lib/src/pirate/pirate_spec.dart`: `BurstPattern { focus, scatter }` 필드 추가(기본 focus).
- `pb_sim/lib/src/combat/ammo_rules.dart` `launchVolley`:
  - focus: 모든 발이 `aim` 그대로(퍼짐 0) — 같은 칸을 연타.
  - scatter: 발마다 `state.rng` 로 각도 ±spreadMdeg/2, 세기 ±8%(정수 permille) 균등 난수. id 순으로 뽑아 결정론 유지. 분열탄의 `_fanOffset` 은 그대로.
  - `previewShot` 은 이미 난수를 되돌리므로(`preview.dart:54,87`) 그대로 쓴다. AI 미리보기는 실제와 같은 흔들림을 보게 되는데, 직사 멂 흔들림(`ammo_rules.dart:45`)과 같은 기존 방식이라 유지한다.
- `pb_data/lib/src/pirate_def.dart`: `ammo.pattern` 읽기(`focus|scatter`, 연사 아닌 탄에 있으면 오류, scatter 는 spreadDeg > 0 필수) 검증 추가.
- `app/assets/game/pirates.json`: 히포 `{"type":"burst","pattern":"focus","spreadDeg":0}`, 라이언 `{"type":"burst","pattern":"scatter","spreadDeg":12}`.
- `app/assets/data/weapons.json` 의 hippo·lion 연사 값(라이언 설명 "5발" 등)이 시뮬과 어긋남 → 설명 키·값을 맞춘다(렌더가 실제로 읽는 값만).
- 조준 화면: 산발 해적을 조준할 때 궤적 끝에 흐린 부채꼴(퍼짐 범위)을 그려 '흩어진다'를 보여 준다. 집중은 지금 궤적 그대로. 카드·도감 설명 l10n 키 갱신(ko/en 동시).
- 테스트: "집중 연사는 모든 발의 각도가 같다", "산발 연사는 같은 시드면 같은 각도·세기를 낸다(해시)", "산발 각도는 ±spread/2 를 넘지 않는다", "pattern 이 연사 아닌 탄에 있으면 로드 오류", 기존 `ammo_test.dart:177`·`r1a2_unique_test.dart:113-150` 갱신, 재현성 해시 테스트 갱신.

## 4. A51 물수제비 튕김 조건 강화 (`sim` + `balance`)

- 먼저 계측: `tools/sim_runner` 에 탄종 계열별 명중률(발사 수 대비 `impact` 이벤트, `splash` 수) 집계 추가(`report.dart`). 바꾸기 전 기준값을 기록한다.
- `combat/hit_effects.dart` `bounceOffSea`(:206): 입사각 조건(`|vy|×1000 > |vx|×skipMaxSlopePermille` 이면 튕기지 않고 첨벙), 감쇠값을 상수로(`skipBounceVyPercent`, `skipBounceVxPercent`, BALANCE 참조 주석).
- `combat/ammo_rules.dart` `armShot` skip: `Reach.far` 면 `bouncesLeft − 1`(최소 1). 파도 사냥꾼 세트 +1 과 상한(+2)은 그대로.
- `combat/hit_effects.dart:145`: ×1.5 를 `p.bounced && 맞은 칸이 흘수선 줄` 일 때만. 흘수선 줄 판정은 침수 규칙에 이미 있는 함수를 재사용(착수 때 확인).
- 고유 능력 점검: 셀던 ricochet(`unique_effects.dart:64-98`)은 벽에서 되튀는 것이라 입사각 조건과 무관하게 유지, 돌피·핑구·오르카는 영향만 테스트로 확인.
- AI(`pb_ai/aim_solver.dart`)는 `previewShot` 으로 실제와 같은 계산을 하므로 코드 변경 없음. 다만 튕김 후보가 줄어 명중 후보가 없을 때 직접 맞히기로 넘어가는지 확인.
- 측정 → BALANCE 확정값 반영(`balance(sim)` 커밋, B부 재계산, `/doc-sync`).
- 테스트: "가파르게 떨어진 물수제비탄은 튕기지 않는다", "얕게 닿으면 튕기고 속도가 감쇠값만큼 준다", "멀면 튕김 수가 하나 준다", "흘수선이 아닌 칸에는 ×1.5 가 붙지 않는다", 재현성 해시 테스트 갱신, `ammo_test.dart:215-220` 갱신.

## 수정할 주요 파일

- 기준 문서(승인 후): `Pirate Busters 게임 설계서.md`, `docs/BALANCE.md`, `Pirate Busters 개발 계획서.md`(12장 A51~A53, 동기화 해시), `docs/DECISIONS.md`, `docs/STATUS.md`, `docs/PROGRESS.md`, `CHANGELOG.md`
- pb_sim: `combat/ammo_rules.dart`, `combat/hit_effects.dart`, `match/match_state.dart`, `pirate/pirate_spec.dart`
- pb_data: `pirate_def.dart`
- 데이터: `app/assets/game/pirates.json`, `app/assets/data/weapons.json`
- app: `battle/battle_session.dart`, `battle/auto_end.dart`, `battle/rest_turns.dart`(새), `game/view/ship_view.dart`, `game/view/rest_badge.dart`(새), `ui/hud/no_shooter_banner.dart`(새), `ui/hud/pirate_cards.dart`, `ui/hud/move_controls.dart`, l10n arb 2개
- tools: `tools/sim_runner/lib/src/report.dart`

## 검증

1. 단계마다 `bash tool/verify.sh` 통과(결정론·300줄·l10n·doc sync 포함).
2. `dart run tools/sim_runner/bin/sim_runner.dart --games 500 …` 로 바꾸기 전/후 계열별 명중률·승률 비교. 물수제비 명중률이 직사·곡사와 ±10%p 안인지 확인하고 결과를 PROGRESS 에 적는다.
3. 앱 실행(`cd app && flutter run`, 웹 빌드 가능 시 Chrome)으로 확인: 머리 위 쉬는 턴 숫자·준비 연출, 쏠 해적 없는 턴의 안내 문구와 자동 넘김(이동 가능/불가 두 경우), 히포 집중 연타·라이언 흩뿌림, 물수제비가 가파른 각도에서 첨벙하는지. 캡처를 `docs/quality/` 에 남긴다.
4. 손맛·실기기 확인은 사람 몫으로 보고에 적는다.
