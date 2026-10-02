import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pirate_busters/app/providers.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';
import 'package:pirate_busters/ui/hud/hud_style.dart';
import 'package:pirate_busters/ui/kit/kit_motion.dart';
import 'package:pirate_busters/ui/kit/pb_button.dart';
import 'package:pirate_busters/ui/kit/pb_dialog.dart';
import 'package:pirate_busters/ui/kit/pb_panel.dart';
import 'package:pirate_busters/ui/meta_icons.dart';

/// 일시정지 창: 저사양·자동 종료, 상대(AI·두 사람), 항복 (설계서 §13.4).
///
/// 언어는 전투 중에 바꾸지 않는다(설계서 §14.1). 설정 화면에서만 고른다.
class PauseMenu extends ConsumerWidget {
  const PauseMenu({
    required this.hotseat,
    required this.onResume,
    required this.onSurrender,
    required this.onOpponent,
    super.key,
  });

  final bool hotseat;
  final VoidCallback onResume;
  final VoidCallback onSurrender;

  /// 상대 방식을 바꾸면 새 판을 시작한다.
  final ValueChanged<bool> onOpponent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: PopIn(
        child: SizedBox(
          width: 380,
          child: PbPanel(
            title: l10n.pause,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _toggle(
                  l10n.lowEndMode,
                  value: ref.watch(lowEndProvider),
                  set: (on) => ref.read(lowEndProvider.notifier).set(on: on),
                ),
                _toggle(
                  l10n.autoEndTurn,
                  value: ref.watch(autoEndTurnProvider),
                  set: (on) =>
                      ref.read(autoEndTurnProvider.notifier).set(on: on),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.opponent,
                  style: const TextStyle(color: HudColors.mute),
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FittedBox(
                    child: PbTabs(
                      labels: [l10n.opponentAi, l10n.opponentHotseat],
                      selected: hotseat ? 1 : 0,
                      onSelect: (i) => onOpponent(i == 1),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    PbButton.small(
                      label: l10n.surrender,
                      icon: MetaIcons.surrender,
                      onPressed: () => _confirmSurrender(context),
                    ),
                    const Spacer(),
                    PbButton(
                      label: l10n.resume,
                      kind: PbButtonKind.gold,
                      height: 46,
                      onPressed: onResume,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 켜기·끄기 한 줄. 글자를 눌러도 바뀐다.
  Widget _toggle(
    String label, {
    required bool value,
    required ValueChanged<bool> set,
  }) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: () => set(!value),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: HudColors.text)),
          ),
          PbToggle(value: value, label: label, onChanged: set),
        ],
      ),
    ),
  );

  Future<void> _confirmSurrender(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showPbConfirm(
      context,
      message: l10n.surrenderConfirm,
      cancel: l10n.cancel,
      confirm: l10n.surrender,
    );
    if (ok) onSurrender();
  }
}
