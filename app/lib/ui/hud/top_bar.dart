import 'package:flutter/material.dart';
import 'package:pirate_busters/battle/battle_session.dart';
import 'package:pirate_busters/battle/session_views.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';
import 'package:pirate_busters/ui/hud/hit_clear.dart';
import 'package:pirate_busters/ui/hud/hud_style.dart';
import 'package:pirate_busters/ui/hud/side_status.dart';
import 'package:pirate_busters/ui/hud/turn_timer.dart';
import 'package:pirate_busters/ui/meta_icons.dart';

/// 위 가운데: 남은 턴, 누구 턴, 턴 타이머, 바람 / 위 양쪽: 해적 체력·선장실·선원 (설계서 §13.4).
class TopBar extends StatelessWidget {
  const TopBar({
    required this.session,
    this.calm = false,
    this.opacity = 1,
    super.key,
  });

  final BattleSession session;

  /// 연출 중 진하기 (§13.4). 선체 패널은 피해 순간 잠깐 1 로 돌아온다.
  final double opacity;

  /// 화면 흔들림 줄이기 (설계서 §13.8).
  final bool calm;

  Widget _side(int side) {
    final crewHp = session.visibleCrewHp(side);
    final captain = session.visibleCaptain(side);
    return HitClear(
      // 해적 체력이나 선장실이 깎이는 순간 잠깐 또렷해진다 (§13.4).
      value: crewHp + captain,
      opacity: opacity,
      child: ShipStatusPanel(
        side: session.state.sides[side],
        crewHp: crewHp,
        captain: captain,
        calm: calm,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _side(0),
      Expanded(
        child: Center(
          // 영어가 길어도 줄어들 뿐 넘치지 않는다 (설계서 §14.4).
          child: AnimatedOpacity(
            key: const ValueKey('hud-top'),
            opacity: opacity,
            duration: const Duration(milliseconds: 220),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: _TurnInfo(session: session, calm: calm),
            ),
          ),
        ),
      ),
      _side(1),
    ],
  );
}

class _TurnInfo extends StatelessWidget {
  const _TurnInfo({required this.session, this.calm = false});

  final BattleSession session;
  final bool calm;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = session.state;
    final rules = state.rules;
    final side = state.activeSide;
    final owner = session.humanSides.length == 2
        ? l10n.playerTurn(side + 1)
        : (session.isHumanTurn ? l10n.yourTurn : l10n.enemyTurn);
    final seconds = (session.remainingMs + 999) ~/ 1000;
    final turnsLeft = (rules.maxTurns - state.turn + 1).clamp(
      0,
      rules.maxTurns,
    );
    return HudPanel(
      borderColor: HudColors.team(side),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          MetaIcons.image(MetaIcons.turns, size: 18),
          const SizedBox(width: 4),
          Text(l10n.turnsLeft(turnsLeft)),
          const SizedBox(width: 12),
          Text(owner, style: TextStyle(color: HudColors.team(side))),
          const SizedBox(width: 12),
          MetaIcons.image(MetaIcons.timer, size: 18),
          const SizedBox(width: 2),
          // 남은 5초는 내 턴에 초마다 튄다 (§2.3, A34).
          TurnTimer(seconds: seconds, pulse: session.isHumanTurn, calm: calm),
          const SizedBox(width: 12),
          _Wind(wind: state.wind),
        ],
      ),
    );
  }
}

/// 바람 화살표와 단계 칸 3개 (설계서 §2.4 “HUD 에는 화살표와 단계를 둔다”). 숫자 없이
/// 채운 칸 수가 세기다. 무풍이면 칸이 모두 비고 화살표 대신 흐린 점이다.
class _Wind extends StatelessWidget {
  const _Wind({required this.wind});

  final int wind;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final level = wind.abs();
    final label = wind == 0
        ? l10n.windCalm
        : l10n.windSemantics(wind > 0 ? l10n.windRight : l10n.windLeft, level);
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Row(
        key: ValueKey('wind-$wind'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.wind),
          const SizedBox(width: 4),
          if (wind == 0)
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: HudColors.mute,
                shape: BoxShape.circle,
              ),
            )
          else
            CustomPaint(
              size: const Size(16, 12),
              painter: WindArrow(dir: wind.sign),
            ),
          const SizedBox(width: 3),
          for (var i = 0; i < 3; i++)
            Container(
              width: 5,
              height: 8 + i * 3,
              margin: const EdgeInsets.only(left: 2),
              decoration: BoxDecoration(
                color: i < level ? HudColors.text : null,
                border: Border.all(color: HudColors.mute),
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
        ],
      ),
    );
  }
}

/// 바람 화살표: 바람이 부는 쪽(+1 오른쪽)을 가리킨다. 글꼴 아이콘 없이 그린다.
class WindArrow extends CustomPainter {
  const WindArrow({required this.dir});

  final int dir;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = HudColors.text
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    final y = size.height / 2;
    final tip = dir > 0 ? size.width - 1 : 1.0;
    final tail = dir > 0 ? 1.0 : size.width - 1;
    final back = tip - dir * size.height * .45;
    canvas
      ..drawLine(Offset(tail, y), Offset(tip, y), paint)
      ..drawLine(Offset(tip, y), Offset(back, y - size.height * .4), paint)
      ..drawLine(Offset(tip, y), Offset(back, y + size.height * .4), paint);
  }

  @override
  bool shouldRepaint(WindArrow old) => old.dir != dir;
}
