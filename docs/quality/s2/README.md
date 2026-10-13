# S2 전후 캡처 — 바람과 파도 구간 (2026-10-13)

같은 시드·같은 장면을 S1 병합 직후 `main`(before)과 S2(after)로 그렸다. 960×440, 저사양 모드(포말 고정), 90프레임(3초) 뒤. 만든 테스트: `app/test/s2_wave_wind_test.dart` ‘바다·바람 장면 골든’.

| 장면 | before | after | 볼 것 |
| --- | --- | --- | --- |
| 전체 보기, 가운데 잔잔·바깥 거침 | before_zones_overview.png | after_zones_overview.png | 가운데 맑은 물빛·평평한 수면, 바깥 짙은 물빛·높은 너울 |
| 전체 보기, 가운데 거침·바깥 잔잔 | before_zones_overview_rough_middle.png | after_zones_overview_rough_middle.png | 가운데 큰 너울과 짙은 물, 배 자리는 평평 |
| 기본 화면, 바람 −3 | before_wind_left3.png | after_wind_left3.png | 깃발·돛·물마루·물보라가 왼쪽 |
| 기본 화면, 무풍 | before_wind_calm.png | after_wind_calm.png | 깃발 처짐, 물보라 없음 |
| 기본 화면, 바람 +3 | before_wind_right3.png | after_wind_right3.png | 깃발·돛·물마루·물보라가 오른쪽 |

정지 화면이라 구름 흐름·포말 흐름·바람 소리는 실기기에서 확인한다.
