/// Pirate Busters AI. 사람과 같은 커맨드만 내보낸다 (설계서 §5).
///
/// 조준 솔버(§5.1)는 `pb_sim` 의 미리 계산(`previewShot`)으로 후보를 매기고,
/// 난이도(§5.2)·성격(§5.3)·턴 운영(§5.5)은 BALANCE.md A5 표를 따른다.
library;

export 'src/ai_controller.dart';
export 'src/aim_solver.dart';
export 'src/dials.dart';
export 'src/planner.dart';
export 'src/scoring.dart';
