import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pirate_busters/app/providers.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';
import 'package:pirate_busters/settings/language.dart';
import 'package:pirate_busters/ui/battle_screen.dart';

/// 앱 루트. M4 는 바로 전투 화면으로 간다(메뉴는 M7).
class PirateBustersApp extends ConsumerWidget {
  const PirateBustersApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final choice = ref.watch(languageProvider);
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      locale: choice == LanguageChoice.system
          ? null
          : resolveLocale(choice, const Locale('en')),
      localeResolutionCallback: (device, _) =>
          resolveLocale(choice, device ?? const Locale('en')),
      supportedLocales: supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        fontFamily: 'Jua',
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E6FB8)),
      ),
      home: const BattleScreen(),
    );
  }
}
