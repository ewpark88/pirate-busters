import 'package:flutter/material.dart';
import 'package:pirate_busters/battle/battle_session.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';
import 'package:pirate_busters/ui/hud/hud_scale.dart';
import 'package:pirate_busters/ui/hud/hud_style.dart';
import 'package:pirate_busters/ui/hud/move_controls.dart';
import 'package:pirate_busters/ui/hud/pause_menu.dart';
import 'package:pirate_busters/ui/hud/pirate_cards.dart';
import 'package:pirate_busters/ui/hud/result_overlay.dart';
import 'package:pirate_busters/ui/hud/top_bar.dart';

/// 전투 HUD 전체 (설계서 §13.4). 판정은 하지 않고 [BattleSession] 을 그리기만 한다.
class BattleHud extends StatelessWidget {
  const BattleHud({
    required this.session,
    required this.paused,
    required this.onPause,
    required this.onRestart,
    super.key,
  });

  final BattleSession session;
  final bool paused;
  final ValueChanged<bool> onPause;

  /// 새 판. `hotseat` 이 null 이면 지금 방식 그대로.
  final void Function({bool? hotseat}) onRestart;

  bool get _hotseat => session.humanSides.length == 2;

  /// 카드·이동 버튼을 보여줄 진영. 핫시트면 지금 턴 진영.
  int get _controlSide => _hotseat ? session.state.activeSide : 0;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: session,
    builder: (context, _) {
      final l10n = AppLocalizations.of(context);
      final myTurn = session.isHumanTurn;
      return HudScale(child: _layout(context, l10n, myTurn: myTurn));
    },
  );

  Widget _layout(
    BuildContext context,
    AppLocalizations l10n, {
    required bool myTurn,
  }) => Stack(
    children: [
      SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: TopBar(session: session)),
                  IconButton(
                    tooltip: l10n.pause,
                    onPressed: () => onPause(true),
                    icon: const Icon(Icons.pause_circle, size: 34),
                    color: HudColors.text,
                  ),
                ],
              ),
              const Spacer(),
              Opacity(
                opacity: myTurn ? 1 : 0.5,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    MoveControls(session: session, side: _controlSide),
                    const Spacer(),
                    PirateCards(session: session, side: _controlSide),
                    const Spacer(),
                    FilledButton(
                      onPressed: session.canAct ? session.endTurn : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: HudColors.border,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                      ),
                      child: Text(l10n.endTurn),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      if (!myTurn && !session.isOver)
        Align(
          alignment: const Alignment(0, -0.45),
          child: IgnorePointer(
            child: HudPanel(
              borderColor: HudColors.red,
              child: Text(
                l10n.enemyTurn,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
        ),
      if (session.isOver && session.playback == null)
        ResultOverlay(
          state: session.state,
          viewer: _hotseat ? null : 0,
          onPlayAgain: onRestart,
        ),
      if (paused)
        ColoredBox(
          color: const Color(0x88000000),
          child: PauseMenu(
            hotseat: _hotseat,
            onResume: () => onPause(false),
            onSurrender: () {
              onPause(false);
              session.surrender();
            },
            onOpponent: (hotseat) {
              onPause(false);
              onRestart(hotseat: hotseat);
            },
          ),
        ),
    ],
  );
}
