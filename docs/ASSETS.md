# 아트 에셋 (ADR-026)

아트는 외부 패키지(`pirate_busters_assets_v<버전>`)로 받는다. SVG 원본에서 PNG 를 뽑아 둔 패키지이고, 부위 애니메이션 데이터(`anims.json`)와 스타일 수치(`tokens.json`)가 들어 있다.

## 구조

```
art/pb_assets_v0.15/            패키지 원본 전체 (git 제외, .gitignore)
                                characters/*.svg, reference/, tools/, README.md …
app/assets/images/              앱에 들어가는 PNG. @2x 한 벌만, 이름에서 "@2x" 를 뗀다
  characters/<id>/              <id>_<team>_battle.png (전투 외곽선을 구워 넣은 한 장)
    parts_<team>/               부위 PNG + parts.json (부위 애니메이션)
    parts_battle_<team>/        전투 외곽선 부위 PNG (json 없음)
  ship/tiles/ rooms/ rig/       블록 32x32 · 선실 96x64 · 돛대·돛·깃발
  fx/ fx/impact/ fx/collapse/   발사체·폭발 · 명중 임팩트 · 붕괴
  ui/portraits/ kit/ icons/     선원 초상 · 판·버튼 · 아이콘
app/assets/data/anims.json      8명 공격 동작, 공용 피격, 발사체·명중 효과
app/assets/data/tokens.json     색, 팀 색, 눈빛 색, HUD 색, 크기, 대기 동작 수치
```

- 캐릭터 id: `octo` 옥토, `bones` 본즈, `sword` 핀, `otter` 수리, `puffer` 퍼피, `gull` 윙, `shark` 샤키, `turtle` 톡. 팀은 `blue`(우리)·`red`(상대).
- **@2x 만 넣는 이유:** Flame 의 이미지 로더는 Flutter 의 해상도별 자동 선택(2.0x/3.0x 폴더)을 쓰지 않는다. 세 벌을 넣어도 앱 용량만 커진다. 조준 줌인 때 약 4배 확대되므로 1x 로는 부족하다.
- **캐릭터 폴더의 초상 PNG 는 넣지 않는다.** 초상은 `ui/portraits/` 를 쓴다.
- **전투 외곽선 부위:** `parts_battle_<team>/` 에는 parts.json 이 없다. `parts_<team>/parts.json` 을 쓰고 각 부위의 `offset` 에서 14, `pivot` 에 14 를 더한다(사방 14px 여백).
- Flutter 는 하위 폴더를 자동으로 넣지 않으므로 `app/pubspec.yaml` 에 폴더마다 한 줄씩 적는다.

## 새 버전으로 바꾸기

```bash
dart run tool/import_assets.dart "D:/Projects/이미지참고용/pirate_busters_assets_v0.16"
dart run tool/import_assets.dart --check     # pubspec 목록 검사만
```

- `art/pb_assets_v0.16/` 이 새로 생기고, `app/assets/images`·`app/assets/data` 는 지우고 다시 채운다.
- 새 캐릭터·폴더가 생기면 `--check` 가 pubspec 에 빠진 폴더를 알려 준다. `app/pubspec.yaml` 에 추가한다.
- 패키지 README 의 ‘바뀐 점’ 표(캔버스·기준점·전투 배율)를 확인하고 렌더 코드의 수치를 맞춘다.

## Flame 재생기 (M4)

`art/pb_assets_v0.15/tools/flame/pb_anim.dart` 는 컴파일 검증 전 참고 구현이다. M4 에서 flame 의존성을 추가할 때 `app/lib/game/anim/` 으로 옮긴다.
- JSON 경로를 `assets/anims/anims.json` → `assets/data/anims.json` 으로 바꾼다.
- 부위 폴더 이름에서 `@2x` 가 빠졌으므로 `parts_$team@${n}x` → `parts_$team` 으로 바꾼다.
- very_good_analysis 린트와 300줄 제한(CLAUDE.md 절대 규칙 9)을 맞추고 테스트를 붙인다.
- 렌더 전용이다. 대기 동작 위상의 `Random` 은 앱에서만 쓰고, 판정에는 영향을 주지 않는다.
