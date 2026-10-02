import 'package:flutter/material.dart';

/// 글꼴 역할 (설계서 §14.4). 셋 다 한글·라틴을 함께 가진 OFL 글꼴이다
/// (라이선스: `assets/fonts/OFL*.txt`).
abstract final class AppFonts {
  /// 제목·숫자: Black Han Sans.
  static const String display = 'BlackHanSans';

  /// 본문: IBM Plex Sans KR.
  static const String body = 'IBMPlexSansKR';

  /// 둥근 강조(버튼·배지): Jua.
  static const String round = 'Jua';
}

/// 앱 테마: 본문은 [AppFonts.body], 제목은 [AppFonts.display], 버튼 글자는
/// [AppFonts.round].
ThemeData appTheme() {
  final base = ThemeData(
    fontFamily: AppFonts.body,
    colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E6FB8)),
  );
  TextStyle? display(TextStyle? s) => s?.copyWith(fontFamily: AppFonts.display);
  final t = base.textTheme;
  return base.copyWith(
    textTheme: t.copyWith(
      displayLarge: display(t.displayLarge),
      displayMedium: display(t.displayMedium),
      displaySmall: display(t.displaySmall),
      headlineLarge: display(t.headlineLarge),
      headlineMedium: display(t.headlineMedium),
      headlineSmall: display(t.headlineSmall),
      titleLarge: display(t.titleLarge),
      labelLarge: t.labelLarge?.copyWith(fontFamily: AppFonts.round),
    ),
  );
}
