import 'package:hive_ce/hive.dart';
import 'package:pirate_busters/settings/language.dart';

/// 로컬 설정 저장소 (ADR-005, ADR-029). M7 에서 진행·설계도 저장이 같은 방식으로 붙는다.
abstract interface class SettingsStore {
  LanguageChoice get language;

  Future<void> setLanguage(LanguageChoice choice);
}

/// Hive CE 상자 하나(`settings`)에 둔다.
class HiveSettingsStore implements SettingsStore {
  HiveSettingsStore._(this._box);

  static const String boxName = 'settings';
  static const String _languageKey = 'language';

  final Box<String> _box;

  /// 상자를 연다. `Hive.initFlutter` 뒤에 부른다.
  static Future<HiveSettingsStore> open() async =>
      HiveSettingsStore._(await Hive.openBox<String>(boxName));

  @override
  LanguageChoice get language => LanguageChoice.parse(_box.get(_languageKey));

  @override
  Future<void> setLanguage(LanguageChoice choice) =>
      _box.put(_languageKey, choice.name);
}

/// 메모리에만 두는 저장소. 테스트용.
class MemorySettingsStore implements SettingsStore {
  MemorySettingsStore([this.language = LanguageChoice.system]);

  @override
  LanguageChoice language;

  @override
  Future<void> setLanguage(LanguageChoice choice) async => language = choice;
}
