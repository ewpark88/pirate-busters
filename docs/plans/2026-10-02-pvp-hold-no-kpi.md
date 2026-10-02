# PvP 서버 계획 확정(착수 보류) + Firebase 분석·KPI 측정 제외

## Context
사용자 결정 (2026-10-02):
1. Firebase Analytics·Crashlytics 실제 연결과 수치 KPI 측정은 하지 않는다. 비공개 테스트는 피드백·리플레이로 판단한다 (ADR-067).
2. 네트워크 PvP 서버는 Cloudflare(2단계 Workers + KV/D1, 3단계 Workers + Durable Objects)로 확정하고 **계획만 잡는다.** 지금은 개발하지 않는다 (ADR-066).

## 한 일 (문서만)
- 설계서(사용자 승인): §1 스택 줄, §8.1 표 1행(Firebase 는 Remote Config 만), §11.1 이벤트·6주차·튜닝 지표(`sim_runner`·포커스 테스트), §11.2 PvP 인원 조건 삭제(착수 시점은 개발자가 정함), §11.3 KPI 표 → 비공개 테스트 판단 기준, 11장 제목.
- 계획서: 1.1·1.3 표(PvP 행 '착수 보류'), 재사용 목록, M7 이벤트·Crashlytics 주석, 5장 KPI 표 → 판단 기준, 7·8장 머리에 '착수 보류' + 서버 확정. 동기화 해시 갱신.
- 처음에는 PvP 를 A13·A14 로 옮기려 했다. 그런데 사용자가 "계획만" 잡으라고 했고, 다른 세션이 A13(전투 연출)·ADR-064·065 를 이미 써서 7·8장을 그 자리에 두고 보류 표시만 했다.

## 확인
- `dart run tool/check_doc_sync.dart` 통과.
