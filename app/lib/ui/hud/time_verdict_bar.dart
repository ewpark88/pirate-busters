import 'package:flutter/material.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/battle/battle_session.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';
import 'package:pirate_busters/ui/hud/hud_style.dart';

/// 턴 제한 안내 띠 (설계서 §2.7·§13.4): 남은 턴이 [shownFrom] 이하가 되면
/// “턴 제한까지 N턴”과 양쪽 남은 해적 체력 비율을 보여 준다. 색은 시뮬의
/// [timeLeader](체력 비율 → 선장실 내구도 비율)를 따른다. 그리기만 하고 판정은
/// 시뮬이 한다.
class TimeVerdictBar extends StatelessWidget {
  const TimeVerdictBar({required this.session, super.key});

  final BattleSession session;

  /// 띠가 나오는 남은 턴(양쪽 합산).
  static const int shownFrom = 10;

  /// 남은 턴(이번 턴 포함). 0 이면 판이 끝났다.
  static int turnsLeft(MatchState state) =>
      (state.rules.maxTurns - state.turn + 1).clamp(0, state.rules.maxTurns);

  /// 띠를 보여 줄 때인가.
  static bool shows(MatchState state) {
    final left = turnsLeft(state);
    return !state.isOver && left > 0 && left <= shownFrom;
  }

  @override
  Widget build(BuildContext context) {
    final state = session.state;
    if (!shows(state)) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    // 사람 한 명이면 그쪽이 ‘나’, 핫시트는 비교 없이 규칙만 적는다.
    final me = session.humanSides.length == 1 ? session.humanSides.first : -1;
    Widget? compare;
    if (me >= 0) {
      final mine = crewHpPercent(state, me);
      final theirs = crewHpPercent(state, 1 - me);
      final lead = timeLeader(state);
      final color = lead == me
          ? HudColors.good
          : (lead < 0 ? HudColors.text : HudColors.danger);
      final hp = l10n.timeVerdictHp('$mine', '$theirs');
      compare = Text(
        leadByCaptain(state) ? '$hp · ${l10n.timeVerdictByHull}' : hp,
        style: TextStyle(color: color, fontSize: 13),
      );
    }
    return HudPanel(
      key: const ValueKey('time-verdict'),
      borderColor: HudColors.warn,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.timeVerdict(turnsLeft(state)),
            style: const TextStyle(color: HudColors.warn, fontSize: 13),
          ),
          if (compare != null) ...[const SizedBox(width: 10), compare],
        ],
      ),
    );
  }
}
