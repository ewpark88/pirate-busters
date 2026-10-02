import 'package:flutter/material.dart';
import 'package:pirate_busters/ui/kit/kit_motion.dart';

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

/// 화면 톤 (에셋 `tokens.json` `palette.hud`, 화면 시안 stage33~35): 어두운 판
/// 바탕, 금 테두리, 밝은 양피지 글자. 선택은 우리 팀 파랑, 켜진 스위치는 초록.
abstract final class AppColors {
  static const Color background = Color(0xFF101217);
  static const Color panel = Color(0xFF15171D);
  static const Color panelHi = Color(0xFF262A33);
  static const Color gold = Color(0xFFC9962E);
  static const Color text = Color(0xFFEFE6D2);
  static const Color mute = Color(0xFF9A917F);
  static const Color blue = Color(0xFF2F62C4);
  static const Color green = Color(0xFF3C8A3C);
  static const Color knob = Color(0xFFF1DFA8);
  static const Color danger = Color(0xFFE06A5A);
}

/// 앱 테마: 어두운 화면 톤([AppColors]). 본문은 [AppFonts.body], 제목은
/// [AppFonts.display], 버튼 글자는 [AppFonts.round].
ThemeData appTheme() {
  const scheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.gold,
    onPrimary: AppColors.panel,
    primaryContainer: Color(0xFF3A2F18),
    onPrimaryContainer: AppColors.text,
    secondary: AppColors.blue,
    onSecondary: Colors.white,
    secondaryContainer: AppColors.blue,
    onSecondaryContainer: Colors.white,
    tertiary: AppColors.green,
    onTertiary: Colors.white,
    error: AppColors.danger,
    onError: AppColors.panel,
    surface: AppColors.panel,
    onSurface: AppColors.text,
    onSurfaceVariant: AppColors.mute,
    surfaceContainerLowest: AppColors.background,
    surfaceContainerLow: AppColors.panel,
    surfaceContainer: AppColors.panel,
    surfaceContainerHigh: AppColors.panelHi,
    surfaceContainerHighest: AppColors.panelHi,
    outline: AppColors.gold,
    outlineVariant: Color(0xFF3A3F4A),
  );
  final base = ThemeData(
    fontFamily: AppFonts.body,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.panel,
      foregroundColor: AppColors.text,
      shape: Border(bottom: BorderSide(color: AppColors.gold)),
    ),
    dividerColor: const Color(0xFF3A3F4A),
    // 화면 전환은 짧게 밀며 나타난다 (설계서 §13 공통 화면 규칙).
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: KitPageTransitions(),
        TargetPlatform.iOS: KitPageTransitions(),
        TargetPlatform.windows: KitPageTransitions(),
        TargetPlatform.macOS: KitPageTransitions(),
        TargetPlatform.linux: KitPageTransitions(),
      },
    ),
    switchTheme: SwitchThemeData(
      thumbColor: const WidgetStatePropertyAll(AppColors.knob),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? AppColors.green
            : AppColors.panelHi,
      ),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
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
