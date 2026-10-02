# 조준 점선 시인성 개선 계획 (A12 화면 시안 대조 · 조준 상태)

## Context
폭탄을 당길 때 보이는 궤적 점선이 부자연스럽고 잘 안 보인다는 사용자 피드백이다. 원인은 코드에 있다.

- **간격이 고르지 않다.** `shot_view.dart` `_renderAim` 이 시뮬 틱 2개마다 점을 찍는다(`i += 2`). 탄은 올라갈수록 느려지므로 처음엔 점이 벌어지고 갈수록 뭉친다.
- **밝은 하늘에 묻힌다.**
  - 일반 등급 점선 색이 크림색 `#fff2dc`(anims.json `rarityFx.aim`)인데 테두리가 없다.
  - 투명도가 25%까지 떨어지고(`AimPainter.dotAlpha`) 점도 2~3.5px 로 작다.
- **발사 지점에서 겹친다.** 첫 점들이 힘 링(반지름 20) 안에서 시작해 고무줄·호·링과 포개진다.
- **수치를 읽을 수 없다.** 디자인 시안 `art/pb_v0.24_main/reference/screens_v2/stage32_aim.png` 에는 두 가지가 있다.
  - 테두리 있는 흰 점이 고르게 찍히고 점점 작아진다.
  - 각도 숫자(40°)와 힘 표시(힘 74%)가 붙는다.

사용자 결정은 세 가지다.
1. A12 를 맡은 세션(art-asset-v023-integration)이 'stage32 조준 상태' 대조 항목으로 구현한다(이 계획을 넘긴다).
2. 각도·힘 숫자를 둘 다 붙인다.
3. 점선이 발사 방향으로 흐르게 한다. 저사양 모드에서는 멈춘다.

판정과 무관한 렌더 전용 작업이다. 리플레이 해시는 바뀌지 않는다(절대 규칙 3).

## 바꿀 것

### 1. 점을 거리 기준으로 고르게 찍는다 (`app/lib/game/view/aim_painter.dart`)
- 새 순수 함수 `static List<Offset> resample(List<Offset> path, double step, {double skip = 0, double phase = 0})` 를 만든다.
  - 입력은 틱마다의 월드 좌표 폴리라인이다. 출력은 호 길이 `skip + phase + k·step` 위치의 점이다.
  - `skip` 은 힘 링 바깥에서 시작하게 하는 값이다(`ringRadius + 3`).
  - `phase` 는 흐름 애니메이션 값이다(0 ≤ phase < step).
- `shot_view.dart` `_renderAim` 은 `head(30)` 경로의 **모든 틱**을 `Coords.point` 로 바꿔 넘긴다. `i += 2` 표본 추출은 없앤다.
- 간격 `dotStep` 은 7 월드 px(줌인 상태에서 약 14dp)로 한다.

### 2. 점 모양 (`AimPainter.trajectory`)
- 각 점을 두 겹으로 그린다.
  - 바깥: 외곽선 색 `#14161c`(설계서 §10.1 외곽선), 반지름 r+1.2
  - 안: 등급색 `rarity.aim`(§10.5 표 그대로)
- 반지름은 앞 3.2px 에서 끝 1.8px 로 줄인다. 투명도는 1.0 에서 0.45 로 줄인다(§10.4 ‘멀어질수록 흐려진다’ 유지). `dotAlpha` 는 거리 비율 기준 `1 - .55·t` 로 바꾼다.
- 흐름 때문에 첫 점이 새로 생길 때 깜빡이지 않게, 맨 앞 점은 `phase` 에 비례해 페이드인한다.

### 3. 흐름 애니메이션
- `ShotView` 에 렌더 시계 `_aimFlow`(초)를 두고 `update(dt)` 에서 늘린다. `phase = (_aimFlow * flowSpeed) % dotStep`, `flowSpeed` 는 10 px/초다.
- `fewer`(저사양) 이면 phase 를 0 으로 고정한다. 플래그는 `battle_game.dart` 의 `applyLowEnd()` 에서 `ShotView.fewer = lowEnd.value` 로 넘긴다(`rig.fewer` 와 같은 방식).

### 4. 고무줄·호·링 정리 (`AimPainter.sling`)
- 각도 호: 반지름 15 → 17, 굵기 1.4 → 2, 흰색에 외곽선 한 겹을 더한다.
- 힘 링: 바탕 원 투명도를 0.22 → 0.35 로 올리고 외곽선 한 겹을 더한다. 시안처럼 당긴 끝(고무줄 끝)에 작은 링을 하나 더 그리는 것은 하지 않는다(지금 구조 유지).

### 5. 각도·힘 숫자 라벨 (새 파일 `app/lib/game/view/aim_labels.dart`)
- `shot_view.dart` 가 283줄이라 300줄 제한(절대 규칙 9) 때문에 라벨은 따로 뺀다.
- 각도: 호 끝 바깥(방향 벡터 × 26px)에 `40°` 를 그린다.
- 힘: 발사 지점 아래 28px 에 둥근 알약 모양으로 `힘 74%` / `Power 74%` 를 그린다. 시안 stage32_aim 기준이다.
- 글꼴은 `AppFonts.display` 에 외곽선 그림자를 넣는다(`fx_layer.dart` `damageNumber` 의 `TextPaint` 패턴).
- 글자는 l10n 으로 받는다. `BattleGame` 의 `damageText`·`tagText` 처럼 `aimAngleText(int deg)`·`aimPowerText(int pct)` 콜백을 화면에서 주입한다(`battle_game.dart` 45~48행, 화면 쪽 생성 지점).
- ARB 두 개(`app/lib/l10n/app_ko.arb`·`app_en.arb`)에 같은 커밋으로 넣는다(절대 규칙 10).
  - `aimAngle`: "{deg}°"
  - `aimPower`: "힘 {pct}%" / "Power {pct}%"
- 상대 턴에는 지금처럼 `_renderAim` 전체를 그리지 않는다(§2.2 ‘상대 턴 궤적 숨김’).

### 6. 설계서 (사용자 승인 필요)
- §10.4 ‘조준 표시’ 에 다음 문장을 더하자고 제안한다: “각도 숫자와 힘(%)을 함께 보여주고, 점선은 고른 간격의 테두리 있는 점이 발사 방향으로 흐른다(저사양 정지).”
- 승인되면 같은 커밋에서 계획서 A12 해당 항목과 `기준 문서 동기화:` 해시를 갱신한다(`/doc-sync`). 승인 전에는 라벨을 넣지 않는다.

## 재사용할 것
- `ShotPath.head(30)`(`app/lib/battle/shot_path.dart`): 30% 규칙은 그대로 둔다.
- `AimPainter.direction`·`pulled`: 라벨 위치 계산에 쓴다.
- `RarityFx.aim` 색(`app/lib/game/anim/rarity_fx.dart`).
- `TextPaint` + `AppFonts.display` 패턴(`fx_layer.dart`, `effect_badges.dart`).
- 저사양 전달 방식(`battle_game.dart` `applyLowEnd`).

## 테스트 (한국어 이름)
- `app/test/aim_painter_test.dart`(새 파일):
  - 직선·꺾인 폴리라인을 `resample` 하면 점 간격이 모두 `step` 이다.
  - `skip` 안쪽에는 점이 없다.
  - `phase` 를 올리면 모든 점이 같은 거리만큼 앞으로 간다.
  - `dotAlpha` 는 앞이 1, 끝이 0.45 이고 줄어들기만 한다.
- 조준 골든 1장을 추가한다(`hud_golden_test.dart` 에 조준 중 상태). 두 언어 × 고·저사양으로 라벨이 잘리지 않는지 본다. 저사양은 phase 0 이라 골든이 고정된다.

## 검증
1. `(cd app && flutter test test/aim_painter_test.dart test/hud_golden_test.dart)`
2. `bash tool/verify.sh` 통과(포맷·analyze·l10n·300줄·골든). 리플레이 해시 테스트는 바뀌지 않아야 한다.
3. 사람 확인: 실기기에서 열대 만 하늘·바다 위에서 점이 잘 보이는지, 흐름 속도가 거슬리지 않는지 본다(PROGRESS 남은 이슈에 적는다).

## 진행 방식
- 이 계획을 SendMessage 로 art-asset-v023-integration 세션에 넘긴다. A12 ‘화면 시안 대조’ 의 stage32 조준 상태 항목으로 그 세션이 구현한다.
- 설계서 §10.4 문장 추가(6번)는 그 세션이 구현 전에 사용자 승인을 받는다.
