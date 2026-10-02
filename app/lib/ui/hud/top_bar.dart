import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/battle/battle_session.dart';
import 'package:pirate_busters/battle/session_views.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';
import 'package:pirate_busters/ui/hud/hud_style.dart';
import 'package:pirate_busters/ui/meta_icons.dart';

/// 위 가운데: 남은 턴, 누구 턴, 턴 타이머, 바람 / 위 양쪽: 선체·침수·선원 (설계서 §13.4).
class TopBar extends StatelessWidget {
  const TopBar({required this.session, super.key});

  final BattleSession session;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SideStatus(side: session.state.sides[0]),
      Expanded(
        child: Center(
          // 영어가 길어도 줄어들 뿐 넘치지 않는다 (설계서 §14.4).
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: _TurnInfo(session: session),
          ),
        ),
      ),
      SideStatus(side: session.state.sides[1]),
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
          _Wind(wind: state.wind),
        ],
      ),
    );
  }
}

class _Wind extends StatelessWidget {
  const _Wind({required this.wind});

  final int wind;

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
    ],
  );
}

/// 한 배의 선체 내구도·침수량·생존 선원 (설계서 §13.4).
class SideStatus extends StatelessWidget {
  const SideStatus({required this.side, super.key});

  final SideState side;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final grid = side.grid;
    final hull = grid.initialTotalHp == 0
        ? 0.0
        : grid.totalHp / grid.initialTotalHp;
    final flood = NumberFormat(
      '0.0',
      Localizations.localeOf(context).toLanguageTag(),
    ).format(side.flood / 10);
    final alive = side.crew.pirates
        .where((p) => p.status != PirateStatus.down)
        .length;
    return SizedBox(
      width: 160,
      child: HudPanel(
        borderColor: HudColors.team(side.side),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                MetaIcons.image(MetaIcons.hull, size: 16),
                const SizedBox(width: 2),
                Text(l10n.hull),
                const SizedBox(width: 6),
                Expanded(
                  child: LinearProgressIndicator(
                    value: hull,
                    minHeight: 8,
                    color: HudColors.team(side.side),
                    backgroundColor: HudColors.panelHi,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            _IconText(MetaIcons.flood, l10n.flood(flood)),
            _IconText(MetaIcons.crew, l10n.crewAlive(alive, side.crew.size)),
          ],
        ),
      ),
    );
  }
}

/// 아이콘과 글자 한 줄 (설계서 §13.4).
class _IconText extends StatelessWidget {
  const _IconText(this.icon, this.text);

  final String icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      MetaIcons.image(icon, size: 16),
      const SizedBox(width: 2),
      Flexible(child: Text(text, overflow: TextOverflow.ellipsis)),
    ],
  );
}
