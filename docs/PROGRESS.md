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
- GitHub 원격 저장소 생성과 공개 여부. 원격이 생기면 CI 가 돈다.
- mozzi 에 Firebase·AdMob·IAP 가 아직 없다(mozzi P9). M7 일정에 영향이 있다 (`docs/MOZZI_REUSE.md` §2).
