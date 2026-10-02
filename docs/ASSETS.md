# 아트 에셋 (ADR-026)

아트는 외부 패키지(`pirate_busters_assets_v<버전>`)로 받는다. SVG 원본에서 PNG 를 뽑아 둔 패키지이고, 부위 애니메이션 데이터(`anims.json`)와 스타일 수치(`tokens.json`)가 들어 있다.

## 구조

```
art/pb_v0.21_main/              패키지 원본 전체 (git 제외, .gitignore). v0.21: 40명 전원 + 무기·탄종 아이콘
                                characters/*.svg, reference/, tools/, README.md …
app/assets/images/              앱에 들어가는 PNG. @2x 한 벌만, 이름에서 "@2x" 를 뗀다
  characters/<id>/              <id>_<team>_battle.png (전투 외곽선을 구워 넣은 한 장)
                                <id>_<team>_card.png (등급 카드 그림, tool/assets/export_cards.py)
    parts_<team>/               부위 PNG + parts.json (부위 애니메이션)
    parts_battle_<team>/        전투 외곽선 부위 PNG + battle.json (outlinePad)
  ship/tiles_v2/ rooms/ rig/    블록 32x32 · 1칸 등불 선실 32x32 · 돛대·돛·깃발
  fx/ fx/impact/ fx/collapse/   발사체·폭발 · 명중 임팩트 · 붕괴
  ui/portraits/ kit/ icons/     선원 초상 · 판·버튼 · 아이콘
  ammo/icons/                   탄종 아이콘 13종 (카드 칩, 설계서 §13.4)
  weapons/ weapons/icons/       해적별 투사체 37종 · 분열 조각·소형 폭탄 · 강습·지원 아이콘
app/assets/data/anims.json      40명 공격 동작, 공용 피격, 발사체·명중 효과, 등급별 연출(rarityFx)
app/assets/data/tokens.json     색, 팀 색, 눈빛 색, HUD 색, 크기, 대기 동작 수치
app/assets/data/weapons.json    해적별 투사체 그림과 움직임(spin·face), 렌더 전용
```

- 캐릭터 id: `octo` 옥토, `bones` 본즈, `sword` 핀, `otter` 수리, `puffer` 퍼피, `gull` 윙, `shark` 샤키, `turtle` 톡. 팀은 `blue`(우리)·`red`(상대).
- **@2x 만 넣는 이유:** Flame 의 이미지 로더는 Flutter 의 해상도별 자동 선택(2.0x/3.0x 폴더)을 쓰지 않는다. 세 벌을 넣어도 앱 용량만 커진다. 조준 줌인 때 약 4배 확대되므로 1x 로는 부족하다.
- **캐릭터 폴더의 초상 PNG 는 넣지 않는다.** 초상은 `ui/portraits/` 를 쓴다.
- **전투 외곽선 부위:** `parts_battle_<team>/` 에는 parts.json 이 없다. `parts_<team>/parts.json` 을 쓰고 각 부위의 `offset` 에서 여백을 빼고 `pivot` 에 더한다. 여백은 같은 폴더 `battle.json` 의 `outlinePad`(v0.24: 22px)다.
- Flutter 는 하위 폴더를 자동으로 넣지 않으므로 `app/pubspec.yaml` 에 폴더마다 한 줄씩 적는다.

## 새 버전으로 바꾸기

v0.16 부터 패키지에 캐릭터 PNG 가 없고 SVG 만 있다. 패키지 복사본에서 PNG 를 먼저 뽑는다.
패키지의 `tools/export_png.py` 는 cairosvg(= 네이티브 cairo)가 필요한데 Windows 에는 cairo 가 없어서,
resvg 로 대신 그리는 대역 모듈 `tool/assets/cairosvg.py` 를 앞에 둔다 (`pip install resvg-py pillow`).

```bash
cp -r "D:/Projects/이미지참고용/pb_v0.19_main" <작업 폴더>/        # 원본은 건드리지 않는다
cd <작업 폴더>/pb_v0.19_main && PYTHONPATH=<저장소>/tool/assets python tools/export_png.py
dart run tool/import_assets.dart "<작업 폴더>/pb_v0.19_main"
```

```bash
dart run tool/import_assets.dart "D:/Projects/이미지참고용/pirate_busters_assets_v0.16"
dart run tool/import_assets.dart --check     # pubspec 목록 검사만
```

- `art/pb_assets_v0.16/` 이 새로 생기고, `app/assets/images`·`app/assets/data` 는 지우고 다시 채운다.
- 새 캐릭터·폴더가 생기면 `--check` 가 pubspec 에 빠진 폴더를 알려 준다. `app/pubspec.yaml` 에 추가한다.
- 패키지 README 의 ‘바뀐 점’ 표(캔버스·기준점·전투 배율)를 확인하고 렌더 코드의 수치를 맞춘다.

## v0.21 (2026-09-30, M5)

- 캐릭터는 v0.19 와 같고 **무기(v0.20)·탄종 아이콘(v0.21)** 이 새로 들어왔다. 패키지의 `png/` 에 이미 뽑힌 @2x 를 그대로 복사했다(`png/ammo/icons`, `png/weapons`, `png/weapons/icons` → `app/assets/images/…`, `weapons/weapons.json` → `app/assets/data/`). 패키지 안 스크립트는 실행하지 않았다.
- 패키지 `ammo/ammo.json` 의 사다리 값은 `app/assets/game/ammo.json`(BALANCE.md A4.8)과 13종 모두 같다.
- 표정 부위는 아직 없다(M4 이월 그대로).

## v0.22 (2026-10-01, ADR-058)

- 원본: `art/pb_v0.22_main/` = `D:\Projects\이미지참고용\pb_v0.22_main` 위에 `이미지참고용\png`(랍스터 전체 PNG·40명 표정 부위)를 덮어쓴 것.
- 새로 온 것: 표정 6종(`png/characters/<id>/expr_<team>@Nx/`, 머리·눈 + expr.json), `anims.json` `states`·`expressions`·`rarityFx.tiers.mythic`, `ship/tiles_v2`, `style/modes.json`, 신화 카드, 사거리·코스트·세트 아이콘, 화면 시안(`reference/screens`). 랍 키는 `lob` → `lobster`.
- **앱에 넣었다 (A11, ADR-059).** 패키지에 39명의 몸 PNG 가 없어서, 지우고 다시 채우는 방식 대신 덮어쓰기만 하는 `--merge` 로 넣는다.

```bash
dart run tool/import_assets.dart --merge art/pb_v0.22_main   # 지우지 않고 덮어쓴다
dart run tool/import_assets.dart --check                     # pubspec 폴더 목록 + 몸 부위 없는 캐릭터 검사
```

- `--merge` 는 패키지에 있는 @2x 파일만 덮어쓰고, 새 키로 대체된 옛 파일(`obsoleteImages`: `characters/lob`, 옛 이름 탄종 아이콘 등)을 지운다. 랍 초상은 v0.24 부터 패키지에서 `lobster_*` 이름으로 온다(이름 바꾸기 표 `renamedImages` 는 지웠다).
- 데이터 파일은 `anims.json`·`tokens.json`·`weapons.json` 세 가지만 넣는다. 패키지의 `ui/cards/cards.json`·`ui/icons/sets.json` 은 설명·세트 이름 글자가 들어 있어 앱에 넣지 않는다(절대 규칙 10). 카드 좌표는 `ui/cards/rarity_card.dart`, 세트 구성은 `ui/cards/card_icons.dart` 에 옮겨 적었다(패키지 값이 바뀌면 같이 고친다).
- 탄종 아이콘 파일 이름은 탄종 키와 같다(`ammo/icons/<AmmoType.jsonName>.png`).
- 표정 부위(`characters/<id>/expr_<team>/`, 머리·눈 × 6표정 + expr.json)가 약 1천 장 늘어 앱 이미지가 14MB → 25MB 가 됐다.
- 전장 타일은 `ship/tiles_v2` 를 쓴다(`game/sprites.dart`). 예전 `ship/tiles`·`ship/rooms` 는 조선소 화면 등에서 아직 쓸 수 있어 남겨 두었다.
- `tokens.json` 의 `character.battleScale 0.16`·`roomSlot "3x2칸"` 은 앱이 쓰지 않았다. 앱은 선실 한 칸에 맞춘 0.09 를 썼다(ADR-057). v0.24 에서 3/32 로 맞췄다(아래).

## v0.23 (2026-10-02, ADR-061)

- 원본: `art/pb_v0.23_main/` = `art/pb_v0.22_main/` 위에 `이미지참고용\pb_v0.23_update`(새 SVG·PNG·JSON, `README_v0.23.md`)와 `이미지참고용\reference\screens_v2`(비교 페이지 29~37단계 화면 74장)를 덮어쓴 것. v0.23 은 추가만 하는 패키지라 v0.22 파일을 하나도 바꾸지 않는다.
- 새로 온 것:
  - 해역 배경(`bg/<해역>/` 6해역 × 레이어 7장, `bg/regions.json`)과 이동 한계 표식(`bg/props/limit_*`)
  - 메타 아이콘 85개(`ui/meta/<묶음>/`, `icons.json`)
  - 기능 모듈 9종(`ship/modules/`)
  - 특수·화재 타일(`ship/tiles_v2/` 얼음·금박·유령 판자·방패·불붙은 블록·그을린 블록)
  - 보스(`boss/`), 컷신 구성(`story/cutscenes.json`)과 말풍선(`ui/story/`)
- **앱 적용 (A12, ADR-063):** 이미 끝난 화면에 쓰는 것만 넣었다. 뒷 단계 화면 그림은 그 단계에서 넣는다.

```bash
python tool/assets/export_bubbles.py art/pb_v0.24_main   # 말풍선의 자리 표시 글자(<text>)를 빼고 @2x 로 다시 굽는다
dart run tool/import_assets.dart --merge art/pb_v0.24_main
```

  - 들어간 것: `bg/tropic`·`bg/gold`·`bg/storm`(프롤로그용), `bg/props`, `ship/modules`, `ui/meta/{hud,meta,currency,ai,faction}`, `ui/story`. 데이터는 `bg/regions.json`·`style/modes.json` 이고, 이름 글자 필드(`ko`·`en`·`faction`·`note`·`limits`)를 지우고 넣는다(절대 규칙 10).
  - `ui/meta` 는 쓰는 묶음을 폴더째 넣어서, 아직 쓰지 않는 아이콘(약관·진주 등)도 함께 들어 있다.
  - 넣지 않는 것: `tool/import_assets.dart` 의 `deferredImages` 목록이다. 해역 2·4·5 배경, `boss/`, `ui/meta` 의 상자·티어·심장·날씨·궤적, 특수 블록 타일(불·그을음·유령·얼음·금박·방패)이 여기 든다. 그 단계에서 목록에서 빼고 pubspec 에 더한다.
  - 전장은 `sea` 겹을 쓰지 않는다. 바다는 앱의 사인파 바다·셰이더가 그린다. 컷신 배경은 7장을 모두 쓴다.
  - 일반 모드가 아닐 때: 하늘·바다는 `regions.json` 의 모드 색 그라데이션으로, far·mid 는 행렬로, 구름은 모드 구름색을 곱해 그린다. 비·번개는 R3 에서 넣는다.
- 해역 배경 레이어 순서(README): sky(고정) → clouds(.08) → far(.18) → haze(.18) → mid(.4) → glow(.4) → 배·해적 → sea(1.0).
  - far·mid 에는 `style/modes.json` 의 색 행렬을 씌운다.
  - glow 는 행렬 없이 모드가 어두울수록 불투명도를 올린다.
  - 지옥 모드의 비·번개는 코드로 그린다.
- **흘수선 아래 칸:** 참나무·소나무만 `tiles_v2/bot_*`(젖은 타일)다(README). 앱은 칸 가운데가 잠긴 깊이 아래면 젖은 것으로 본다(`BattleSprites.isWet`, A11).
- **데이터로 쓰지 않는 파일:**
  - `ship/hulls/hulls.json`: 격자 크기와 선실 수는 설계서 §3.1 과 같다. 하지만 블록을 꽉 채운 그림이라 건조 포인트(BALANCE.md A3.1)의 약 2배이고, 추천 설계도도 프리깃 기준이다. 앱 추천 설계도(`app/assets/game/blueprints.json`, 슬루프)를 바꾸지 않는다.
  - `boss/bosses.json`: 선원 목록에 같은 해적이 중복되고 중간·해역 보스가 같다. 크라켄 촉수 6개·체력 칸 4/3/2/1 은 설계서·BALANCE.md 에 근거가 없다(계획서 11장, R3).
  - `story/cutscenes.json`: `lineKey` 4개(`story_prologue_1_tok` 등)가 앱 ARB 에 없다. 앱 키(`story_prologue_n`)에 맞춘다.
- **디자인 쪽 요청 중 v0.23 에서도 남은 것(ADR-057, v0.24 에서 모두 해결):**
  - `style/tokens.json` `battleScale 0.16`·`roomSlot` 3×2칸(README 문장만 0.095·1칸이다)
  - 새 배율에 맞춘 전투 외곽선(`parts_battle_*`) 다시 굽기
  - 1칸 등불 선실 타일
  - 랍 초상 이름 `ui/portraits/lob_*` → `lobster_*`

## v0.25 (2026-10-02, ADR-065)

- 원본: `art/pb_v0.25_patch/` 를 `art/pb_v0.24_main/` 위에 덮어썼다(`README_v0.25.md`). 그 전에 README 대로 `boss/kraken_tentacle_hp1~4`(SVG·PNG)와 `reference/screens_v2/stage31_pre_ironclad`·`stage31_pre_swift` 를 지웠다.
- v0.23 에서 데이터로 쓰지 않던 세 파일을 디자인 쪽이 고쳐 보냈다.
  - `ship/hulls/hulls.json`: 선형마다 앱 `blueprints.json` 형식의 기준 설계도(`starter.blueprint`)가 건조 포인트·모듈 한도 안이다(슬루프 58/60, 브리건틴 74/80, 프리깃 93/100, 갤리온 113/120). 앱 추천 설계도는 그대로이고, R2 선형별 추천 설계도의 출발점으로 쓴다.
  - `boss/bosses.json`: 배 안 해적 중복이 없고 중간·해역 보스 선원이 다르다(그림용 제안, 실제 덱은 R3). 기믹 문구는 BALANCE.md A5.4 값이다.
  - `story/cutscenes.json`: 앱 ARB 키만 쓴다. 프롤로그는 `story_prologue_1~5` 자막만(말풍선 없음), 해역 1 인트로·1-5 뒤·1-12 전후는 이미 있는 해역 1 대사 키다.
- 크라켄 촉수는 체력 칸 그림 대신 촉수 1개 손상 단계 4장(`boss/kraken_tentacle_dmg0~3`)이다. 촉수 수·체력은 여전히 정해지지 않았다(계획서 11장, R3).
- 비교 페이지 31~37단계 화면 47장을 실제 크기 배로 다시 그렸다(보스 화면만 1.4배). A12 화면 시안 대조는 이 그림을 쓴다.
- 앱 이미지는 바뀌지 않는다. `boss/` 는 `deferredImages` 로 R3 까지 가져오지 않는다.

## v0.26 (2026-10-02, ADR-070)

- 원본: `art/pb_v0.26_patch/` 를 `art/pb_v0.24_main/` 위에 덮어썼다(`README_v0.26.md`, 지울 파일 없음).
- 피해 표현 v3(비교 페이지 38단계): `fx/damage_v3/damage_v3.json`(그리는 순서·색·규칙), 규칙별 예시 SVG·PNG, 참고 구현 `tools/py/damage38.py`, 비교 캡처 `reference/stage38_damage_v3.png`·`reference/screens_v2/stage38_h0~h3.png`.
- 앱은 예시 PNG 를 넣지 않고 규칙을 코드로 그린다(`app/lib/game/view/damage_*.dart`, A15). 색은 `damage_style.dart` 에 옮겨 두었다.
- `fx/impact/scorch.png` 는 A15 부터 쓰지 않는다(그을음은 코드로 그림). 폴더째 가져오므로 다음 가져오기 정리 때 뺀다.

## 소리 (설계서 §10.3, A13, ADR-068)

소리 파일은 없다. 효과음과 배경음악을 모두 `app/lib/audio/pcm_synth.dart` 로 코드 합성한다. 만든 소리는 프로젝트 저작물이라 CC0 으로 둔다.

| 곡 | 선율 출처 | 쓰는 곳 |
| --- | --- | --- |
| *Sailor's Hornpipe* (College Hornpipe) | 영국 민요, 18세기. 저작권 없음 | 항구 (`Music.port`) |
| *Drunken Sailor* | 선원 민요, 19세기 기록. 저작권 없음 | 전투 (`Music.battle`), 폭풍 타임 1.2배 |

선율은 앱이 짧은 루프로 편곡한 것이다(`audio/shanty_music.dart`). 효과음 레시피는 `audio/sfx_bank.dart` 에 있다.

## 글꼴 (설계서 §14.4, A11)

`app/assets/fonts/` 에 OFL 글꼴 세 가지를 라이선스 파일과 함께 둔다. 출처는 Google Fonts 저장소(`github.com/google/fonts/ofl/`).

| 역할 | 글꼴 | 파일 | 라이선스 |
| --- | --- | --- | --- |
| 제목·숫자 | Black Han Sans | `BlackHanSans-Regular.ttf` | `OFL-BlackHanSans.txt` |
| 본문 | IBM Plex Sans KR | `IBMPlexSansKR-Regular.ttf`, `-Bold.ttf` | `OFL-IBMPlexSansKR.txt` |
| 둥근 강조(버튼) | Jua | `Jua-Regular.ttf` | `OFL.txt` |

역할은 `app/lib/app/app_theme.dart` 가 정한다. 골든 테스트는 `app/test/test_fonts.dart` 로 세 글꼴을 읽는다.

## Flame 재생기 (M4)

`art/pb_assets_v0.15/tools/flame/pb_anim.dart` 는 컴파일 검증 전 참고 구현이다. M4 에서 flame 의존성을 추가할 때 `app/lib/game/anim/` 으로 옮긴다.
- JSON 경로를 `assets/anims/anims.json` → `assets/data/anims.json` 으로 바꾼다.
- 부위 폴더 이름에서 `@2x` 가 빠졌으므로 `parts_$team@${n}x` → `parts_$team` 으로 바꾼다.
- very_good_analysis 린트와 300줄 제한(CLAUDE.md 절대 규칙 9)을 맞추고 테스트를 붙인다.
- 렌더 전용이다. 대기 동작 위상의 `Random` 은 앱에서만 쓰고, 판정에는 영향을 주지 않는다.

## v0.24 (2026-10-02, ADR-062)

- 원본: `art/pb_v0.24_main/` = `art/pb_v0.23_main/` 에서 `ui/portraits/lob_*`·`png/ui/portraits/lob_*` 를 지우고 `이미지참고용/pb_v0.24_patch.zip` 을 덮어쓴 것. 풀어 둔 폴더(`pb_v0.24_patch/`)에는 `style/`·`tools/`·`ui/` 가 빠져 있어 zip 을 쓴다.
- 바뀐 것:
  - `style/tokens.json`: `character.battleScale` 0.16 → 3/32(0.09375), `roomSlotPx`(1칸 32×32, 발 16, 29), `battleHeightAtDesign` 29. 3×2칸 `room_*.svg` 와 `design` 18×12 좌표는 레거시.
  - 전투 PNG(`<id>_<team>_battle`)와 `parts_battle_<team>`(+ `battle.json` `outlinePad` 22)를 새 배율로 다시 구웠다. 외곽선은 1x 약 1px(설계서 §10.1).
  - 1칸 등불 선실 타일 `ship/rooms/room1_lantern_{0,1}[_left]`, 꺼진 등불 `room1_dark_{0,1}`(아귀 등불선 기믹, 해역 5 — 그 단계에서 쓴다).
  - 랍 초상 `ui/portraits/lobster_*`.
- 앱 적용: `game/coords.dart`(`pirateScale` 3/32, `pirateHeight` 29, `cabinFloor` 3), `character_rig.dart`(`outlinePad` 읽기), `sprites.dart`(선실 타일 → `room1_lantern_*` 네 가지, 칸 위치로 고정 선택). 예전 `ship/rooms/room_*.png`(3×2칸)는 `obsoleteImages` 로 지웠다.
- **가져오기 주의:** `--merge art/pb_v0.24_main` 은 v0.23 의 아직 안 쓰는 폴더(`bg/`·`boss/`·`ship/modules`·`ui/meta`·`ui/story`·`tiles_v2` 새 타일)도 함께 넣는다. 이번에는 v0.24 몫만 남기고 지웠다. 그 폴더들은 A12·뒷 단계에서 넣는다.
- **카드 그림:** 등급 카드는 전투 PNG 를 키워 쓰고 있었다. 전투 PNG 가 작아지면서(@2x 45×61) 흐려졌다. 그래서 패키지 `ui/cards/cards.json` 의 `character`(원본 `<id>_<team>.svg`, 0.74배)대로 카드용 그림을 따로 굽는다:

```bash
python tool/assets/export_cards.py art/pb_v0.24_main   # png/characters/<id>/<id>_<team>_card@2x.png (355×480), 80장 약 2.3MB
dart run tool/import_assets.dart --merge art/pb_v0.24_main
```
