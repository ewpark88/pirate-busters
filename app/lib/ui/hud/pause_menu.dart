import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pirate_busters/app/providers.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';
import 'package:pirate_busters/ui/hud/hud_style.dart';

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
      child: HudPanel(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.pause, style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                children: [
                  FilterChip(
                    label: Text(l10n.lowEndMode),
                    selected: ref.watch(lowEndProvider),
                    onSelected: (on) =>
                        ref.read(lowEndProvider.notifier).set(on: on),
                  ),
                  FilterChip(
                    label: Text(l10n.autoEndTurn),
                    selected: ref.watch(autoEndTurnProvider),
                    onSelected: (on) =>
                        ref.read(autoEndTurnProvider.notifier).set(on: on),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                l10n.opponent,
                style: const TextStyle(color: HudColors.mute),
              ),
              Wrap(
                spacing: 6,
                children: [
                  ChoiceChip(
                    label: Text(l10n.opponentAi),
                    selected: !hotseat,
                    onSelected: (_) => onOpponent(false),
                  ),
                  ChoiceChip(
                    label: Text(l10n.opponentHotseat),
                    selected: hotseat,
                    onSelected: (_) => onOpponent(true),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  TextButton(
                    onPressed: () => _confirmSurrender(context),
                    child: Text(
                      l10n.surrender,
                      style: const TextStyle(color: HudColors.danger),
                    ),
                  ),
                  const Spacer(),
                  FilledButton(onPressed: onResume, child: Text(l10n.resume)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmSurrender(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(l10n.surrenderConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.surrender),
          ),
        ],
      ),
    );
    if (ok ?? false) onSurrender();
  }
}
