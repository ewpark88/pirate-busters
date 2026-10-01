import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pirate_busters/app/providers.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';
import 'package:pirate_busters/settings/language.dart';

/// 설정 화면 (설계서 §13.8, §14.1): 언어·효과음·진동·저사양 모드·자동 턴 종료.
/// 전투 중에는 열 수 없고 항구 위쪽 아이콘에서 연다(§13.2).
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final language = ref.watch(languageProvider);
    final iap = ref.watch(iapProvider);
    return Scaffold(
      appBar: AppBar(toolbarHeight: 40, title: Text(l10n.settings)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          children: [
            ListTile(
              title: Text(l10n.language),
              trailing: SegmentedButton<LanguageChoice>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                    value: LanguageChoice.system,
                    label: Text(l10n.languageSystem),
                  ),
                  ButtonSegment(
                    value: LanguageChoice.ko,
                    label: Text(l10n.languageKorean),
                  ),
                  ButtonSegment(
                    value: LanguageChoice.en,
                    label: Text(l10n.languageEnglish),
                  ),
                ],
                selected: {language},
                onSelectionChanged: (s) =>
                    ref.read(languageProvider.notifier).choose(s.first),
              ),
            ),
            SwitchListTile(
              title: Text(l10n.soundOn),
              value: ref.watch(soundOnProvider),
              onChanged: (on) => ref.read(soundOnProvider.notifier).set(on: on),
            ),
            SwitchListTile(
              title: Text(l10n.vibrationOn),
              value: ref.watch(vibrationOnProvider),
              onChanged: (on) =>
                  ref.read(vibrationOnProvider.notifier).set(on: on),
            ),
            SwitchListTile(
              title: Text(l10n.lowEndMode),
              value: ref.watch(lowEndProvider),
              onChanged: (on) => ref.read(lowEndProvider.notifier).set(on: on),
            ),
            SwitchListTile(
              title: Text(l10n.autoEndTurn),
              value: ref.watch(autoEndTurnProvider),
              onChanged: (on) =>
                  ref.read(autoEndTurnProvider.notifier).set(on: on),
            ),
            // 광고 제거 (설계서 §9). 스토어 연결 전에는 안 보인다.
            if (iap.available)
              ListTile(
                title: Text(l10n.iapRemoveAds),
                trailing: ref.watch(adsRemovedProvider)
                    ? Text(l10n.iapBought)
                    : FilledButton(
                        onPressed: () =>
                            ref.read(adsRemovedProvider.notifier).buy(),
                        child: Text(l10n.iapBuy),
                      ),
              ),
          ],
        ),
      ),
    );
  }
}
