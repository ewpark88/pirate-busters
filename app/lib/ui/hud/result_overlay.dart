import 'package:flutter/material.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/app/app_theme.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';
import 'package:pirate_busters/ui/hud/hud_style.dart';
import 'package:pirate_busters/ui/kit/kit_art.dart';
import 'package:pirate_busters/ui/kit/kit_motion.dart';
import 'package:pirate_busters/ui/kit/pb_button.dart';
import 'package:pirate_busters/ui/kit/pb_panel.dart';

/// 둘이서·테스트 대전의 판 결과 (설계서 §13.4·§13 공통 키트). 캠페인 결과는 StageResultScreen(§13.5).
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
        child: PbPanel(
          padding: const EdgeInsets.fromLTRB(28, 18, 28, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (state.outcome == MatchOutcome.sunk ||
                  state.outcome == MatchOutcome.floodSunk)
                // ‘격침!’ 배너 (설계서 §14.2).
                PopIn(
                  child: OutlinedText(
                    AppLocalizations.of(context).sunkBanner,
                    size: 48,
                    color: HudColors.warn,
                    font: AppFonts.display,
                    stroke: 6,
                  ),
                ),
              OutlinedText(
                title,
                size: 34,
                color: winner < 0 ? HudColors.text : HudColors.team(winner),
                font: AppFonts.display,
                stroke: 5,
              ),
              const SizedBox(height: 6),
              Text(how, style: const TextStyle(color: HudColors.mute)),
              const SizedBox(height: 16),
              PbButton(label: l10n.playAgain, onPressed: onPlayAgain),
            ],
          ),
        ),
      ),
    );
  }
}
