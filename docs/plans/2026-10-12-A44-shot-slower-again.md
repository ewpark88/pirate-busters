# A44 보정: 탄 비행 1.3배 더 느리게 (중력 5.6 → 3.3)

## Context
A44(ADR-095, 아직 커밋 전)로 중력을 9.5 → 5.6칸/초² 로 낮췄지만, 사용자가 탄을 더 느리게 해 달라고 했다. 사용자 선택: **1.3배 더** (2026-10-12). A14·A44 와 같은 방식으로 사거리는 그대로 두고 중력과 등급 탄속을 함께 낮춘다. A44 가 아직 커밋·병합 전이라 새 단계를 만들지 않고 A44 를 고쳐 쓴다(같은 작업을 이어서 함).

## 새 값 (계산 끝)
- `gravityPerTick` 622 → **368** (실제 3.312칸/초², 짝수 유지)
- 바람 1단계 `windAccelPerStep` 15 → **9** (자동 계산)
- 탄속 표: 짧음 **9280** · 보통 **10919** · 긺 **12869** · 매우 긺 **14785**
- 최대 힘·45° 비행: 짧음 4.0 · 보통 4.7 · 긺 5.5 · 매우 긺 6.3초

## 작업
1. `docs/BALANCE.md` A2.8 탄도 시간 표 (사용자 승인): 중력 3.3(이전 5.6 → 9.5 → 16 이력), 탄속·비행 시간·목표(긴 사거리 5.5초 안팎) 갱신.
2. `packages/pb_sim/lib/src/world/world.dart` `gravityPerTick` 과 주석, `packages/pb_sim/lib/src/pirate/range_grade.dart` 탄속 표·주석.
3. `packages/pb_sim/test/ballistics_test.dart` 상수·주석 기대값(368, 긺 탄속 단위) 갱신. 비행 틱 기대가 BALANCE 표에서 유도되면 그대로 확인.
4. 골든 리플레이 재생성(`packages/pb_sim/test/golden/*`)과 고정 해시 테스트(`r1a_effects_test`·`r1a2_unique_test` 등) 갱신 — A44 때 쓴 방법 그대로.
5. 문서: ADR-095 결정 문구(9.5 → 3.3, 2단계 조정 기록), 계획서 A44 제목·체크 항목·완료 조건(5.5초), `/doc-sync` 해시 갱신, PROGRESS A44, CHANGELOG 문구(약 1.7배, 긴 사거리 약 5.5초).
6. 앱 쪽 확인: `app/lib/game/camera_director.dart` 등 비행 시간 가정이 있는지 grep, AI(`pb_ai`) 탐색이 비행 틱 상한에 걸리지 않는지 확인.

## 검증
- `(cd packages/pb_sim && dart test)`, `pb_ai` 테스트
- `dart run tool/check_doc_sync.dart`
- `bash tool/verify.sh` 전체 통과
- 사람 확인(실기기): 긴 사거리 최대 힘 약 5.5초, 판이 늘어지지 않는지
