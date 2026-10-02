import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart' show TextStyle;
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/app/app_theme.dart';
import 'package:pirate_busters/battle/battle_session.dart';
import 'package:pirate_busters/game/coords.dart';
import 'package:pirate_busters/game/weapon_styles.dart';

/// 턴을 넘기는 효과의 남은 턴 수 배지 (설계서 §10.4). 설치탄은 붙은 칸에서 그 해적의
/// 무기 그림이 기다리고, 투하·다시 물기는 터질 자리에 배지만 뜬다. 시뮬레이션의
/// 예약 목록([MatchState.effects])을 그리기만 한다.
class EffectBadges extends Component {
  EffectBadges({required this.session, this.weapons, super.priority});

  final BattleSession session;

  /// 붙어 있는 설치탄 그림. 없으면 배지만 그린다(테스트).
  final WeaponStyles? weapons;

  /// 남은 턴 수 글자. 화면이 로케일 숫자 형식으로 바꿔 넣는다 (설계서 §14.2).
  String Function(int turns) turnsText = (turns) => '$turns';

  /// 투하 예약 배지의 높이(월드 px, 해수면 위).
  static const double dropHeight = 96;
  static const double radius = 7;

  static final Paint _fill = Paint()..color = const Color(0xE614161C);
  static final Paint _ring = Paint()
    ..color = const Color(0xFFFFC24A)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.4;
  static final TextPaint _text = TextPaint(
    style: const TextStyle(
      fontFamily: AppFonts.display,
      fontSize: 10,
      color: Color(0xFFFFE082),
    ),
  );

  /// 효과 [e] 가 터질 자리(월드 px).
  Vector2 positionOf(TurnEffect e) {
    if (e.kind == EffectKind.flockDrop || e.cell < 0) {
      return Vector2(Coords.x(e.x), -dropHeight);
    }
    final ship = session.state.sides[e.target];
    final (x, y) = ship.frame.cellCenter(
      e.cell % ship.grid.width,
      e.cell ~/ ship.grid.width,
    );
    return Coords.point(x, y);
  }

  /// 붙어서 기다리는 효과: 그 해적의 무기 그림 옆에 배지를 단다.
  static bool _attached(EffectKind k) =>
      k == EffectKind.mineBlast ||
      k == EffectKind.gnawBite ||
      k == EffectKind.tentacle;

  @override
  void render(Canvas canvas) {
    for (final e in session.state.effects) {
      // 떠 있는 기뢰는 WorldMarks 가 수면에 그리고, 펌프 정지는 물어뜯기와 같은 칸이다.
      if (e.kind == EffectKind.floatMine || e.kind == EffectKind.pumpOff) {
        continue;
      }
      final at = positionOf(e);
      var badge = at;
      if (_attached(e.kind)) {
        // 설치탄은 붙어서 턴을 기다린다. 배지는 그 오른쪽 위에 붙인다.
        final style = weapons?.of(session.speciesOf(e.spec.id));
        if (style != null) {
          weapons!
              .sprite(style)
              .render(
                canvas,
                position: at,
                size: Vector2(22, 16.5),
                anchor: Anchor.center,
              );
        }
        badge = at + Vector2(9, -9);
      }
      drawBadge(canvas, badge, turnsText(e.turnsLeft));
    }
  }

  /// 남은 턴 수 배지 하나: 어두운 원, 금색 테두리, 숫자.
  static void drawBadge(Canvas canvas, Vector2 at, String label) {
    canvas
      ..drawCircle(at.toOffset(), radius, _fill)
      ..drawCircle(at.toOffset(), radius, _ring);
    _text.render(canvas, label, at, anchor: Anchor.center);
  }
}
