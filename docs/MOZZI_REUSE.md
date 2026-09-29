# mozzi 재사용 목록

> 개발 계획서 §3 Phase 0. mozzi(`D:\Projects\mozzi`, 2026-09-29 기준 P6 진행 중)에서 가져올 코드와 가져오는 방식.
> 방식은 **복사 후 수정**이다 (ADR-004). 가져온 파일은 첫 줄 주석에 `mozzi <원본 경로>`를 적는다.

## 1. 가져올 것

| mozzi 원본 | 가져갈 곳 | 시점 | 수정할 점 |
| --- | --- | --- | --- |
| `lib/core/random/seeded_rng.dart` (xorshift32) | `pb_sim` | M1 | `nextDouble`/`nextBool(double)` 을 빼고 정수 범위 함수만 남긴다. 범위 난수는 곱셈 대신 `(x * max) >> 32` 정수 계산으로 바꾼다 |
| `lib/domain/sim/fixed_stepper.dart` | `app/lib/render` | M4 | 렌더 쪽 누적기라 `double` 을 써도 된다. 30Hz(`simTickHz`)로 맞춘다 |
| `lib/domain/sim/launch_controller.dart` | `app/lib/input` | M4 | 당기기 → 각도·힘. 결과를 `FIRE` 커맨드(정수 밀리도·힘)로 바꾼다. 정확도 게이지 판정은 빼고 조준만 남긴다 |
| `lib/game/input/play_input.dart`, `flight_gesture.dart` | `app/lib/input` | M4 | 발사 전 당기기 / 비행 중 탭 라우팅. 홀드·스와이프는 빼고 탭(`TAP` 커맨드)만 남긴다 |
| `lib/game/components/gauge_component.dart` | `app/lib/render` | M4 | 재장전 게이지·힘 바 그리기 참고 |
| `lib/game/camera/camera_rig.dart` | `app/lib/render` | M4 | 포탄 추적 → 적 배 → 복귀, 핀치 줌 |
| `lib/game/viewport/virtual_viewport.dart`, `lib/ui/play/hud_scale.dart` | `app/lib/render` | M4 | 가로 고정 반응형 가상 화면 그대로 |
| `lib/game/effects/particle_effects.dart`, `run_fx.dart` | `app/lib/render` | M4 | 파편·물보라·화면 흔들림·햅틱 |
| `lib/game/render/palette.dart` | `app/lib/render` | M4 | 구조만. 색은 해적·바다 팔레트로 새로 정한다 |
| `모찌 런처 2.5D.html` (2.5D 렌더 규칙, 합성음) | `app/lib/render`, 효과음 | M4 | 그림자·림라이트·하이라이트·말랑 변형 규칙. 합성음은 샘플 JS 를 Dart 로 옮긴다 |
| `lib/core/json/json_reader.dart` | `pb_data` | M5 | 정수 필드 읽기를 기본으로 한다. 실수 값이 오면 오류로 처리한다 |
| `lib/domain/balance/stage_spec.dart`, `lib/domain/run/star_rules.dart` | `pb_data`, `app/lib/meta` | M7 | 스테이지 JSON 구조(`stage_table`)와 별 3개 미션 판정 |
| 연패 보정 로직(보스 레이스) | `pb_ai` | M6 | 3연패마다 각도 오차 +1°, 최대 +3° |
| `tool/verify.sh`, `check_architecture.dart`, `hooks/format_on_edit.dart`, CI | `tool/`, `.github/` | Phase 0 | **완료.** 결정론 검사를 추가했다 |

## 2. mozzi 에 아직 없는 것 (직접 만들어야 함)

| 항목 | 상태 | 영향 |
| --- | --- | --- |
| Firebase(Analytics·Remote Config·Crashlytics), AdMob, IAP 래퍼 | mozzi P9 로 예정돼 있고 아직 없다 | M7 전에 mozzi P9 가 끝나면 가져오고, 아니면 여기서 먼저 만들어 mozzi 로 되돌려준다 |
| Hive CE 저장소 | mozzi `pubspec` 에 의존성만 있다 | M7 에서 같은 패키지(`hive_ce`)로 구현한다 |
| 합성 효과음 Dart 구현 | HTML 샘플에만 있다 | M4 에서 새로 만든다 |
