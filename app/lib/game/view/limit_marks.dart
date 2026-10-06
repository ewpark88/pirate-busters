import 'dart:ui';

import 'package:flame/components.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/battle/battle_session.dart';
import 'package:pirate_busters/game/coords.dart';
import 'package:pirate_busters/game/sprites.dart';
import 'package:pirate_busters/game/view/shot_view.dart';

/// 이동 한계 표식 (설계서 §2.6): 전진 한계는 암초와 부표 줄, 후퇴 한계는 불빛 부표.
///
/// 물 위 소품이라 배보다 뒤에 그린다. 탄과 같은 겹에 그리면 확대했을 때 등대가
/// 배를 덮는다(docs/quality/2026-10-02-gap-analysis.md).
class LimitMarks extends Component {
  LimitMarks({required this.session, required this.sprites, super.priority});

  final BattleSession session;
  final BattleSprites sprites;

  /// 그림 안에서 한계선·수면이 닿는 점(그림 px). 전진 한계는 부표 줄 끝과 암초
  /// 사이, 후퇴 한계는 부표 밑동이다. 그림은 오른쪽(+x)을 보는 배 기준이다.
  static final Vector2 forwardAnchor = Vector2(150, 96);
  static final Vector2 backAnchor = Vector2(40, 96);

  @override
  void render(Canvas canvas) {
    final state = session.state;
    final (lo, hi) = moveLimits(state.rules, state.turn);
    for (final side in state.sides) {
      final facing = facingOf(side.side);
      final start = startBowX(side.side);
      _limit(
        canvas,
        BattleSprites.limitForward,
        // 초계선 보스는 전진 한계가 턴마다 다가온다 (설계서 §5.4).
        Coords.x(start + facing * (hi + side.forwardBonus)),
        facing,
        forwardAnchor,
      );
      _limit(
        canvas,
        BattleSprites.limitBack,
        Coords.x(
          ShotView.sternAt(start + facing * lo, facing, side.grid.width),
        ),
        facing,
        backAnchor,
      );
    }
  }

  void _limit(Canvas c, String file, double x, int facing, Vector2 anchor) {
    final sprite = sprites.get(file);
    c
      ..save()
      ..translate(x, 0)
      ..scale(facing.toDouble(), 1);
    sprite.render(c, position: -anchor, size: sprite.srcSize / 2);
    c.restore();
  }
}
