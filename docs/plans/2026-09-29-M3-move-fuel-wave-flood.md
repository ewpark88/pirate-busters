# M3 — 이동·연료·파도·침수·시간 판정 (`pb_sim`)

## Context
M2(턴 루프·탄도·타격·붕괴)는 검증을 끝냈다(체크박스·PROGRESS·현재 단계 M3·버전 0.2.0, 커밋 전). 다음은 개발 계획서 M3: 배라서 생기는 차별화(이동·연료·파도·침수·기울기)와 30턴 뒤 시간 판정을 `pb_sim` 에 넣는다 (설계서 §2.4~§2.7, §3.4, §7.2).
사용자 결정: 침수는 **자기 턴 끝에 자기 배만**, 구멍 = **원래 블록 칸 중 파괴됐거나 ‘구멍’ 단계(HP ≤ 1/3)**, 파도 위상은 **FIRE 의 `t`** 로 계산, 기울기는 **충돌 격자까지 회전**.

## 0. 브랜치 정리 (계획 승인 = 이 git 작업 승인)
1. `feat/M2-ballistics` 에 M2 검증 변경 커밋: `docs(docs): M2 완료 기록, 버전 0.2.0` (+ match_test 복귀 통합 테스트), push.
2. `main` 에 `feat/M2-ballistics` 를 `--no-ff` 머지, verify 확인 후 `main` push (M1 머지 등 로컬 커밋 포함).
3. `main` 에서 `feat/M3-sea` 브랜치 생성.

## 1. 규칙 수치 — `lib/src/match/rules.dart` (`MatchRules` 확장)
- 폭풍: `stormTurns = 4`(27~30턴), `stormTurnTimeMs 20000`, 바람 ×2, 파도 ×1.5(150%), 침수 ×1.5, 후퇴 한계 2칸 당김, 연료 +30.
- 파도: `wavePeriodMs 2000`(고정), `waveBob`(1/1000칸, 스테이지 값, 기본 250), `waveRollMdeg`(기본 2000). 진영 1 은 위상 180° 차이.
- 연료: `fuelRegen 30`. 판정: `judgeFloodTieBp 100`(1%p).
- `toJson`/리플레이에 새 필드 추가.

## 2. 선형·격자
- `ship/hull.dart`: `fuelTank`(슬루프 80), `fuelPerCell`(슬루프 8) (§2.7).
- `ship/ship_grid.dart`: 시작 재질 보관(`wasBlockAt`), `isHole(x, y)` = 원래 블록 칸 && (파괴 || 단계 holed), `totalWeight`(재질 무게 합, 코르크 음수).

## 3. 좌표·자세 — `world/world.dart` `ShipFrame` 확장
- 뱃머리 x 에 더해 `yOffset`(흘수·내려앉기·파도 bob)과 `tiltMdeg`(기울기 + 파도 roll)를 가진다. 회전 중심 = 선체 가운데 x, 해수면 높이.
- `toLocal(wx, wy)`, `toWorld(lx, ly)`: `sinMicro/cosMicro`(기존 `math/trig.dart`)와 `roundDiv`(기존 `math/fx.dart`)로 정수 회전. **선분은 회전해도 선분이라, 끝점 두 개만 로컬로 바꿔 기존 `traceCells`(DDA)를 그대로 쓴다** → 충돌 격자 회전.
- 기존 `toLocalX`/`toWorldX`/`cellCenter` 호출부(`combat/flight.dart`, `match/match.dart`, `test/aim.dart`)를 2D 변환으로 바꾼다.

## 4. 새 파일
- `ship/buoyancy.dart`: 
  - 기본 흘수 = (총무게 − 부력) ÷ (선형 폭 × 3) — 계수 3 은 임시(설계서 공식 그대로면 표본 배가 4.2칸 잠김, ADR).
  - 내려앉기 = 침수량 비율 × (선형 높이 − 기본 흘수) ÷ 2 (임시).
  - `floodGainBp(side)`: 구멍 칸마다 회전·오프셋 적용한 칸 위·아래가 해수면 아래면 +300bp(3%p), 걸치면 +150bp. 폭풍 ×1.5.
  - 기울기 = (뱃머리 절반 − 선미 절반의 흘수선 아래 구멍 수) × 1° , ±8° 제한 (임시). 뱃머리 쪽이 뚫리면 앞으로 숙인다.
- `world/wave.dart`: 정수 사인파. `bob(tMs, side, rules, storm)`, `roll(...)` — `sinMicro` 사용.
- `match/turn_phases.dart`: `match.dart` 300줄 제한 때문에 턴 시작·끝·폭풍·판정 처리를 분리.

## 5. 상태·커맨드·턴 흐름
- `SideState`: `offset`(1/1000칸, 전진 +), `backLimit`/`frontLimit`(±4칸), `fuelTenths`(연료 ×10: 슬루프 800, 1/10칸당 8), `floodBp`(0~10000), `draft`, `listTilt`. `bowX = startBowX + facing × offset`.
- `command.dart`: `MoveCommand(t, dx)` — dx 는 1/10칸, JSON `{"t","type":"MOVE","dx"}` (§7.2).
- `match.dart` MOVE 적용: 내 턴, 제한 시간 안. 한계선으로 자른 뒤 연료로 갈 수 있는 만큼(`fuelTenths ÷ fuelPerCell`)만 간다. 한계선에 막힌 거리는 연료를 쓰지 않는다. 0 이면 무시.
- 발사: 쏘는 쪽 자세 = FIRE `t` 시점(파도 roll + 기울기). 발사각에 기울기를 더하고 발사 위치도 회전 좌표. 비행 중 매 틱 상대 배 자세 = `t + 틱×1000/30` 시점 파도 → 틱마다 `frameAt(ms)` 로 판정.
- 턴 시작: (27턴이면 폭풍 시작: 양쪽 연료 +30, 후퇴 한계 −2칸으로, 넘어 있으면 한계로 당김) → 연료 +30(상한) → 바다에 빠진 해적 복귀.
- 턴 끝(자기 배만): 화재(M5) → **침수량 += floodGain** → 수리·펌프(M5) → 쿨다운 → 흘수·기울기 다시 계산 → 바람. 침수량 ≥ 100% 면 격침.
- 턴 시간: 폭풍 턴은 20초.
- 판정(30턴 끝): `MatchOutcome.timeJudgement` 추가 — 침수량 적은 쪽 승; 차이 ≤ 1%p 면 선체 내구도 비율(`totalHp/initialTotalHp`, 교차 곱 비교) 높은 쪽; 같으면 무승부. `turnLimit` 는 판정으로 바꾼다.
- 이동 속도 헬퍼 `moveSpeed(side)` = 선형 속도 × (1 − 침수량 × 0.6) — 앱의 연출·턴 시간용, 판정에는 안 쓴다.
- 해시에 offset·한계·연료·침수량·흘수·기울기 추가. 리플레이 v4(MOVE, 새 규칙 필드).
- 헤드리스 러너: `match/headless.dart` `MatchResult playToEnd(match, left, right)` — outcome·winner·턴 수·양쪽 침수량·내구도 %·최종 해시.

## 6. 테스트 (이름은 한국어 문장)
- `move_test`: 연료 소모(1칸 = 8), 한계선 막힘은 연료 안 씀, 연료 부족 시 갈 수 있는 데까지, 간격 8/16/24칸, 턴 시작 +30 상한, 폭풍 후퇴 한계·보급.
- `sea_test`: 흘수 계산, 구멍 정의(holed 포함·원래 빈 칸 제외), 완전/반 잠김 +3/+1.5%p, 폭풍 ×1.5, 누적(막아도 안 줄어듦), 자기 턴 끝에만, 내려앉기로 잠기는 칸 증가, 침수 100% 격침.
- `tilt_wave_test`: 회전 변환 왕복 오차, 기울어진 배에 닿는 칸이 달라짐, 기울기가 발사각을 바꿈, 같은 t 면 같은 결과·다른 t 면 파도 위상으로 착탄이 달라짐.
- `judgement_test`: **시간 판정 시나리오 10종**(침수 적은 쪽 승, 1%p 이내 → 내구도, 완전 동률 무승부, 폭풍 침수 가속, 선·후공 뒤바뀜 등).
- `outcome_test`: 헤드리스 매치가 격침(내구도)·격침(침수)·전멸·시간 판정·무승부로 끝나고 결과 해시 고정.
- `golden_test` + `test/golden/*.json` 10개(리플레이 + 기대 최종 해시) + 생성 스크립트 `test/golden/generate.dart`(의도한 규칙 변경 때만 다시 만든다).
- 기존 `determinism_test` 골든 해시 갱신(규칙 변경), `aim.dart` 2D 변환 대응.

## 7. 문서
- 설계서 §7.2: “`t` 는 판정에 쓰지 않는다” → “`t` 는 턴 시간 초과와 파도 위상 판정에 쓰고, 상대 화면 재생에도 쓴다”(사용자 승인).
- ADR-015: M3 임시 수치(흘수 계수 3, 내려앉기, 기울기 1°/구멍·±8°, 파도 진폭·주기), 회전 충돌, 침수 시점·구멍 정의.
- 계획서 M3 체크, PROGRESS, 현재 단계 → M4, 버전 0.3.0 (완료 때 `/step-verify M3`).

## Verification
- `bash tool/verify.sh` (format·analyze·architecture/결정론·doc sync·test) 통과.
- M3 완료 조건: `outcome_test` 5가지 결말 + 결과 해시 고정, `judgement_test` 10종, `determinism_test` 100회 반복·연료·위치 포함 해시 일치, `golden_test` 10개.
- 결정론 규칙: `double`/`/`/`dart:math` 없이 `sinMicro`·`roundDiv`만 (check_architecture 가 검사).
