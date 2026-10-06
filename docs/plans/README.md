# 작업 계획 기록

에이전트가 계획 모드 등에서 세운 작업 계획을 모아 둔다. 파일 이름은 `YYYY-MM-DD-<내용>.md` 이고, 결정의 근거는 `docs/DECISIONS.md`(ADR), 진행 결과는 `docs/PROGRESS.md` 가 기준이다. 여기 있는 계획은 당시의 생각이라 기준 문서와 다를 수 있다.

규칙(CLAUDE.md 「문서 위치」): 게임 관련 문서·계획은 C 드라이브(`~/.claude/plans`, 임시 폴더 등)에 두지 않고 이 저장소 `docs/` 아래에 둔다.

| 파일 | 내용 |
| --- | --- |
| [2026-09-29-M1-sim-core.md](2026-09-29-M1-sim-core.md) | M1 — 시뮬레이션 코어 (`pb_sim`) 구현 계획 |
| [2026-09-29-M3-move-fuel-wave-flood.md](2026-09-29-M3-move-fuel-wave-flood.md) | M3 — 이동·연료·파도·침수·시간 판정 (`pb_sim`) |
| [2026-09-29-art-assets-v015.md](2026-09-29-art-assets-v015.md) | 아트 에셋 v0.15 배치 (art/ 원본 + app/assets 게임용) |
| [2026-09-29-design-campaign-story-range.md](2026-09-29-design-campaign-story-range.md) | 설계서 보완: 캠페인 서사 + 넓은 전장·줌·해적별 사거리 |
| [2026-09-29-dev-plan-writing.md](2026-09-29-dev-plan-writing.md) | 계획: `Pirate Busters 개발 계획서.md` 작성 |
| [2026-09-29-roster-ability-overlap.md](2026-09-29-roster-ability-overlap.md) | 해적 로스터 능력 중복 점검 (설계서 §4.2) |
| [2026-09-30-art-folder-restore.md](2026-09-30-art-folder-restore.md) | art/ 폴더 복구 |
| [2026-09-30-pirate-set-effects.md](2026-09-30-pirate-set-effects.md) | 해적 세트 효과 추가 — 설계서·계획서 수정 계획 |
| [2026-09-30-plan-follows-design.md](2026-09-30-plan-follows-design.md) | 계획서를 설계서에 맞추기 + “계획서는 설계서를 따른다” 규칙 추가 |
| [2026-09-30-shot-flight-camera-follow.md](2026-09-30-shot-flight-camera-follow.md) | 계획: 탄 비행 시간을 늘리고, 카메라가 착탄까지 탄을 따라가게 기재 |
| [2026-10-01-A11-cabin-pirate-one-cell.md](2026-10-01-A11-cabin-pirate-one-cell.md) | 선실 해적을 한 칸 안에 그리기 (A11 타일 항목에 포함) |
| [2026-10-01-aim-switch-cancel.md](2026-10-01-aim-switch-cancel.md) | 조준 중 해적 바꾸기: 손가락을 되돌리면 취소되고, 화면에 표시한다 |
| [2026-10-01-art-doc-sync.md](2026-10-01-art-doc-sync.md) | 설계서 아트 동기화 (`/art-doc-sync`, 사용자 승인 작업) |
| [2026-10-01-design-recheck-2.md](2026-10-01-design-recheck-2.md) | 설계서 재대조 2차 반영 — 이 세션 몫 (보스 난이도·전투 중 언어·문서 정합) |
| [2026-10-01-test-battle-12-pirates.md](2026-10-01-test-battle-12-pirates.md) | 테스트 대전: 해적 12명을 등급별로 골라 AI 와 바로 붙기 |
| [2026-10-02-A11-asset-v023.md](2026-10-02-A11-asset-v023.md) | 에셋 v0.23 수용 + A11 마무리 |
| [2026-10-02-A12-aim-dotted-line.md](2026-10-02-A12-aim-dotted-line.md) | 조준 점선 시인성 개선 계획 (A12 화면 시안 대조 · 조준 상태) |
| [2026-10-02-A9-proposals.md](2026-10-02-A9-proposals.md) | A9 마무리 — 제안 1·2 를 기준 문서에 반영 (문서만, 브랜치 `feat/A9-proposals`) |
| [2026-10-02-remaining-work.md](2026-10-02-remaining-work.md) | 남은 개발건 정리 (2026-10-02 기준) |
| [2026-10-02-battle-polish.md](2026-10-02-battle-polish.md) | 전투 연출이 허접한 원인과 A13 "전투 연출 손질" 신설 계획 |
| [2026-10-02-pvp-hold-no-kpi.md](2026-10-02-pvp-hold-no-kpi.md) | PvP 서버 Cloudflare 확정·착수 보류, Firebase 분석·KPI 측정 제외 (ADR-066·067) |
| [2026-10-02-A14-shot-slow-camera.md](2026-10-02-A14-shot-slow-camera.md) | 탄 비행 1.3배 느리게(중력 9.5)·카메라 탄 중심 추적, A14 신설 |
| [2026-10-02-damage-v3.md](2026-10-02-damage-v3.md) | 에셋 v0.26 피해 표현 v3 적용, A15 신설 (ADR-070) |
| [2026-10-02-quality-diagnosis.md](2026-10-02-quality-diagnosis.md) | 퀄리티 진단(Castle Busters 기준) 계획, 결과는 docs/quality/2026-10-02-gap-analysis.md |
| [2026-10-02-dev-practice.md](2026-10-02-dev-practice.md) | 빌드 앱 개발 도구 숨은 스위치 + 더미배 폭탄투하 연습, A23 신설 (ADR-073) |
| [2026-10-02-A21-match-length.md](2026-10-02-A21-match-length.md) | A21 판 길이 측정(난이도별 400판)과 3~4분 조정안 3개 (사용자 결정 대기) |
| [2026-10-02-camera-base-zoom.md](2026-10-02-camera-base-zoom.md) | 전장 축소 영향 파악 → 전투 기본 화면만 확대(카메라 baseWidth 축소, 렌더 전용) |
| [2026-10-02-R1a-sim-modules.md](2026-10-02-R1a-sim-modules.md) | R1a 행동 모듈·상태 효과 엔진 세부 계획, 설계 결정 제안 P1~P10 (ADR-074) |
| [2026-10-02-aim-visual-polish.md](2026-10-02-aim-visual-polish.md) | 당겨 쏠 때 조준 표시 다듬기(진주알 점선·화살촉·새총 주머니·10칸 힘 링·숫자 알약, 렌더 전용) |
| [2026-10-02-aim-commit-fuel-half.md](2026-10-02-aim-commit-fuel-half.md) | 조준 작업 커밋(공유 트리 덩어리 분리)과 배 움직임 반(1칸당 연료 2배, ADR-077), 돛 탑승 질문 답 |
| [2026-10-02-quality-recheck.md](2026-10-02-quality-recheck.md) | 퀄리티 재점검: 진단 항목 대조, 전투 아트 보강 A24 신설(ADR-079), A21 판 길이 재측정 방침 |
| [2026-10-02-quality-3-fun.md](2026-10-02-quality-3-fun.md) | 퀄리티 3차: 배 키우기(돛단배→슬루프)·선체 틀·판자 이음·보스 기믹·감정 연출·첫 10분, A25~A31 제안, 돛대 칸·돛 자리 (R1d 뒤) |
| [2026-10-02-R1d-balance.md](2026-10-02-R1d-balance.md) | R1d 40명 밸런스 1만 판 측정, 1차 조정 9건과 재측정 (ADR-082) |
| [2026-10-06-quality-4-hit-feel.md](2026-10-06-quality-4-hit-feel.md) | 퀄리티 4차: 전투 타격감(피해 비례 히트스톱·흔들림·줌, 파괴 조각·덩어리 붕괴, 소리 겹침, 해적 반응·발사, A30 감정 연출 흡수), A32 제안 |
