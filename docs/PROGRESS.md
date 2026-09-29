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

## M2 — 턴 루프·탄도·타격·붕괴 `pb_sim` (2026-09-29, 브랜치 `feat/M2-ballistics`, 버전 0.2.0)

**완료**
- 턴 묶음 커맨드 `TurnBundle{turn, side, cmds[t, …], hash}`: FIRE·TAP·END_TURN·SURRENDER (§7.2). MOVE 는 M3
- 턴 루프: 선공 시드 결정(`mixSeed`), 교대, 턴당 서로 다른 해적 2발·2발 뒤 자동 종료, 25초 턴 타이머(비행 틱만큼 정지, 넘긴 커맨드는 버림), 양쪽 합쳐 30턴, 턴마다 바람 −3~+3, 턴 끝 처리(쿨다운 → 바람), 턴 끝 해시
- 탄도·타격: 포물선+바람, 정수 DDA(터널링 방지), 손상 단계, 원형 폭발(가장자리 50%), 용골 BFS 붕괴
- 해적: 등급 코스트(3·4·5·6·8)와 출전 명단 검사(코스트 한도·선실 수·최대 7명·중복 금지), 턴 쿨다운, 선실 파괴 시 20% 피해 후 낙하 → 다음 내 턴 시작 복귀, 바다에 빠진 동안 맞으면 KO
- 승리: 격침(선체 내구도 20% 미만)·전멸·항복. 30턴 뒤는 `turnLimit`(판정은 M3)
- 리플레이 v3(규칙·코스트 한도·턴 묶음), 재생 시 턴 해시 불일치 검출(`TurnHashMismatch`)
- 테스트 81개. 완료 조건 근거: `같은 턴 묶음 목록이면 최종 해시가 100번 모두 같다`, 시나리오 `뱃머리 벽을 쏴서 부순다`·`기둥을 부수면 위의 판이 통째로 무너진다`·`선실을 노려 쏘면 … 전멸로 이긴다`·`선체 내구도를 20% 미만으로 만들면 격침으로 이긴다`

**결정**
- ADR-010 판정 구조(선실 안 해적·블록이 방패, 뱃머리 간격)와 임시 수치, ADR-011 턴제 재편, ADR-012/013 출전 코스트(플레이어 레벨 한도)·30턴, ADR-014 캐주얼 종족 아트
- 골든 해시 1686798692 (규칙 변경으로 갱신)

**임시로 정한 값 (설계서에 없음 → 밸런스 단계에서 조정)**
- 중력 36칸/초², 최대 탄속 40칸/초, 바람 세기 1 = 1/1000칸/틱², 폭발 가장자리 50%, 낙하 피해 20%
- 바다에 빠진 해적 위치는 뱃머리 1칸 앞 해수면, 폭발·물보라 1칸(또는 반경) 안이면 KO
- 탄은 쏜 진영 배에 닿지 않고, 바다에 떨어진 탄은 블록을 다치게 하지 않는다. 해수면 = 용골 바닥(흘수선은 M3)
- END_TURN 없이 끝난 묶음은 시간 초과로 처리한다

**남은 이슈**
- 설계서 확인 필요: AI 생각 연출 시간(§5.2 vs §5.5), 실시간 표현 잔재(§2.2·§5.1 “재장전”, §5.4 보스 기믹) — 계획서 11장
- `main` 에 M2 가 아직 머지되지 않았다(사용자 요청 시 머지)

## 하네스 확장 (2026-09-29, ADR-015)

**완료**
- 검사 추가: ARB 짝(`check_l10n`), 비밀값(`check_secrets`), 커밋 메시지(`check_commit_msg`), 릴리스 일치(`release check`). `tool/test` 테스트 20개. `verify` 7단계
- git 훅(commit-msg / pre-commit / pre-push), `tool/install_hooks.sh`
- 출시 규칙 `docs/RELEASE.md`, `CHANGELOG.md`(0.1.0·0.2.0 소급), `release.yml`(태그 → 서명 AAB → Release 초안), release 서명 설정
- Claude 권한·SessionStart/Stop 훅, `/doc-sync`·`/adr`·`/release`, `rules-reviewer` 에이전트, PR·이슈 템플릿, dependabot, `.editorconfig`
- 구성표 `docs/HARNESS.md`

**남은 이슈 (사용자 확인 필요)**
- `bash tool/install_hooks.sh` 실행(에이전트 권한에서 훅 설정 변경을 막아 두었다)
- GitHub `main` 브랜치 보호(PR 필수, CI 통과 필수), 서명 Secrets 4개 등록
- `applicationId` 확정, 업로드 키 생성
