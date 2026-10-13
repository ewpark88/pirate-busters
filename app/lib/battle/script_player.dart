import 'dart:math' as math;

import 'package:pb_ai/pb_ai.dart';
import 'package:pb_sim/pb_sim.dart';

/// 상대 컨트롤러 턴 묶음의 재생 순서와 시계 (설계서 §2.1·§2.3·§5.5, A62).
///
/// 묶음의 커맨드 시각 `t` 는 [scriptMs] 로 잰다. 이 시계는 탄 연출과 그 뒤 쉼
/// ([settleMs]) 동안 멈춘다. 그래서 앞 탄이 오래 날아도 다음 해적의 생각 연출
/// (BALANCE.md A5.2)이 줄지 않고, 카메라가 착탄 지점에서 다음 해적으로 옮겨 간 뒤
/// 조준이 보인다. 시뮬레이션에는 묶음의 `t` 를 그대로 넘기므로 판정·리플레이는 같다.
class ScriptPlayer {
  /// 탄 연출이 끝난 뒤·상대 턴이 시작될 때 쉬는 시간. 카메라가 다음 해적으로 옮겨
  /// 가는 동안이다(카메라 복귀 1.2초와 같다). 판정에 들어가지 않는 연출 상수다.
  static const int settleMs = 1200;

  /// 이번 턴 묶음. 아직 계획 중이면 null.
  TurnBundle? bundle;

  /// AI 상대의 이번 턴 계획기. 프레임마다 후보를 나눠 평가한다 (BALANCE.md A5.1).
  AiPlanner? _planner;

  /// 다음에 낼 커맨드 위치.
  int index = 0;

  /// 묶음 시각을 재는 시계(밀리초).
  int scriptMs = 0;

  int _settleLeft = settleMs;

  /// 마지막 쉼이 끝난 [scriptMs]. 조준 진행은 여기서부터 찬다.
  int _aimFrom = 0;

  bool get settling => _settleLeft > 0;

  /// 새 턴: 묶음을 비우고 쉼부터 시작한다.
  void reset() {
    bundle = null;
    _planner = null;
    index = 0;
    scriptMs = 0;
    _settleLeft = settleMs;
    _aimFrom = 0;
  }

  /// 탄 연출이 끝났다: 다음 커맨드 전에 쉰다.
  void settle() => _settleLeft = settleMs;

  /// 탄 연출이 없는 프레임마다 [dtMs] 만큼 쉼을 줄이거나 시계를 흘린다.
  void tick(int dtMs) {
    if (_settleLeft <= 0) {
      scriptMs += dtMs;
      return;
    }
    _settleLeft -= dtMs;
    if (_settleLeft <= 0) {
      _settleLeft = 0;
      _aimFrom = scriptMs;
    }
  }

  /// 이번 턴 묶음을 준비한다. AI 는 계획이 끝날 때까지 null.
  TurnBundle? load(Controller? opponent, MatchState state) {
    if (bundle == null && opponent is AiController) {
      final planner = _planner ??= opponent.planner(state);
      if (!planner.step()) return null;
      bundle = planner.bundle;
    }
    return bundle ??= opponent?.turnFor(state);
  }

  /// 묶음을 다 냈는가.
  bool get finished {
    final b = bundle;
    return b != null && index >= b.commands.length;
  }

  /// 지금 낼 커맨드. 쉬는 중이거나 시각이 아직이면 null.
  Command? get due {
    final b = bundle;
    if (b == null || settling || index >= b.commands.length) return null;
    final c = b.commands[index];
    return c.t <= scriptMs ? c : null;
  }

  /// 다음 커맨드가 발사면 그 해적과 조준 진행(0~1). 쉬는 동안은 0 이라 카메라가
  /// 먼저 그 해적으로 간다. 진행은 발사 [showMs] 전부터(쉼이 끝난 뒤로) 0→1 로 찬다.
  ({int slot, double progress})? aim(int showMs) {
    final b = bundle;
    if (b == null || index >= b.commands.length) return null;
    final c = b.commands[index];
    if (c is! FireCommand) return null;
    if (settling) return (slot: c.slot, progress: 0.0);
    final window = math.max(1, math.min(showMs, c.t - _aimFrom));
    final left = c.t - scriptMs;
    return (slot: c.slot, progress: (1 - left / window).clamp(0.0, 1.0));
  }
}
