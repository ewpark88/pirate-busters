import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pirate_busters/app/app_theme.dart';
import 'package:pirate_busters/app/providers.dart';
import 'package:pirate_busters/audio/music_director.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';
import 'package:pirate_busters/settings/language.dart';
import 'package:pirate_busters/ui/kit/kit_motion.dart';
import 'package:pirate_busters/ui/kit/pb_button.dart';
import 'package:pirate_busters/ui/kit/pb_panel.dart';
import 'package:pirate_busters/ui/kit/pb_scaffold.dart';
import 'package:pirate_busters/ui/meta_icons.dart';

/// 설정 화면 (설계서 §13.8, §14.1, §13 공통): 언어·효과음·진동·저사양 모드·자동 턴 종료.
/// 전투 중에는 열 수 없고 항구 위쪽 아이콘에서 연다(§13.2).
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final language = ref.watch(languageProvider);
    final iap = ref.watch(iapProvider);
    const choices = LanguageChoice.values;
    Widget toggle(
      String icon,
      String label, {
      required bool value,
      required ValueChanged<bool> set,
    }) => GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => set(!value),
      child: _Row(
        icon: icon,
        label: label,
        trailing: PbToggle(value: value, label: label, onChanged: set),
      ),
    );
    return PbScaffold(
      title: l10n.settings,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: PopIn(
              child: PbPanel(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _Row(
                      icon: MetaIcons.language,
                      label: l10n.language,
                      trailing: PbTabs(
                        labels: [
                          for (final c in choices)
                            switch (c) {
                              LanguageChoice.system => l10n.languageSystem,
                              LanguageChoice.ko => l10n.languageKorean,
                              LanguageChoice.en => l10n.languageEnglish,
                            },
                        ],
                        selected: choices.indexOf(language),
                        onSelect: (i) => ref
                            .read(languageProvider.notifier)
                            .choose(choices[i]),
                      ),
                    ),
                    toggle(
                      MetaIcons.sound,
                      l10n.soundOn,
                      value: ref.watch(soundOnProvider),
                      set: (on) =>
                          ref.read(soundOnProvider.notifier).set(on: on),
                    ),
                    toggle(
                      MetaIcons.sound,
                      l10n.musicOn,
                      value: ref.watch(musicOnProvider),
                      set: (on) =>
                          ref.read(musicOnProvider.notifier).set(on: on),
                    ),
                    toggle(
                      MetaIcons.vibrate,
                      l10n.vibrationOn,
                      value: ref.watch(vibrationOnProvider),
                      set: (on) =>
                          ref.read(vibrationOnProvider.notifier).set(on: on),
                    ),
                    toggle(
                      MetaIcons.lowSpec,
                      l10n.lowEndMode,
                      value: ref.watch(lowEndProvider),
                      set: (on) =>
                          ref.read(lowEndProvider.notifier).set(on: on),
                    ),
                    toggle(
                      MetaIcons.endTurn,
                      l10n.autoEndTurn,
                      value: ref.watch(autoEndTurnProvider),
                      set: (on) =>
                          ref.read(autoEndTurnProvider.notifier).set(on: on),
                    ),
                    // 광고 제거 (설계서 §9). 스토어 연결 전에는 안 보인다.
                    if (iap.available)
                      _Row(
                        label: l10n.iapRemoveAds,
                        trailing: ref.watch(adsRemovedProvider)
                            ? Text(l10n.iapBought)
                            : PbButton.small(
                                label: l10n.iapBuy,
                                kind: PbButtonKind.gold,
                                onPressed: () =>
                                    ref.read(adsRemovedProvider.notifier).buy(),
                              ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 설정 한 줄: 아이콘·이름·오른쪽 조작.
class _Row extends StatelessWidget {
  const _Row({required this.label, required this.trailing, this.icon});

  final String? icon;
  final String label;
  final Widget trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      children: [
        if (icon != null) ...[
          MetaIcons.image(icon!, size: 28),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 16, color: AppColors.text),
          ),
        ),
        trailing,
      ],
    ),
  );
}
