import 'package:pb_sim/pb_sim.dart';

/// M4 연습 상대 ‘허수아비’ (ADR-029). M6 AI 가 들어오면 지운다.
///
/// 사람과 같은 커맨드만 낸다: 상대 배의 블록 하나를 골라 닿는 각도를 찾고, 각도에
/// 오차를 섞어 쏠 수 있는 해적 2명까지 쏜 뒤 조금 움직이고 턴을 넘긴다. 난수는
/// 매치 시드와 턴 번호로만 뽑아 같은 판이면 같은 수를 둔다.
class DummyController implements Controller {
  const DummyController({this.errorMdeg = 4000});

  /// 각도 오차 범위(±밀리도).
  final int errorMdeg;

  @override
  TurnBundle turnFor(MatchState state) {
    final rng = XorShift32(mixSeed(state.seed ^ (state.turn * 7919)));
    final me = state.sides[state.activeSide];
    final commands = <Command>[];
    var t = 1500;
    for (var slot = 0; slot < me.crew.size; slot++) {
      if (commands.length == state.rules.firesPerTurn) break;
      if (!me.canFire(slot)) continue;
      // 닿는 각도를 못 찾으면 대충 45° 로 쏜다(허수아비답게).
      final angle = _aim(state, slot, rng, t) ?? 45000;
      final error = rng.nextRange(-errorMdeg, errorMdeg + 1);
      commands.add(
        FireCommand(
          t: t,
          slot: slot,
          angle: angle + error,
          power: maxFirePower,
        ),
      );
      t += 3500;
    }
    if (rng.nextChance(1, 2)) {
      commands.add(MoveCommand(t: t, dx: rng.nextRange(-30, 31)));
      t += 1500;
    }
    commands.add(EndTurnCommand(t: t + 500));
    return TurnBundle(
      turn: state.turn,
      side: state.activeSide,
      commands: commands,
    );
  }

  /// 상대 배의 블록 하나에 닿는 가장 낮은 각도(밀리도). 없으면 null.
  int? _aim(MatchState state, int slot, XorShift32 rng, int t) {
    final target = state.sides[1 - state.activeSide];
    final grid = target.grid;
    final cells = <int>[];
    // 물 위로 드러난 블록만 노린다(물 아래는 탄이 닿지 않는다).
    for (var i = 0; i < grid.cellCount; i++) {
      final top = (i ~/ grid.width + 1) * cellUnit;
      if (grid.hasBlockAt(i) && top > target.draft) cells.add(i);
    }
    if (cells.isEmpty) return null;
    final cell = cells[rng.nextInt(cells.length)];
    final tx = cell % grid.width;
    final ty = cell ~/ grid.width;
    final ms = realMs(state, effectiveMs(state, t));
    final wind = state.wind * state.rules.windAccel;
    for (var angle = 2000; angle <= 80000; angle += 500) {
      final p = launchShot(
        state,
        slot: slot,
        angle: angle,
        power: maxFirePower,
        ms: ms,
      );
      while (!p.isExpired && p.y >= 0) {
        final x0 = p.x;
        final y0 = p.y;
        p.advance(wind);
        final at = msAfterTicks(ms, p.age);
        final (lx0, ly0) = toShipLocal(state, target.side, at, x0, y0);
        // 시뮬레이션처럼 해수면에서 자른다 (물 아래는 맞지 않는다).
        var x1 = p.x;
        var y1 = p.y;
        if (y1 < 0) {
          x1 = y0 <= 0 ? x0 : x0 + roundDiv((x1 - x0) * y0, y0 - y1);
          y1 = 0;
        }
        final (lx1, ly1) = toShipLocal(state, target.side, at, x1, y1);
        final hit = traceCells(
          lx0,
          ly0,
          lx1,
          ly1,
          (cx, cy) => cx == tx && cy == ty,
        );
        if (hit != null) return angle;
      }
    }
    return null;
  }
}
