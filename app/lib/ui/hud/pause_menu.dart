import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pirate_busters/app/providers.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';
import 'package:pirate_busters/settings/language.dart';
import 'package:pirate_busters/ui/hud/hud_style.dart';

/// 일시정지 창: 언어, 상대(허수아비·두 사람), 항복 (설계서 §13.4, §14.1).
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
    final choice = ref.watch(languageProvider);
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
              Text(
                l10n.language,
                style: const TextStyle(color: HudColors.mute),
              ),
              Wrap(
                spacing: 6,
                children: [
                  for (final c in LanguageChoice.values)
                    ChoiceChip(
                      label: Text(switch (c) {
                        LanguageChoice.system => l10n.languageSystem,
                        LanguageChoice.ko => l10n.languageKorean,
                        LanguageChoice.en => l10n.languageEnglish,
                      }),
                      selected: choice == c,
                      onSelected: (_) =>
                          ref.read(languageProvider.notifier).choose(c),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              FilterChip(
                label: Text(l10n.lowEndMode),
                selected: ref.watch(lowEndProvider),
                onSelected: (on) =>
                    ref.read(lowEndProvider.notifier).set(on: on),
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
                    label: Text(l10n.opponentDummy),
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
