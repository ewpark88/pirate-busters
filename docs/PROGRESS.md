# 진행 기록

## Phase 0 — 준비 (2026-09-29)

**완료**
- git 저장소, `.gitignore`/`.gitattributes`
- pub workspace 모노레포: `packages/pb_sim`, `pb_ai`, `pb_data`, `tools/sim_runner`, `app`(Android) (ADR-001)
- 품질 게이트 `tool/verify.sh`/`verify.ps1`: format, analyze(very_good_analysis + strict), 의존 방향·결정론 검사, test
- `tool/check_architecture.dart`: 의존 방향(ADR-002), 결정론 금지 규칙(ADR-003), lib 300줄 제한. 위반 7종을 넣은 파일로 검출을 확인했다
- CI(`.github/workflows/ci.yml`): verify + debug APK 빌드
- Claude 설정: `CLAUDE.md`, 편집 후 자동 포맷 훅, `/step-start`, `/step-verify`
- mozzi 재사용 목록 `docs/MOZZI_REUSE.md` (ADR-004)
- 미정 사항 결정: 로컬 DB는 Hive CE (ADR-005), 대상 플랫폼은 Android 먼저 (ADR-006)

**남은 이슈 (사용자 확인 필요)**
- 상표 사전 검색(KIPRIS, USPTO): ‘Pirate Busters’와 대체 이름 후보. 결과를 개발 계획서 §3 에 기록한다.
- ~~GitHub 원격 저장소 생성~~ → `https://github.com/ewpark88/pirate-busters` 에 push 했다 (2026-09-29). 공개 여부는 사용자 확인 필요.
- mozzi 에 Firebase·AdMob·IAP 가 아직 없다(mozzi P9). M7 일정에 영향이 있다 (`docs/MOZZI_REUSE.md` §2).

## M1 — 시뮬레이션 코어 `pb_sim` (2026-09-29, 브랜치 `feat/M1-sim-core`, 버전 0.1.0)

**완료**
- `Fx` ×1000 고정소수점(0에서 먼 쪽 반올림, 범위·곱셈 오버플로 검사), `roundDiv`, `mulChecked`
- 정수 삼각함수: 0~90° 0.25° 간격 sin 테이블(×1,000,000, `tool/gen_trig_table.dart` 생성) + 선형 보간. `isqrt`, `atan2Mdeg`(이분 탐색)
- `XorShift32`(mozzi `seeded_rng` 복사 후 정수화), 재질 5종(§3.2), 슬루프 선형(§3.1), 설계도 검증·JSON, 전투 격자 `ShipGrid`
- `Command`(FIRE/TAP/SURRENDER, §7.2 JSON), `Controller`·`ScriptedController`·`runMatch`, `Match.step` 30Hz 틱 루프
- FNV-1a 32 상태 해시 `hashMatchState`, 리플레이 JSON(version 1) 저장·읽기·재생
- 테스트 46개. 완료 조건 근거(`determinism_test.dart`): 1,000틱 반복 해시 20회 동일, 골든 해시 고정, 리플레이 JSON 왕복 후 해시 동일

**결정**
- ADR-007: 리플레이·커맨드·설계도 직렬화는 `pb_sim`, 콘텐츠 JSON 은 `pb_data`

**임시로 정한 값 (설계서에 없음 → 이후 단계에서 교체·확인)**
- 재장전 기본 90틱(3초). 해적별 재장전은 M5 데이터로 바뀐다
- FIRE 힘 범위 0~10000, 각도 0~359999 밀리도. 범위 밖 커맨드는 무시한다
- 같은 틱 적용 순서 FIRE → TAP → SURRENDER, 진영 0 먼저
- TAP 은 M1 에서 효과가 없다(투사체가 생기는 M2 에서 연결)
- 시간 종료 시 승자 없음(-1). 판정 점수는 M3 이후

**남은 이슈**
- 골든 해시는 규칙이 바뀌는 M2 에서 갱신될 예정이다(의도한 변경이면 커밋 메시지에 이유)
