import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:pirate_busters/settings/language.dart';
import 'package:pirate_busters/settings/settings_store.dart';

void main() {
  group('언어 (설계서 §14.1)', () {
    test('시스템 설정을 따르면 기기가 한국어일 때만 한국어, 그 밖은 영어', () {
      expect(
        resolveLocale(LanguageChoice.system, const Locale('ko', 'KR')),
        const Locale('ko'),
      );
      expect(
        resolveLocale(LanguageChoice.system, const Locale('ja')),
        const Locale('en'),
      );
    });

    test('직접 고르면 기기 언어와 상관없이 그 언어', () {
      expect(
        resolveLocale(LanguageChoice.en, const Locale('ko')),
        const Locale('en'),
      );
      expect(
        resolveLocale(LanguageChoice.ko, const Locale('fr')),
        const Locale('ko'),
      );
    });

    test('저장된 값이 없거나 모르는 값이면 시스템 설정', () {
      expect(LanguageChoice.parse(null), LanguageChoice.system);
      expect(LanguageChoice.parse('de'), LanguageChoice.system);
      expect(LanguageChoice.parse('ko'), LanguageChoice.ko);
    });

    test('고른 언어는 저장소에 남는다', () async {
      final store = MemorySettingsStore();
      await store.setLanguage(LanguageChoice.en);
      expect(store.language, LanguageChoice.en);
    });
  });
}
