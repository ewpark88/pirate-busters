import 'package:hive_ce/hive.dart';
import 'package:pirate_busters/settings/language.dart';

/// 로컬 설정 저장소 (ADR-005, ADR-029). M7 에서 진행·설계도 저장이 같은 방식으로 붙는다.
abstract interface class SettingsStore {
  LanguageChoice get language;

  Future<void> setLanguage(LanguageChoice choice);

  /// 저사양 모드: 셰이더 효과를 끈다 (설계서 §10.2, §13.8).
  bool get lowEnd;

  Future<void> setLowEnd({required bool on});

  /// 2발을 다 쏘면 유예 뒤 턴을 자동으로 끝낸다 (설계서 §2.2). 기본 켬.
  bool get autoEndTurn;

  Future<void> setAutoEndTurn({required bool on});
}

/// Hive CE 상자 하나(`settings`)에 둔다.
class HiveSettingsStore implements SettingsStore {
  HiveSettingsStore._(this._box);

  static const String boxName = 'settings';
  static const String _languageKey = 'language';
  static const String _lowEndKey = 'lowEnd';
  static const String _autoEndKey = 'autoEndTurn';

  final Box<String> _box;

  /// 상자를 연다. `Hive.initFlutter` 뒤에 부른다.
  static Future<HiveSettingsStore> open() async =>
      HiveSettingsStore._(await Hive.openBox<String>(boxName));

  @override
  LanguageChoice get language => LanguageChoice.parse(_box.get(_languageKey));

  @override
  Future<void> setLanguage(LanguageChoice choice) =>
      _box.put(_languageKey, choice.name);

  @override
  bool get lowEnd => _box.get(_lowEndKey) == 'on';

  @override
  Future<void> setLowEnd({required bool on}) =>
      _box.put(_lowEndKey, on ? 'on' : 'off');

  @override
  bool get autoEndTurn => _box.get(_autoEndKey) != 'off';

  @override
  Future<void> setAutoEndTurn({required bool on}) =>
      _box.put(_autoEndKey, on ? 'on' : 'off');
}

/// 메모리에만 두는 저장소. 테스트용.
class MemorySettingsStore implements SettingsStore {
  MemorySettingsStore([this.language = LanguageChoice.system]);

  @override
  LanguageChoice language;

  @override
  bool lowEnd = false;

  @override
  Future<void> setLanguage(LanguageChoice choice) async => language = choice;

  @override
  Future<void> setLowEnd({required bool on}) async => lowEnd = on;

  @override
  bool autoEndTurn = true;

  @override
  Future<void> setAutoEndTurn({required bool on}) async => autoEndTurn = on;
}
