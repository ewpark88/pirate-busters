# S4 타격감 CC0 에셋 후보 조사 (2026-10-13)

계획서 0장 S4(설계서 §10.3 사운드, §10.4 전투 연출)를 시작하기 전에 조사한 내용이다. **코드·에셋은 바꾸지 않았다.**
0원 원칙(절대 규칙 8)에 따라 **CC0(공개 기증)만** 골랐다. CC-BY·CC-BY-SA·GPL·유료 팩·"로열티 프리" 개별 라이선스(Sonniss, Adobe Stock, Construct 등)는 넣지 않았다.

> 라이선스는 2026-10-13 에 각 페이지에서 확인했다(※ 표시는 검색 요약으로만 확인했다). **받기 직전에 페이지를 다시 확인하고**, 받은 파일의 출처를 `docs/ASSETS.md` 「음원」 표 형식으로 적는다.
> 해상도·프레임 수가 "미표기"인 것은 받아서 열어 봐야 안다.

## 0. 먼저 볼 점 (화풍)

- 설계서 §10 화풍은 **플랫 2D 벡터 + 남색 외곽선(#14161c)** 이다. CC0 폭발 시트의 대부분은 **픽셀 아트**이거나 **3D 렌더 사실풍**이라 그대로 넣으면 캐릭터·배와 어울리지 않는다.
- 그래서 그림 쪽은 두 갈래로 나눠 고른다.
  1. **사실풍 렌더 시트**(Sinestesia): 프레임 수가 많아 움직임이 부드럽다. 색 보정·윤곽 없음 상태로 "불·연기" 층에만 쓴다.
  2. **입자 낱장**(Kenney Smoke Particles): 플랫 화풍에 가장 가깝다. 지금 코드(Flame 파티클 + 낱장 PNG)를 거의 그대로 쓸 수 있다.
- 지금 `fx/impact/fireball_0~4`·`puff_0~6`·`shockwave` 등은 디자인 패키지(v0.2x)에서 온 **화풍이 맞는 그림**이다. 바꿀 때 "프레임 수만 부족한 것"인지 "그림 자체가 약한 것"인지 전후 캡처로 먼저 가른다(S4 완료 조건이 전후 영상 승인이다).

## 1. 그림 후보

### 1.1 폭발 연속 프레임 (불덩이)

| 후보 | 출처 | 라이선스 | 해상도·프레임 | 장점 | 단점 |
| --- | --- | --- | --- | --- | --- |
| **2D Explosion Animations — Frame by frame** (Sinestesia) | https://opengameart.org/content/2d-explosion-animations-frame-by-frame | CC0 (작가 표기는 부탁이지 조건 아님) | 프레임 512×512, 아틀라스 4096×4096(반 크기 2048 판 포함), 폭발 4종. 프레임 수 미표기(아틀라스 8×8 이면 64) | 고해상도, 4종이라 한 방 크기 3단계(가벼움·중간·묵직)+유폭에 나눠 쓸 수 있다. 연기로 식는 꼬리까지 있다 | 사실풍 렌더라 화풍이 다르다. 아틀라스 하나 18MB 급 → 256px 로 줄이고 프레임 솎아야 앱 용량이 맞다 |
| **2D Explosion Animations 2** (Sinestesia) | https://opengameart.org/content/2d-explosion-animations-2-frame-by-frame | CC0 | 512×512 프레임, 4096 아틀라스(2048 판 포함), 폭발 4종, zip 18.3MB | 위와 다른 모양 4종 → 변형을 돌려 반복감 줄이기 | 위와 같음 |
| **2D Explosion Animations 3** (Sinestesia) | https://opengameart.org/content/2d-explosion-animations-3-frame-by-frame | CC0 | 512×512, 2종(보통 불색·파란 불) | **옆으로 터지는 폭발 = 포구 불꽃**으로도 쓸 수 있다고 작가가 적었다 → §10.4 발사 포구 불꽃 | 파란 불은 쓸 데가 적다 |
| explosion 7 (BenHickling) | https://opengameart.org/content/explosion-7 | CC0 | 100×100, **50프레임**, 투명 PNG 시트 | 프레임이 아주 많아 부드럽다, 용량 작음 | 픽셀 아트 → 확대하면 계단. 화풍 불일치 |
| Explosion 48/96 + 벡터판 (Fry) | https://opengameart.org/node/147142 | CC0 | 48·96px 시트 + **SVG 원본** | SVG 라 원하는 크기로 굽고 외곽선·팀 색을 덧그릴 수 있다 → 우리 화풍으로 고치기 가장 쉽다 | 프레임 수 미표기(적음), 원래 픽셀 스타일 디자인 |
| ReactorCore Explosion mini-pack (itch.io) | https://reactorcore.itch.io/explosion-spriteanim-sheet-minipack | ※ 댓글로 CC0 라고 답했을 뿐 페이지 표기 불확실 | 10종 × 16프레임(4×4) | 종류 많음 | **라이선스 확인 전에는 쓰지 않는다** |

**추천:** Sinestesia 1·2 에서 묵직·유폭용 2~3종을 골라 256px·16~24프레임으로 줄여 쓰고, 가벼움·중간은 지금 `fireball_*` 5장 + Kenney 입자로 둔다. 화풍 차이가 크면 Fry 의 SVG 를 우리 외곽선 규칙으로 다시 그리는 안(디자인 쪽 요청)을 대안으로 둔다.

### 1.2 연기 기둥 · 충격파 · 불티

| 후보 | 출처 | 라이선스 | 내용 | 장단점 |
| --- | --- | --- | --- | --- |
| **Smoke Particles** (Kenney) | https://kenney.nl/assets/smoke-particles (OGA 사본: https://opengameart.org/content/smoke-particle-assets) | CC0 | 70~77장, 5스타일: 검은 연기·폭발·방귀(동글 연기)·섬광·흰 연기 | **플랫 화풍에 가장 가깝다.** 낱장이라 지금 `ExplosionFx.puffs`·`rising` 에 바로 꽂힌다. 연기 기둥은 여러 장을 떠오르게 겹쳐 만든다 |
| **Particle Pack** (Kenney) | https://kenney.nl/assets/particle-pack (OGA: https://opengameart.org/content/particle-pack-80-sprites) | CC0 | 80장, 512×512, 불·연기·불꽃·마법·전기(Unity 예제 포함) | 충격파 고리·불티·섬광 재료. 512px 라 줄여서 쓴다 |
| Sinestesia 시트의 연기 꼬리 | 1.1 참조 | CC0 | 폭발 끝부분이 연기 | 따로 "연기 기둥" 시트는 없다. 끝 프레임만 잘라 쓸 수 있다 |

충격파는 CC0 전용 시트를 찾지 못했다. Particle Pack 의 고리 그림을 `ScaleEffect` 로 키우거나 지금처럼 `fx/impact/shockwave.png` 를 코드로 키우는 쪽이 낫다.

### 1.3 파편 (나무 판자 · 철판)

- **CC0 파편 스프라이트 세트는 찾지 못했다.** 검색에 나온 "wooden debris" 는 CC-BY 3.0 효과음이고, itch.io 판자 타일셋은 CC-BY 4.0 이라 뺐다.
- 쓸 만한 재료: Wood plank(CC0, 픽셀) https://opengameart.org/content/wood-plank — 화풍이 달라 결국 다시 그려야 한다.
- **추천:** 파편은 에셋 대신 **지금 타일 그림(`ship/tiles_v2`)을 칸 위치로 정한 다각형으로 잘라 튀기는 코드 방식**이 설계서 §10.4("나무는 결을 따라 갈라진 판자, 철판은 휜 조각 2~4개, 칸 위치로 모양 고정")와 화풍 둘 다 맞다. 이미 `debris_0~5`·`debris_plank` 가 있으므로 부족하면 디자인 패키지에 "재질별 조각 4장 × 나무·철" 을 요청한다.

### 1.4 물보라

- **CC0 물보라 연속 프레임은 사실상 없다.** 유명한 Julien Jorge "water splash" 는 CC-BY-SA 3.0, 그 밖에는 유료(Adobe Stock, Construct)였다.
- CC0 이 맞는 것: Splash (jcpmcdonald) https://opengameart.org/node/16595 ※ — 3프레임 57×12, SVG 포함, 아주 작다.
- **추천:** 지금 `fx/collapse/{splash_big,water_spike,foam_ring,water_drop,mist,bubble}` + `fx/splash.png` 를 유지하고, 물방울 입자 수·떨어지는 궤적·물기둥 늘어남(세로 스케일 애니)을 코드로 보강한다. Kenney Smoke Particles 의 흰 연기를 푸른 기로 칠해 물안개로 쓰는 것도 가능하다.

## 2. 효과음 후보 (실녹음 위주)

지금 쓰는 음원은 `docs/ASSETS.md` 「음원 (A19, CC0)」 표에 있다(Kenney 팩 + rubberduck 25 bang·40 water). 아래는 **바꾸거나 더할 후보**다. Freesound 는 계정 로그인 뒤 내려받고, 페이지마다 CC0 표기를 다시 본다. 길이(초)는 검색 목록 표기다.

### 2.1 포성 (`cannon`) — 지금: 폭죽 녹음(rubberduck `cannon_0x`)이라 가볍다

| 후보 | URL | 길이 | 메모 |
| --- | --- | --- | --- |
| Cannon shots.wav (Andykub) | https://freesound.org/people/Andykub/sounds/415293/ | 6초 | 여러 발 → 잘라서 변형 3개 |
| Cannon boom (Quassorr) | https://freesound.org/people/Quassorr/sounds/758072/ | 6초 | 단발 굉음 |
| Cannon fire.WAV (t-man95) | https://freesound.org/people/t-man95/sounds/553240/ | 4초 | 짧아 손질 적음 |
| Cannon Fires, Take 3, Quarter Speed, Debris (CHallSmith) | https://freesound.org/people/CHallSmith/sounds/870746/ | 미표기 | 파편 소리 포함 → 묵직한 한 방 잔향 재료 |
| Cannon Fire / Large Cannon Fire (raphavpires) | https://freesound.org/people/raphavpires/sounds/867028/ · …/867030/ | 미표기 | 크기 두 단계 |
| S20-12 Distant cannon fire (craigsmith) | https://freesound.org/people/craigsmith/sounds/675613/ | 6초 | **상대 턴 원거리 포성**으로 |
| Little Cannon (vulkanbruder) | https://freesound.org/people/vulkanbruder/sounds/850499/ | 3초 | 작은 포·직사 |

### 2.2 폭발 (`hit`·`hitBig`·`boom`·`rumble`) — 지금: Kenney Sci-fi `explosionCrunch` 섞임(SF 느낌)

| 후보 | URL | 길이 | 메모 |
| --- | --- | --- | --- |
| large explosion 1 (V-ktor) | https://freesound.org/people/V-ktor/sounds/482993/ | 52초(원본) | 유폭 `boom` |
| Sharp Explosion 4 of 5 (Rudmer_Rotteveel) | https://freesound.org/people/Rudmer_Rotteveel/sounds/336011/ | 26초 | 5개 연작 → 변형 돌리기 좋다, `hit` |
| Firecracker Explosion (unfa) | https://freesound.org/people/unfa/sounds/609588/ | 49초 | 가벼운 착탄 |
| Huge Explosion Part 1 – Shockwave (bevibeldesign) | https://freesound.org/people/bevibeldesign/sounds/366091/ | 84초 | 선장실 파괴 판 끝·`rumble` 잔향 |
| Explosion 1.wav (Deganoth) | https://freesound.org/people/Deganoth/sounds/165911/ | 52초 | `hitBig` |
| 25 CC0 bang / firework SFX (rubberduck, 이미 사용) | https://opengameart.org/content/25-cc0-bang-firework-sfx | — | 쓰지 않은 `bang_0x` 를 가벼움 변형으로 |

Sci-fi·8-Bit 표기 음원은 화풍(해적)과 안 맞아 뺐다.

### 2.3 나무 부서짐 (`wood`·`creak`)

| 후보 | URL | 길이 | 메모 |
| --- | --- | --- | --- |
| Wood Break Planks Multiple 9 (Sheyvan) | https://freesound.org/people/Sheyvan/sounds/569694/ | 미표기 | **판자 여러 장** — 칸 파괴에 가장 맞다. 같은 작가 연작 확인 |
| Crate Break 4 / Barrel Break 4 (kevinkace) | https://freesound.org/people/kevinkace/sounds/66780/ · …/66772/ | 각 60초 묶음 | 상자·통 부수기 여러 번 → 변형 많이 뽑힌다. 화약고 통 유폭에도 |
| crate_break4 (K-Forces) | https://freesound.org/people/K-Forces/sounds/856631/ | 미표기 | 짧은 단발 |
| SFX_wood_cracking (EricsSoundschmiede) | https://freesound.org/people/EricsSoundschmiede/sounds/669457/ | 7초 | **붕괴 우지끈 `creak`** |
| Foley Wood Breaking Ply 192k (Sonicquinn) | https://freesound.org/people/Sonicquinn/sounds/518791/ | 5초 | 고음질 |
| Wood Break (BOAAY) | https://freesound.org/people/BOAAY/sounds/520720/ | 55초 묶음 | 변형 재료 |

### 2.4 철판 (`clang`·`dent`) — `dent` 는 지금 합성음뿐

| 후보 | URL | 라이선스 | 메모 |
| --- | --- | --- | --- |
| Metal Impact Sounds (BMacZero) | https://opengameart.org/content/metal-impact-sounds | CC0 ※ | clink·bong·thud 단발, 바로 쓰기 쉽다 |
| 100 CC0 metal and wood SFX (rubberduck) | https://opengameart.org/content/100-cc0-metal-and-wood-sfx ※ | CC0 | 금속 치기·쾅·떨어짐 + 나무. **`dent` 후보**(slam). 다른 사이트 사본 논란 댓글 있음 — 출처 확인 |
| 27 metal audio samples (blacklodgegames) | https://opengameart.org/content/27-metal-audio-samples-sfx | CC0 ※ | **철판 휨·치기 녹음** → `dent` 에 가장 맞다 |
| 33 metal clang sounds from cast iron pans (bart) | OGA 검색 "33 metal clang" ※ | CC0 | 무쇠 팬 울림 — `clang` 변형 |

### 2.5 물 첨벙 (`splash`·`plunge`·`sink`·`gurgle`)

지금 rubberduck 40 water 팩으로 충분히 실녹음이다. 물기둥(큰 착탄)만 보강 후보:

| 후보 | URL | 길이 |
| --- | --- | --- |
| Water Splash in Lake 05 (vero.marengere) | https://freesound.org/people/vero.marengere/sounds/524524/ | 40초 묶음 |
| water_splash_10shots (vibe_crc) | https://freesound.org/people/vibe_crc/sounds/50623/ | 10발 묶음 |
| Water splashing (Whiplaff) | https://freesound.org/people/Whiplaff/sounds/273223/ | 20초 |
| squeaky jetty and water splash (Garuda1982) | https://freesound.org/people/Garuda1982/sounds/529456/ | 3초 |

### 2.6 바람·바다 환경음 (지금 `SfxBank.seaLoop` 합성 4초 루프)

| 후보 | URL | 메모 |
| --- | --- | --- |
| Sea shore with medium wind (borralbi) | https://freesound.org/people/borralbi/sounds/317397/ | 15초, 루프로 다듬기 쉬움 |
| sea waves and wind (tullio) | https://freesound.org/people/tullio/sounds/710738/ | 길이 미표기 |
| strong wind on coastal path (bruno.auzet) | https://freesound.org/people/bruno.auzet/sounds/706471/ | 25초, 바람 단계 높을 때 |
| Wind whoosh loop (OGA) | https://opengameart.org/content/wind-whoosh-loop | CC0 ※, 짧은 바람 루프 |
| Sea and river wave sounds (OGA) | https://opengameart.org/content/sea-and-river-wave-sounds | CC0 ※, 강 물결 녹음(5분판) |

"wind loop"(OGA)는 CC-BY 3.0 이라 뺐다.

## 3. 음악 후보 (CC0 만)

| 곡 | 작가 | URL | 형식·길이 | 분위기 | 쓸 곳 |
| --- | --- | --- | --- | --- | --- |
| **Pirate's Orchestra** | Dizzy Crow | https://opengameart.org/content/pirates-orchestra-208 | MP3 2:08 + MIDI | 아코디언·오케스트라, 장난스러운 모험 | **항구** 1순위 |
| **Pirate Indenture** | Eldritch Grim | https://opengameart.org/node/160257 | WAV 전체판 + **루프판** | 빠르고 웅장한 북 중심 | **전투** 1순위 |
| Pirate Ship Theme Loop | beardalaxy | https://opengameart.org/content/pirate-ship-theme-loop | OGG 317KB, 루프 | 항해 테마, 스네어 | 전투·항구 보조, 용량 작음 |
| A sailor's chant | Thimras | https://opengameart.org/content/a-sailors-chant | OGG 3.7MB, 루프 가능 ※ | 하프시코드·플루트·목소리, 섄티풍 | 항구·캠페인 지도 |
| Pirates Incoming | Eldritch Grim | 작가 페이지 https://opengameart.org/user/115034 ※ | 하드 드럼 루프 | 긴장 | 폭풍 타임·마지막 턴 |
| (지금) Pirate Game Tune / OPL2 Drunken Sailor | Tozan / TheOuterLinux | ASSETS.md 참조 | — | — | 비교 기준 |

빼낸 것: "Pirate Music"(migfus20, CC-BY 4.0), "Pirate Theme"(loliver1814, GPL 3.0), "Haul Away Joe"·"Pique La Baleine"(CC-BY-SA), "Woffelsbacher Pirates"(여러 라이선스 혼재 — 받은 파일의 라이선스를 확인 못 하면 쓰지 않는다).

## 4. 지금 코드에서 바꿔 끼울 자리

| 영역 | 파일 | 지금 하는 일 |
| --- | --- | --- |
| 폭발 그림 | `app/lib/game/view/explosion_fx.dart` | `Fireball`: `fireball_0~4` 5장을 나이(0.06/0.14/0.26/0.4초)로 바꾸며 0.62초 재생. 저사양은 한 장 건너뜀. `debris`·`puffs`·`embers`·`rising`(연기 기둥)·`flicker`(잔불) 입자 |
| 착탄 연출 묶음 | `app/lib/game/view/fx_layer.dart` | 계열별 명중 모양(`flash`·`spark`·`hole_burnt`·`cracks`·`shockwave`·`burst`·`water_spike`·`foam_ring`), 흔들림(`ScreenTrauma`), 진동, `few()` 입자 상한(60) |
| 파괴·붕괴·물 | `breakage_fx.dart`, `collapse_fx.dart`, `water_fx.dart`, `shot_fx.dart`(포구 섬광·물기둥) | 조각 낙하 → 물보라, 붕괴 큰 물보라 |
| 그림 미리 읽기 | `app/lib/game/sprites.dart` (`BattleSprites`), `ExplosionFx.files` | 경로 문자열 목록 |
| 효과음 목록 | `app/lib/audio/sound_library.dart` (`AudioAssets.variants`·`synthOnly`) | `assets/audio/sfx_<소리>_<번호>.ogg` 를 변형 수만큼 읽고, 못 읽으면 `SfxBank` 합성음 |
| 재생 | `app/lib/audio/sound_service.dart` (`SoloudSoundService`), `VariantPicker`(±6%) | `loadClips`·`loadMusicClips`·`loadAmbience`(환경음 루프) |
| 착탄 소리 겹침 | `app/lib/game/impact_sound.dart` | `impactLayers`: 크기별 `hit`/`hitBig` + `wood`/`clang` + `dent` + `rumble`, `SfxMixer` 프레임 크기 합 2.4 |
| 음악 | `music_director.dart`, `assets/audio/music_{port,battle}.ogg` | 크로스페이드·덕킹 |
| 출처 기록 | `docs/ASSETS.md` 「음원」 표, `app/assets/audio/LICENSE_*.txt` | |

## 5. 작업 목록 초안 (S4)

**그림**

1. 전후 비교 기준 캡처: 가벼움·중간·묵직·유폭·물 착탄·붕괴 6장면을 지금 상태로 `docs/quality/` 에 먼저 찍는다(S4 완료 조건).
2. Sinestesia 1·2 를 저장소 밖 임시 폴더에서 풀어 후보 3~4종을 고른다. 256px(@2x 기준) 로 줄이고 16~24프레임으로 솎아 가로 시트 한 장씩 만든다(`fx/explosion/<이름>.png` + 프레임 수). 앱 용량 증가를 표로 남긴다.
3. `Fireball` 을 "N장 시트 + 프레임 시간" 으로 일반화한다(지금은 5장·단계 시각 고정). 저사양은 프레임 반, `low` 규칙 유지. 테스트: `frameAt`·`scaleAt` 경계값.
4. 한 방 크기별로 시트를 고르는 표(가벼움=기존 5장, 중간=시트 A, 묵직·유폭=시트 B/C)를 `fx_layer.dart` 에 둔다(렌더 전용, 판정 무관).
5. Kenney Smoke Particles 로 `puff_*`·`smoke` 를 바꾸거나 더하고, `rising` 을 여러 장 겹친 연기 기둥으로 바꾼다. 충격파는 Particle Pack 고리 또는 기존 `shockwave.png` 확대.
6. 파편: 타일 그림을 칸 위치로 정한 다각형 2~4조각으로 잘라 튀기는 코드(나무 결 방향, 철판은 휜 모양 + 회전 느리게). 물에 닿으면 `water_drop` 물보라. 리플레이 같음 테스트(칸 위치 → 같은 조각).
7. 포구 불꽃: Sinestesia 3(옆 폭발)을 작게 써 `shot_fx.dart` 의 `flash`+`spark` 를 바꿀지 비교.
8. `pubspec.yaml` 에 새 폴더, `BattleSprites` 미리 읽기 목록, `docs/ASSETS.md` 에 그림 출처 절 추가.

**소리**

9. 후보를 받아 Audacity 등으로 0.05초 앞 무음 자르기·정규화(-1dBFS)·모노 44.1kHz OGG(q4) 로 변환. 변형 3개씩 `sfx_<소리>_<번호>.ogg` 로 덮어쓴다(파일 이름 규칙 그대로 → 코드 수정 최소).
10. `dent`(철판 찌그러짐)·`crackle`(불)·`wake`(물살)·`gurgle`(침수) 음원을 고르면 `AudioAssets.variants` 에 넣고 `synthOnly` 에서 뺀다. 환경음은 `loadAmbience` 에 OGG 를 읽는 길을 더한다(지금은 합성 WAV 만).
11. 포성은 거리 두 단계(가까운 우리 포, 먼 상대 포)를 둘지 결정 — 둔다면 `Sfx` 새 값이 필요해 ARB 와 무관하지만 설계서 §10.3 목록에 없으므로 **사용자 확인 필요**.
12. 음악: 항구 Pirate's Orchestra, 전투 Pirate Indenture(루프판)을 1안으로 듣기 비교. MP3/WAV → OGG 변환, 루프 지점 확인. 용량 목표: 곡당 2MB 이하.
13. `docs/ASSETS.md` 「음원」 표에 원작자·URL·원본 파일 이름을 적는다(CC0 이라 표기 의무는 없지만 절대 규칙 8 기록). Freesound 는 작가별 페이지 URL 을 그대로 남긴다.

**확인**

14. 실기기에서 전후 영상(`docs/quality/`)을 찍어 사용자 승인을 받는다(S4 완료 조건). 저사양 모드·소리 끄기·진동 끄기도 한 번씩.

## 6. 정리

- **바로 쓸 만한 것:** Kenney Smoke Particles·Particle Pack(그림), Sinestesia 폭발 시트(묵직·유폭), Freesound CC0 포성·판자 부서짐, 음악 Pirate's Orchestra·Pirate Indenture.
- **CC0 로 못 찾은 것:** 화풍이 맞는 폭발 연속 프레임, 파편 스프라이트, 물보라 연속 프레임 → 코드 생성 또는 디자인 패키지 요청이 낫다.
- **사용자에게 물을 것:** 사실풍 폭발 시트를 플랫 화풍 위에 써도 되는지, 포성 거리 두 단계를 더할지.
