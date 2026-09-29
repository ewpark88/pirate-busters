import 'package:pb_sim/src/command/command.dart';
import 'package:pb_sim/src/match/match_state.dart';
import 'package:pb_sim/src/math/trig.dart';
import 'package:pb_sim/src/ship/blueprint.dart';
import 'package:pb_sim/src/ship/ship_grid.dart';

/// M1 임시 재장전: 3초. 해적별 재장전(설계서 §2.3)은 M5 에서 데이터로 바뀐다.
const int defaultReloadTicks = 3 * simTickHz;

/// FIRE 힘의 상한(×1000).
const int maxFirePower = 10000;

/// 결정론 전투 엔진 (설계서 §7). 같은 시드와 같은 커맨드면 같은 결과를 낸다.
class Match {
  Match._(this.state);

  /// [blueprints] 와 [decks] 는 [0] = 왼쪽, [1] = 오른쪽.
  factory Match.start({
    required int seed,
    required List<Blueprint> blueprints,
    required List<List<String>> decks,
  }) {
    if (blueprints.length != 2 || decks.length != 2) {
      throw ArgumentError('설계도와 덱은 진영마다 하나씩 2개여야 한다');
    }
    return Match._(
      MatchState(
        seed: seed,
        sides: [
          for (var i = 0; i < 2; i++)
            SideState(ShipGrid.fromBlueprint(blueprints[i]), decks[i]),
        ],
      ),
    );
  }

  final MatchState state;

  final List<Command> _log = [];

  /// 지금까지 [step] 에 들어온 현재 틱 커맨드(적용 순서). 리플레이 저장용.
  List<Command> get commandLog => List.unmodifiable(_log);

  bool get isOver => state.isOver;

  /// 한 틱 진행한다. [commands] 중 현재 틱이 아닌 것은 무시한다.
  ///
  /// 순서: 커맨드 정렬(tick → side → 종류 → slot) → 적용 → 재장전 감소 → 틱 증가.
  void step([List<Command> commands = const []]) {
    if (state.isOver) return;
    final now = [
      for (final c in commands)
        if (c.tick == state.tick) c,
    ]..sort(Command.compare);
    for (final c in now) {
      _log.add(c);
      if (state.isOver) break;
      _apply(c);
    }
    for (final side in state.sides) {
      final reload = side.reloadTicks;
      for (var i = 0; i < reload.length; i++) {
        if (reload[i] > 0) reload[i]--;
      }
    }
    state.tick++;
    if (!state.isOver && state.tick >= matchDurationTicks) {
      state.outcome = MatchOutcome.timeUp;
    }
  }

  void _apply(Command c) {
    final side = state.sides[c.side];
    switch (c) {
      case FireCommand():
        if (!side.isSlotOccupied(c.slot)) return;
        if (side.reloadTicks[c.slot] > 0) return;
        if (c.angle < 0 || c.angle >= fullTurnMdeg) return;
        if (c.power < 0 || c.power > maxFirePower) return;
        side.shots.add(
          FiredShot(
            tick: c.tick,
            slot: c.slot,
            angle: c.angle,
            power: c.power,
          ),
        );
        side.reloadTicks[c.slot] = defaultReloadTicks;
      case TapCommand():
        // 비행 중 2단 동작은 투사체가 생기는 M2 에서 연결한다.
        break;
      case SurrenderCommand():
        state
          ..outcome = MatchOutcome.surrender
          ..winner = 1 - c.side;
    }
  }
}
