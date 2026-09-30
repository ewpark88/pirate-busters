import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pirate_busters/settings/language.dart';
import 'package:pirate_busters/settings/settings_store.dart';

/// 부트스트랩에서 덮어쓴다.
final settingsStoreProvider = Provider<SettingsStore>(
  (ref) => throw UnimplementedError('settingsStoreProvider 를 덮어써야 한다'),
);

/// 언어 선택. 바꾸면 저장하고 앱이 재시작 없이 바로 다시 그려진다 (설계서 §14.1).
final languageProvider = NotifierProvider<LanguageNotifier, LanguageChoice>(
  LanguageNotifier.new,
);

class LanguageNotifier extends Notifier<LanguageChoice> {
  @override
  LanguageChoice build() => ref.read(settingsStoreProvider).language;

  Future<void> choose(LanguageChoice choice) async {
    state = choice;
    await ref.read(settingsStoreProvider).setLanguage(choice);
  }
}
