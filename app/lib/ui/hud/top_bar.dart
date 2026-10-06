import 'package:flutter/material.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/battle/battle_session.dart';
import 'package:pirate_busters/battle/session_views.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';
import 'package:pirate_busters/ui/hud/hud_style.dart';
import 'package:pirate_busters/ui/hud/side_status.dart';
import 'package:pirate_busters/ui/meta_icons.dart';

/// 위 가운데: 남은 턴, 누구 턴, 턴 타이머, 바람 / 위 양쪽: 선체·침수·선원 (설계서 §13.4).
class TopBar extends StatelessWidget {
  const TopBar({required this.session, this.calm = false, super.key});

  final BattleSession session;

  /// 화면 흔들림 줄이기 (설계서 §13.8).
  final bool calm;

  Widget _side(int side) => ShipStatusPanel(
    side: session.state.sides[side],
    hull: session.visibleHull(side),
    sunkPercent: session.state.rules.sunkHullPercent,
    calm: calm,
  );

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _side(0),
      Expanded(
        child: Center(
          // 영어가 길어도 줄어들 뿐 넘치지 않는다 (설계서 §14.4).
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: _TurnInfo(session: session),
          ),
        ),
      ),
      _side(1),
    ],
  );
}

class _TurnInfo extends StatelessWidget {
  const _TurnInfo({required this.session});

  final BattleSession session;

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
    final timerColor = seconds <= 5
        ? HudColors.danger
        : (seconds <= 10 ? HudColors.warn : HudColors.text);
    final turnsLeft = (rules.maxTurns - state.turn + 1).clamp(
      0,
      rules.maxTurns,
    );
    return HudPanel(
      borderColor: HudColors.team(side),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (rules.isStorm(state.turn)) ...[
            Text(l10n.stormTime, style: const TextStyle(color: HudColors.warn)),
            const SizedBox(width: 10),
          ],
          MetaIcons.image(MetaIcons.turns, size: 18),
          const SizedBox(width: 4),
          Text(l10n.turnsLeft(turnsLeft)),
          const SizedBox(width: 12),
          Text(owner, style: TextStyle(color: HudColors.team(side))),
          const SizedBox(width: 12),
          MetaIcons.image(MetaIcons.timer, size: 18),
          const SizedBox(width: 2),
          Text(
            '$seconds',
            style: TextStyle(color: timerColor, fontSize: 22),
          ),
          const SizedBox(width: 12),
          _Wind(wind: state.wind, note: _windNote(context, state)),
        ],
      ),
    );
  }
}

/// 이번 턴 바람에 걸린 상태: 램프의 무풍이 알바의 역풍보다 앞선다 (설계서 §4.8).
String? _windNote(BuildContext context, MatchState state) {
  final status = state.sides[state.activeSide].status;
  final l10n = AppLocalizations.of(context);
  if (status.windIgnoreTurn == state.turn) return l10n.windCalm;
  if (status.windReverseTurn == state.turn) return l10n.windReversed;
  return null;
}

class _Wind extends StatelessWidget {
  const _Wind({required this.wind, this.note});

  final int wind;

  /// 역풍·무풍 표시. 없으면 null.
  final String? note;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(AppLocalizations.of(context).wind),
      const SizedBox(width: 4),
      Icon(
        wind >= 0 ? Icons.arrow_forward : Icons.arrow_back,
        size: 16,
        color: wind == 0 ? HudColors.mute : HudColors.text,
      ),
      Text('${wind.abs()}'),
      if (note != null) ...[
        const SizedBox(width: 4),
        Text(note!, style: const TextStyle(color: HudColors.warn)),
      ],
    ],
  );
}
