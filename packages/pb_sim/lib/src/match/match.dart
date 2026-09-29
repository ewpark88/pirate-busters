import 'package:pb_sim/src/combat/flight.dart';
import 'package:pb_sim/src/command/command.dart';
import 'package:pb_sim/src/match/match_state.dart';
import 'package:pb_sim/src/match/sim_event.dart';
import 'package:pb_sim/src/math/trig.dart';
import 'package:pb_sim/src/pirate/pirate_spec.dart';
import 'package:pb_sim/src/projectile/projectile.dart';
import 'package:pb_sim/src/ship/blueprint.dart';

/// 결정론 전투 엔진 (설계서 §7). 같은 시드와 같은 커맨드면 같은 결과를 낸다.
class Match {
  Match._(this.state);

  /// [blueprints] 와 [decks] 는 [0] = 왼쪽, [1] = 오른쪽. 덱의 해적 id 는
  /// [pirates] 에서 찾는다. [wind] 는 스테이지 바람(1/1000칸/틱²).
  factory Match.start({
    required int seed,
    required List<Blueprint> blueprints,
    required List<List<String>> decks,
    required PirateCatalog pirates,
    int wind = 0,
  }) {
    if (blueprints.length != 2 || decks.length != 2) {
      throw ArgumentError('설계도와 덱은 진영마다 하나씩 2개여야 한다');
    }
    return Match._(
      MatchState(
        seed: seed,
        wind: wind,
        sides: [
          for (var i = 0; i < 2; i++)
            SideState(
              side: i,
              blueprint: blueprints[i],
              deck: [for (final id in decks[i]) pirates.byId(id)],
            ),
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
  /// 순서: 커맨드(tick → side → 종류 → slot) → 배 이동(진영 순) → 투사체(id 순)
  /// → 재장전·헤엄 → 승리 판정 → 틱 증가. [MatchState.events] 는 새로 채운다.
  void step([List<Command> commands = const []]) {
    if (state.isOver) return;
    state.events.clear();
    final now = [
      for (final c in commands)
        if (c.tick == state.tick) c,
    ]..sort(Command.compare);
    for (final c in now) {
      _log.add(c);
      if (state.isOver) break;
      _apply(c);
    }
    if (state.isOver) {
      state.tick++;
      return;
    }
    for (final side in state.sides) {
      if (side.motion.step()) {
        state.events.add(
          SimEvent(SimEventKind.moveLimit, side: side.side),
        );
      }
    }
    advanceProjectiles(state);
    for (final side in state.sides) {
      side.crew.tick(side.side, state.events);
    }
    _judge();
    state.tick++;
    if (!state.isOver && state.tick >= matchDurationTicks) {
      state.outcome = MatchOutcome.timeUp;
    }
  }

  void _apply(Command c) {
    final side = state.sides[c.side];
    switch (c) {
      case FireCommand():
        if (!side.crew.canFire(c.slot)) return;
        if (c.angle < 0 || c.angle >= fullTurnMdeg) return;
        if (c.power < 0 || c.power > maxFirePower) return;
        final pirate = side.crew.pirateAt(c.slot)!;
        final cabin = side.cabins[c.slot];
        final (x, y) = side.frame.cellCenter(cabin.x, cabin.y);
        final id = state.nextProjectileId++;
        state.projectiles.add(
          Projectile.launch(
            id: id,
            side: c.side,
            slot: c.slot,
            spec: pirate.spec,
            x: x,
            y: y,
            angle: c.angle,
            power: c.power,
          ),
        );
        pirate.reload = pirate.spec.reloadTicks;
        side.shotsFired++;
        state.events.add(
          SimEvent(
            SimEventKind.fire,
            side: c.side,
            slot: c.slot,
            x: x,
            y: y,
            value: id,
          ),
        );
      case TapCommand():
        // 비행 중 2단 동작(onTap)은 MVP 에서 쓰지 않는다 (개발 계획서 M5).
        break;
      case MoveCommand():
        if (c.dir < -1 || c.dir > 1) return;
        side.motion.dir = c.dir;
      case SurrenderCommand():
        state
          ..outcome = MatchOutcome.surrender
          ..winner = 1 - c.side;
    }
  }

  /// 전멸 → 파괴 순으로 본다. 두 배가 같은 틱에 끝나면 무승부(winner −1).
  void _judge() {
    for (final outcome in const [
      MatchOutcome.annihilation,
      MatchOutcome.destruction,
    ]) {
      final lost = [
        for (final s in state.sides)
          outcome == MatchOutcome.annihilation
              ? s.crew.allDown
              : s.grid.totalHp == 0,
      ];
      if (!lost[0] && !lost[1]) continue;
      state
        ..outcome = outcome
        ..winner = lost[0] && lost[1] ? -1 : (lost[0] ? 1 : 0);
      return;
    }
  }
}
