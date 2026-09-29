/// Pirate Busters 결정론 전투 시뮬레이션.
///
/// 같은 시드와 같은 커맨드 목록이면 어떤 기기에서든 같은 결과를 낸다 (설계서 §7).
/// 이 패키지에서는 `double`, `dart:math`, `Random`, `DateTime` 을 쓰지 않는다
/// (`tool/check_architecture.dart` 가 검사한다).
library;

/// 시뮬레이션 고정 틱 속도(Hz). 렌더는 두 틱 사이를 보간한다 (설계서 §7.1).
const int simTickHz = 30;
