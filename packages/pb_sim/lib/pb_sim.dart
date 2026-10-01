/// Pirate Busters 결정론 전투 시뮬레이션.
///
/// 같은 시드와 같은 커맨드 목록이면 어떤 기기에서든 같은 결과를 낸다 (설계서 §7).
/// 이 패키지에서는 `double`, `dart:math`, `Random`, `DateTime` 을 쓰지 않는다
/// (`tool/check_architecture.dart` 가 검사한다).
library;

export 'src/combat/crack_spread.dart';
export 'src/combat/flight.dart' show predictFirstHit;
export 'src/combat/impact.dart';
export 'src/combat/launch.dart';
export 'src/combat/preview.dart';
export 'src/command/command.dart';
export 'src/hash/state_hasher.dart';
export 'src/match/controller.dart';
export 'src/match/headless.dart';
export 'src/match/judge.dart';
export 'src/match/match.dart';
export 'src/match/match_state.dart';
export 'src/match/rules.dart';
export 'src/match/sim_event.dart';
export 'src/match/turn_effects.dart';
export 'src/math/fx.dart';
export 'src/math/int_math.dart';
export 'src/math/trig.dart';
export 'src/pirate/ammo.dart';
export 'src/pirate/crew.dart';
export 'src/pirate/pirate_spec.dart';
export 'src/pirate/range_grade.dart';
export 'src/projectile/grid_trace.dart';
export 'src/projectile/projectile.dart';
export 'src/projectile/shot_trace.dart';
export 'src/random/xorshift32.dart';
export 'src/replay/replay.dart';
export 'src/ship/blueprint.dart';
export 'src/ship/build_check.dart';
export 'src/ship/flooding.dart';
export 'src/ship/hull.dart';
export 'src/ship/material.dart';
export 'src/ship/module.dart';
export 'src/ship/module_state.dart';
export 'src/ship/motion.dart';
export 'src/ship/ship_grid.dart';
export 'src/ship/ship_stats.dart';
export 'src/ship/support.dart';
export 'src/world/wave.dart';
export 'src/world/world.dart';
