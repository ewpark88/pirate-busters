import 'dart:ui';

/// 언어 선택 (설계서 §14.1). 기본은 시스템 설정을 따른다.
enum LanguageChoice {
  /// 시스템 언어가 한국어면 한국어, 그 밖은 영어.
  system,
  ko,
  en;

  /// 저장 값으로 찾는다. 모르는 값이면 [system].
  static LanguageChoice parse(String? name) {
    for (final c in values) {
      if (c.name == name) return c;
    }
    return system;
  }
}

/// 앱이 지원하는 언어. 영어가 기준이다 (설계서 §14.2).
const List<Locale> supportedLocales = [Locale('en'), Locale('ko')];

/// [choice] 와 기기 언어 [device] 로 쓸 언어를 정한다.
Locale resolveLocale(LanguageChoice choice, Locale device) => switch (choice) {
  LanguageChoice.ko => const Locale('ko'),
  LanguageChoice.en => const Locale('en'),
  LanguageChoice.system =>
    device.languageCode == 'ko' ? const Locale('ko') : const Locale('en'),
};
