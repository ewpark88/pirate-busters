# Changelog

이 프로젝트의 사용자에게 보이는 변경을 기록한다. 형식은 [Keep a Changelog](https://keepachangelog.com/ko/1.1.0/),
버전은 CLAUDE.md 「브랜치·커밋·버전」 규칙(MVP 동안 `0.<마일스톤>.PATCH+BUILD`)을 따른다.
분류: Added / Changed / Fixed / Removed / Balance. 릴리스 절차는 `docs/RELEASE.md`.

## [Unreleased]

## [0.2.0] - 2026-09-29

### Added
- 턴제 전투 루프: 턴 묶음 커맨드(FIRE·TAP·END_TURN·SURRENDER), 25초 턴, 양쪽 합쳐 30턴
- 탄도(포물선+바람)와 블록 타격·손상 단계·원형 폭발, 용골 연결이 끊긴 블록 붕괴
- 해적 출전 코스트 검사, 선실 파괴 시 낙하·복귀, 격침·전멸·항복 승리
- 리플레이 v3 와 턴 해시 불일치 검출

## [0.1.0] - 2026-09-29

### Added
- 결정론 시뮬레이션 코어: ×1000 고정소수점, 정수 삼각함수, xorshift32 난수
- 격자 배·커맨드·30Hz 틱 루프, 상태 해시, 리플레이 저장·재생
