# A61 기뢰·설치탄 폭발 연출 빠짐 고침

## 배경
사용자 제보: 기뢰가 터져도 임팩트가 없어 적 배가 "혼자 가라앉는" 것처럼 보인다.

원인 (코드 확인):
- 설치탄(퍼피 등)이 턴 시작에 터질 때(`effect_runner.dart` `_fire`)와 떠 있는 기뢰(젤리)가
  배 이동으로 터질 때(`ability_effects.dart` `_blowFloatMine`)는 `resolveImpact` 를 직접 부른다.
  이 경로는 `SimEventKind.impact` 를 내지 않는다(impact 는 `flight.dart` 비행 착탄만 낸다).
- 연출 쪽 `battle_cues.dart` 는 `effectFired` 를 "뒤따르는 착탄 이벤트가 그린다"며 무시한다.
  그런데 착탄 이벤트가 안 오므로 폭발·카메라·흔들림·폭발음이 하나도 없다.
- 남는 건 블록 파편(`blockDestroyed`)과 침수 물방울(`flood`)뿐이고, `hitAt`·`spec` 이 null 이라
  칸 번쩍임·피해 숫자도 안 뜬다. → "혼자 가라앉음".

설계서 §10.4(명중은 폭발·흔들림·숫자로 전달), §4.8(기뢰는 터져 폭발 피해 + 침수)와 맞추는 수정이라
설계서 변경은 필요 없다. 판정은 그대로, 앱 연출만 고친다(절대 규칙 3).

## 변경
1. `app/lib/game/cues_unique.dart` 에 `Vector2? mineBlast(SimEvent e)` 추가
   - `e.value` 가 `EffectKind.mineBlast` 또는 `EffectKind.floatMine` 일 때만 처리, 아니면 null.
   - 위치: `e.cell >= 0` 이면 `cellWorld(e.side, e.cell)`, 아니면 `Coords.point(e.x, 0)`.
   - 수중 폭발: `fx.waterHit` + `fx.splash`(물기둥) + `fx.explosion(at, radius: 1, heavy: true)`.
   - `director.impact(at, punch: .., ship: shipSpan(e.side))` 로 카메라가 맞은 배를 본다.
   - `ships[e.side].rock(...)`, `fx.jolt`/히트스톱, `Sfx.boom` (+ 물 소리).
   - 이름표 `HitTag.mineBlast` ("기뢰 폭발!" / "Mine blast!") 한 번.
   - 위치를 돌려줘 호출부가 `hitAt` 으로 쓰게 한다 → 칸 번쩍임·피해 숫자가 뜬다.
2. `app/lib/game/battle_cues.dart` `effectFired` 분기를 따로 떼어 `hitAt = mineBlast(e) ?? hitAt;`
   (파일 300줄 이하 유지 — 넘으면 `joltOnce`/연출 일부를 확장으로 옮긴다).
3. `app/lib/game/hit_tag.dart` 에 `mineBlast` 추가, `app_ko.arb`·`app_en.arb` 같은 키로 함께 추가,
   `battle_texts_l10n.dart` 매핑.
4. 손대지 않음: 모레이 물어뜯기·크라키 촉수 연출(별도 경로, 필요하면 다음 작업으로 제안).

## 테스트
- `app/test/battle_fx_test.dart` 패턴으로: `effectFired(value: mineBlast)` + `blockHit` 묶음을
  dispatch 하면 폭발 효과가 생기고 카메라 impact 가 불리고 피해 숫자가 뜬다(테스트 이름 한국어).
- 떠 있는 기뢰(`floatMine`, cell −1 포함)도 같은 확인. `flockDrop` 은 그대로(뒤 착탄이 그림).
- 골든 영향 있으면 확인 후 갱신.

## 진행
- 공유 작업 트리: 내 파일만 `git add`. 별도 브랜치 `feat/A61-mine-blast-fx`,
  계획서 12장에 A 단계 한 줄, STATUS·PROGRESS·CHANGELOG `[Unreleased]` 갱신.
- `bash tool/verify.sh` → 커밋 → push → main 병합 → main push (ADR-098).
- 사람 확인: 실기기에서 기뢰 폭발 손맛.
