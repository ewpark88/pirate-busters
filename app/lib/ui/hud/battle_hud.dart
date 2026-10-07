import 'package:flutter/material.dart';
import 'package:pirate_busters/app/app_theme.dart';
import 'package:pirate_busters/battle/battle_session.dart';
import 'package:pirate_busters/battle/playback.dart';
import 'package:pirate_busters/battle/session_views.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';
import 'package:pirate_busters/port/port_widgets.dart';
import 'package:pirate_busters/ui/hud/gap_bar.dart';
import 'package:pirate_busters/ui/hud/hud_scale.dart';
import 'package:pirate_busters/ui/hud/hud_style.dart';
import 'package:pirate_busters/ui/hud/move_controls.dart';
import 'package:pirate_busters/ui/hud/pause_menu.dart';
import 'package:pirate_busters/ui/hud/pirate_cards.dart';
import 'package:pirate_busters/ui/hud/result_overlay.dart';
import 'package:pirate_busters/ui/hud/time_verdict_bar.dart';
import 'package:pirate_busters/ui/hud/top_bar.dart';
import 'package:pirate_busters/ui/kit/kit_art.dart';
import 'package:pirate_busters/ui/kit/pb_button.dart';
import 'package:pirate_busters/ui/meta_icons.dart';

/// 전투 HUD 전체 (설계서 §13.4). 판정은 하지 않고 [BattleSession] 을 그리기만 한다.
class BattleHud extends StatelessWidget {
  const BattleHud({
    required this.session,
    required this.overview,
    required this.paused,
    required this.onPause,
    required this.onRestart,
    this.hint,
    this.settled = true,
    this.onClick,
    super.key,
  });

  /// 버튼 누름 소리 (설계서 §10.3). 화면이 효과음 설정을 따라 낸다.
  final VoidCallback? onClick;

  /// 판이 끝난 뒤 연출(격침)이 끝났다. 끝나야 결과 창을 띄운다 (설계서 §10.4).
  final bool settled;

  final BattleSession session;

  /// 튜토리얼 안내 한 줄 (설계서 §13.1). 없으면 안 보인다.
  final String? hint;

  /// ‘전체 보기’ 켜짐. 전장(카메라)이 읽는다.
  final ValueNotifier<bool> overview;
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

  /// 조준·탄 비행·착탄 연출 중이다. 위쪽 정보를 흐려 배와 착탄 지점을 가리지
  /// 않는다 (설계서 §13.4 연출 중 HUD).
  bool get _busy => session.aim != null || session.playback != null;

  /// 연출 중 위쪽 정보의 진하기.
  static const double busyOpacity = 0.25;

  bool get _awaitingTap {
    final p = session.playback;
    return p is ShotPlayback &&
        p.awaitingTap &&
        session.humanSides.contains(p.side);
  }

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
              if (hint != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: HudPanel(
                    borderColor: HudColors.warn,
                    child: Text(hint!, style: const TextStyle(fontSize: 13)),
                  ),
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AnimatedOpacity(
                      key: const ValueKey('hud-top'),
                      opacity: _busy ? busyOpacity : 1,
                      duration: const Duration(milliseconds: 220),
                      child: Column(
                        children: [
                          TopBar(session: session),
                          const SizedBox(height: 4),
                          GapBar(state: session.state, overview: overview),
                          const SizedBox(height: 4),
                          TimeVerdictBar(session: session),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // 일시정지는 AI 전만(§13.4). 핫시트에서는 설정 창만 연다.
                  PbIconButton(
                    tooltip: _hotseat ? l10n.settings : l10n.pause,
                    icon: _hotseat ? PortIcons.gear : MetaIcons.pause,
                    onPressed: () {
                      onClick?.call();
                      onPause(true);
                    },
                  ),
                ],
              ),
              const Spacer(),
              Opacity(
                opacity: myTurn ? 1 : 0.5,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    MoveControls(
                      session: session,
                      side: _controlSide,
                      onClick: onClick,
                    ),
                    const Spacer(),
                    PirateCards(session: session, side: _controlSide),
                    const Spacer(),
                    PbButton(
                      label: l10n.endTurn,
                      icon: MetaIcons.endTurn,
                      kind: PbButtonKind.gold,
                      height: 50,
                      minWidth: 110,
                      fontSize: 17,
                      onPressed: session.canAct
                          ? () {
                              onClick?.call();
                              session.endTurn();
                            }
                          : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      if (myTurn && !session.isOver && session.remainingMs <= 5000)
        // 5초부터 카운트다운 (설계서 §2.3). 배 위가 아니라 턴 타이머 아래 (§13.4).
        Align(
          alignment: const Alignment(0, -0.62),
          child: IgnorePointer(
            child: OutlinedText(
              '${(session.remainingMs + 999) ~/ 1000}',
              key: const ValueKey('countdown'),
              size: 56,
              color: HudColors.danger,
              font: AppFonts.display,
              stroke: 6,
            ),
          ),
        ),
      if (_awaitingTap)
        // 분열탄이 날고 있다: 화면 어디든 탭하면 갈라진다 (설계서 §2.2, §4.8).
        Align(
          alignment: const Alignment(0, -0.45),
          child: IgnorePointer(
            child: HudPanel(
              borderColor: HudColors.warn,
              child: Text(
                l10n.tapToSplit,
                style: const TextStyle(fontSize: 22, color: HudColors.warn),
              ),
            ),
          ),
        ),
      if (session.aim?.cancelling ?? false)
        // 당겼다가 되돌렸다: 놓으면 쏘지 않고, 다른 해적을 고를 수 있다.
        Align(
          alignment: const Alignment(0, -0.45),
          child: IgnorePointer(
            child: HudPanel(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MetaIcons.image(MetaIcons.cancel, size: 26),
                  const SizedBox(width: 6),
                  Text(l10n.aimCancel, style: const TextStyle(fontSize: 22)),
                ],
              ),
            ),
          ),
        ),
      if (session.surrenderQueued && !session.isOver)
        Align(
          alignment: const Alignment(0, 0.35),
          child: HudPanel(child: Text(l10n.surrenderQueued)),
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
      if (session.isOver && session.playback == null && settled)
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
