# 전투 화면 "허접함" 원인과 개선 계획 (초안)


## Context
사용자가 실기기(SM S921N)에서 보니 디자인·포탄/폭발 연출이 여전히 허접하다고 했다. 조사 결과 원인은 세 갈래다.

1. **A12 아트 적용이 아직 진행 중이다.** 계획서 §12 A12 의 6개 항목이 미완료다: 해역 배경 `bg/tropic` 6레이어(지금 바다는 `sea_view.dart` 에서 단색 Path·원으로 그림), 이동 한계 표식, 모듈 그림 8종, 메타 아이콘(HUD 가 Material 기본 버튼·`Icons.*` — `ui/meta/hud/*`, `ui/kit/*` 는 들어 있지만 안 씀), 화면 시안 대조(조준 점선 개선), 프롤로그. 이 작업은 같은 작업 트리에서 다른 세션이 진행 중이다(커밋 안 된 22개 파일).
2. **들어 있지만 안 쓰는 이펙트 에셋이 많다.** `fx/impact/fireball_0_hot~4_smoke`(폭발 시퀀스 5장), `flame`, `ember`, `scorch`, `smoke`, `fx/fire.png`, `fx/smoke.png`, `fx/collapse/{dust,mist,bubble,water_drop,broken_edge}`. 지금 폭발은 `explosion.png` 한 장을 키우며 흐리게 하는 수준(`fx_layer.dart:52-60, 227-244`)이고, 꼬리·파손·등급 연출은 Canvas 도형(`trail_painter.dart`, `damage_painter.dart`, `impact_accent.dart`)이다.
3. **설계서·계획서에 아예 없는 연출이 있다.** 격침(배가 가라앉는 연출 없음, `ship_view.dart:139-152`), 화재 블록 불꽃, 침수 차오름, 화약고 유폭, 배경음악(§10.3 은 있지만 담당 단계 없음), 효과음은 코드 합성 4종뿐.

## 제안 접근
- **A12 는 현 세션 범위대로 끝낸다** (다른 세션 담당. 이 세션은 건드리지 않는다).
- **새 단계 A13 "전투 연출 손질"** 을 계획서 12장 끝에 붙인다 (절대 규칙 11). 먼저 설계서 §10.3·§10.4 수정안을 사용자에게 제안·승인받는다(설계서는 직접 안 고침).
  - 폭발: `fireball_0~4` 프레임 시퀀스 + `scorch` 그을음 자국 + `ember` 불티 파티클 (`fx_layer.dart`)
  - 연기: 착탄 후 `smoke`/`puff` 가 떠오르며 흩어짐
  - 화재 블록: `flame`/`fire.png` 루프 (`ship_view.dart`, 시뮬 상태 읽기만)
  - 격침: 배 기울며 가라앉음 + `bubble`/`mist`/`splash_big`
  - 물보라: `water_drop`, `dust`(나무 칸 파괴) 보강
  - 성능: 꼬리·등급 Paint 재사용 (PROGRESS A11 남은 이슈)
  - 음악: CC0 섄티 1곡 + 승패·버튼 효과음 (0원 원칙)
- 규칙: 렌더만 바꾸고 `pb_sim` 무변경 → 리플레이 해시 불변. 저사양 모드에서 파티클 절반.

## 진행 순서 (사용자 선택: A13 신설)
1. 설계서 §10.3(음악·효과음)·§10.4(폭발 시퀀스·연기·화재·격침·침수) 추가 문구를 사용자에게 제안하고 승인을 받는다. 수치가 필요하면 BALANCE.md 가 아니라 렌더 상수로 둔다(밸런스와 무관).
2. 승인 후 `/doc-sync`: 계획서 12장 끝에 A13(작업·완료 조건) 추가, 해시·날짜 갱신, `/adr` 로 ADR-064 "전투 연출 손질 A13 신설".
3. 착수 시점: A12 가 머지된 뒤 `/step-start A13` → `feat/A13-battle-fx` 브랜치. 작업 트리를 다른 세션과 공유하므로 그 전에는 브랜치를 바꾸지 않는다. 문서 작업(1~2)은 다른 세션이 건드리지 않는 내 경로만 add 한다.
4. 구현 순서: 폭발 시퀀스·그을음 → 연기·불티 → 화재 루프 → 격침 → 물보라 보강 → Paint 재사용 → 음악·효과음. 항목마다 실기기 확인.

## 핵심 파일
`app/lib/game/view/fx_layer.dart`, `ship_view.dart`, `sea_view.dart`, `trail_painter.dart`, `app/lib/game/sprites.dart`, `app/lib/game/battle_cues.dart`, `app/lib/audio/`, 설계서 §10.3·§10.4, 계획서 12장.

## 검증
- `bash tool/verify.sh` 통과, 리플레이 해시 테스트 불변, 골든 재생성(ko/en)
- `flutter run -d R3CX90JQLEB` 로 실기기에서 착탄·화재·격침 장면 확인, 프레임 저하 없는지 확인
