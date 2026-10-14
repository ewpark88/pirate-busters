# 다시 시작하기: 세션 3개 동시 착수 준비 (2026-10-14)

> 사용자가 다른 개발을 하고 돌아왔을 때 바로 세션 3개를 띄워 동시에 진행하기 위한 문서다. 현황 요약은 `docs/STATUS.md`, 단계별 기록은 `docs/PROGRESS.md`.

## 0. 지금 상태 한눈에 (main `811783c` 이후)

- **게임 정리(ADR-111):** S1·S3·S6 완료, S2·S4 는 사용자 확인 대기, S5(사용자 10판)는 아직이다.
- **실기기:** `R3CX90JQLEB` 에 최신 빌드를 깔았다. APK 는 `D:\Projects\pb-playtest\app-profile.apk`(프로필 빌드, 디버그 서명).
- **밸런스:** 피해 1.5배(ADR-115) 뒤 sim_runner 1,000판 결과다. B2 목표를 모두 맞춘다.

  | AI | 평균 턴 | 턴 제한 | 전멸 | 선장실 |
  | --- | --- | --- | --- | --- |
  | 보통 | 16.5 | 13.1% | 44.5% | 42.4% |
  | 어려움 | 14.2 | 3.6% | 50.9% | 45.5% |

- **작업 폴더:** 메인 폴더는 `main` 이다. 남은 worktree 는 없다(`D:/Projects/pb-wt/` 비어 있음). `app/web/` 은 손대지 않은 추적 밖 폴더다.

## 1. 시작 순서

1. 메인 세션(조율자) 하나를 연다. 아래 「조율자 첫 문장」을 붙여 넣는다.
2. 새 세션 3개를 연다. 각 세션에 아래 A·B·C 문구를 하나씩 붙여 넣는다. 세션 이름은 `pb-a`·`pb-b`·`pb-c` 처럼 알아보기 쉽게 짓는다.
3. 사용자가 S5 손맛 점검(10판)을 했다면 점검표 결과를 조율자에게 먼저 준다. 그러면 조율자가 A 의 범위를 그 결과로 바꿔 보낸다.

### 공통 규칙 (세 문구에 이미 들어 있다)
- 메인 폴더는 쓰지 않는다. 세션마다 `D:/Projects/pb-wt/<이름>` worktree 를 `origin/main` 기준 새 브랜치로 만든다. C 드라이브에는 아무것도 두지 않는다.
- 맡은 파일 범위 밖은 건드리지 않는다. ARB 처럼 같이 고치는 파일은 병합 때 양쪽을 살린다.
- 설계서·BALANCE.md 는 직접 고치지 않는다. 바꿀 안을 만들어 조율자에게 보내고, 사용자 승인을 받은 뒤에 고친다.
- 끝날 때 할 일:
  1. `bash tool/verify.sh` 를 통과시킨다.
  2. 커밋한다.
  3. `git fetch origin && git merge origin/main` 뒤 verify 를 다시 돌린다.
  4. 브랜치를 push 하고 `git push origin HEAD:main` 한다. 거절되면 fetch·merge·verify 를 다시 한다.
  5. worktree 를 지운다.
- force push·`--no-verify` 금지. 서명 키·`key.properties` 는 읽지 않는다.
- 중간 보고 없이 끝까지 한다. 끝나면 조율자에게 한국어로 짧게 보고한다. 권한에 막히면 우회하지 않고 바로 알린다.
- 경험상 세션이 worktree 만 만들고 턴을 끝내는 일이 잦다. 조율자는 멈춤 알림을 받으면 "이번 턴에 끝까지" 라고 다시 보낸다.

## 2. 조율자 첫 문장

```
docs/STATUS.md 와 docs/plans/2026-10-14-restart-3-sessions.md 를 읽고 조율자로 시작해.
pb-a·pb-b·pb-c 세션에 문서의 A·B·C 일을 SendMessage 로 보내고(notify_when_idle), 끝날 때마다 결과를 확인해 다음 일을 줘.
사용자 결정이 필요한 것(설계서·BALANCE 변경, 손맛 확인)만 모아서 나에게 물어봐. 모두 끝나면 연결한 기기에 최신 main 을 설치해.
```

## 3. 세션 A — 해역 1 밸런스·콘텐츠 다듬기

```
Pirate Busters 세션 A: 해역 1 밸런스·콘텐츠 다듬기. CLAUDE.md·docs/STATUS.md·docs/plans/2026-10-14-restart-3-sessions.md 를 먼저 읽어.
worktree: git -C D:/Projects/pirate-busters fetch origin && git -C D:/Projects/pirate-busters worktree add D:/Projects/pb-wt/a -b balance/sea1-polish origin/main
범위(파일 소유): app/assets/stages/sea1.json, app/lib/campaign/**, 캠페인 대사·미션 ARB, 관련 테스트, docs/PROGRESS.md 의 내 절, 제안 문서. 렌더(app/lib/game/**)·pb_sim 은 다른 세션 몫.
할 일 (재측정 근거: docs/PROGRESS.md 'S6 후속' 표, ADR-114):
1. 1-4: 어려움 대리 승률 27%(선장실을 자주 잃음) → 적 덱·적 배·성격을 조정해 앞뒤 판과 곡선을 맞춘다.
2. 1-7: 미션 '안 쓰러지기' 달성 0%(망대 저격 상대) → 달성 가능한 미션으로 바꾸거나 상대를 조정한다.
3. 1-10: 승률 97~100% 로 너무 쉬움 → 바람 판의 의도(바람 읽기)를 살리며 조금 어렵게.
4. 1-11 이 보스 1-12 보다 어려움(보통 대리 27% vs 40%) → 1-11 을 낮추거나 1-12 를 올려 마지막이 가장 어렵게.
5. 300줄에 닿은 app/lib/campaign/result_hero.dart(281줄)를 나눈다(ADR-107).
6. sim_runner 경고: 스타리 59%·히포 56% (같은 등급 평균 +5%p 초과). BALANCE 수치가 필요하면 바꿀 안(현재값→제안값→측정)만 docs/plans/YYYY-MM-DD-balance-proposal.md 에 쓰고 조율자에게 보낸다.
측정: app/test/s5_sea1_campaign_test.dart 방식(앱 경로, 보통·어려움 대리, 판마다 40시드)으로 전후 표. sim_runner 는 --jobs 6 이하.
끝: verify → 커밋 → main 병합·push → worktree 삭제 → 조율자에게 전후 표와 BALANCE 제안(있으면)만 짧게.
```

## 4. 세션 B — 화면·연출 후속 (S2·S4 에서 미룬 것)

```
Pirate Busters 세션 B: 화면·연출 후속. CLAUDE.md·docs/STATUS.md·docs/plans/2026-10-14-restart-3-sessions.md·docs/plans/2026-10-13-s2-wave-wind-visual.md·docs/plans/2026-10-13-s4-asset-candidates.md 를 먼저 읽어.
worktree: git -C D:/Projects/pirate-busters fetch origin && git -C D:/Projects/pirate-busters worktree add D:/Projects/pb-wt/b -b feat/render-followup origin/main
범위(파일 소유): app/lib/game/** (view 포함), app/lib/ui/hud/move_controls·top_bar·gap_bar, 사운드 서비스·효과음 에셋, docs/quality/, docs/ASSETS.md. 캠페인·sea1.json·pb_sim 은 다른 세션 몫.
할 일:
1. S2 에서 미룬 것: 상대 앞에서 막힐 때 멈춤 반동·짧은 진동(진동 설정 따름), 이동 중 카메라가 앞을 비워 주기, 구간 물빛 셰이더 경로(지금은 Dart 띠, 성능 비교 후 결정).
2. S4 에서 못 한 것: 물기둥 연속 프레임·파편 스프라이트 — CC0 를 다시 찾거나(라이선스 확인, docs/ASSETS.md 기록) 코드로 더 풍성하게. 안 쓰는 옛 fx 그림이 남았는지 확인(tool/import_assets_exclude.txt 도 갱신).
3. 저사양 모드 프레임 점검: 폭발·물보라·구간 물빛이 겹칠 때 프레임 시간 측정(테스트 또는 프로파일), 무거운 곳 줄이기.
4. 전후 캡처를 docs/quality/followup/ 에 남기고 README 에 볼 점.
끝: verify → 커밋 → main 병합·push → worktree 삭제 → 조율자에게 바꾼 것·사용자 확인 항목만 짧게.
```

## 5. 세션 C — 코드 품질·정리

```
Pirate Busters 세션 C: 코드 품질·정리. CLAUDE.md·docs/STATUS.md·docs/plans/2026-10-14-restart-3-sessions.md 를 먼저 읽어.
worktree: git -C D:/Projects/pirate-busters fetch origin && git -C D:/Projects/pirate-busters worktree add D:/Projects/pb-wt/c -b refactor/quality-pass origin/main
범위(파일 소유): packages/pb_sim/**, packages/pb_data/**, packages/pb_ai/**, tools/**, tool/**, app/lib 중 game/·campaign/ 을 뺀 곳(battle/·ui/ 의 hud 이동 3파일 제외·crew/·shipyard/·meta/·data/·story/·port/), 해당 테스트. 세션 A·B 의 파일은 건드리지 않는다.
할 일:
1. 300줄에 닿은 파일 나누기(ADR-107): battle_session 287·crew_ship 297·shipyard_model 283·cutscene_screen 280·match.dart 293 등. battle_game 299·camera_director 299·shot_view 292 는 세션 B, result_hero 281 은 세션 A 범위다.
2. 보류 기능 잔재 정리: MatchParams.hullPermille·sets(리플레이 형식 호환 확인 뒤), 쓰이지 않는 공개 API·export, 옛 규칙 주석. docs/plans/2026-10-13-arb-glossary.md 의 '코드 정리가 필요한 옛 규칙 키' 중 남은 것(hitTag 계열·noPirateCanFire·hull 등)을 코드와 ARB 에서 함께 지우기(ARB 는 ko/en 같은 커밋).
3. 테스트 빈 곳: 결정론(턴 효과 해시는 golden_effects 로 메워짐), 옛 저장 데이터 읽기(legacy_save_test 외에 progress·덱·리플레이), 2인 대전 흐름.
4. verify 시간 측정과 줄이기(가장 느린 테스트 파일 상위 5개, 골든 렌더 비용).
끝: verify → 커밋 → main 병합·push → worktree 삭제 → 조율자에게 정리 목록과 남긴 것만 짧게.
```

## 6. 사용자 확인이 남은 것 (조율자가 모아서 묻는다)

- **S2:** 숫자 없이 바람·잔잔한 구간이 읽히는지, 바람 소리 크기, 저사양 프레임. 전후 캡처 `docs/quality/s2/`.
- **S4:** 소리를 직접 듣고 확인한다.
  - 먼 포성 크기(가까운 포성보다 7dB 작게)
  - 착탄이 겹칠 때 전체 크기
  - 전투 곡 14.5초 반복 지점의 이음새
  - 사실풍 폭발이 화풍과 어울리는지
  - 전후 캡처 `docs/quality/s4/`
- **S5:** 10판 점검표 `docs/plans/2026-10-13-s5-playtest-checklist.md`. 결과에 따라 BALANCE·규칙을 조정하고 메타를 다시 논의한다.
