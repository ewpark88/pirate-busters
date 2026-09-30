import 'package:flutter/material.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';
import 'package:pirate_busters/ui/hud/hud_style.dart';

/// 판 결과 (간이판, 결과 화면 완성판은 M7 §13.5).
class ResultOverlay extends StatelessWidget {
  const ResultOverlay({
    required this.state,
    required this.viewer,
    required this.onPlayAgain,
    super.key,
  });

  final MatchState state;

  /// 결과를 보는 진영. 핫시트면 null(승자 번호로 보여준다).
  final int? viewer;
  final VoidCallback onPlayAgain;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final winner = state.winner;
    final title = winner < 0
        ? l10n.resultDraw
        : viewer == null
        ? l10n.playerWins(winner + 1)
        : (winner == viewer ? l10n.resultWin : l10n.resultLose);
    final how = switch (state.outcome) {
      MatchOutcome.sunk => l10n.outcomeSunk,
      MatchOutcome.floodSunk => l10n.outcomeFloodSunk,
      MatchOutcome.annihilation => l10n.outcomeAnnihilation,
      MatchOutcome.timeDecision => l10n.outcomeTimeDecision,
      MatchOutcome.surrender => l10n.outcomeSurrender,
      MatchOutcome.ongoing => '',
    };
    return ColoredBox(
      color: const Color(0x99000000),
      child: Center(
        child: HudPanel(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (state.outcome == MatchOutcome.sunk ||
                  state.outcome == MatchOutcome.floodSunk)
                // ‘격침!’ 배너 (설계서 §14.2).
                Text(
                  AppLocalizations.of(context).sunkBanner,
                  style: const TextStyle(fontSize: 48, color: HudColors.warn),
                ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 34,
                  color: winner < 0 ? HudColors.text : HudColors.team(winner),
                ),
              ),
              const SizedBox(height: 6),
              Text(how, style: const TextStyle(color: HudColors.mute)),
              const SizedBox(height: 16),
              FilledButton(onPressed: onPlayAgain, child: Text(l10n.playAgain)),
            ],
          ),
        ),
      ),
    );
  }
}
