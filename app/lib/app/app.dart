import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pirate_busters/app/providers.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';
import 'package:pirate_busters/port/port_screen.dart';
import 'package:pirate_busters/settings/language.dart';

/// 앱 루트. 항구(설계서 §13.2)에서 조선소·선원·출항으로 간다. 프롤로그·튜토리얼 분기는 M7 뒤 묶음.
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
      home: const PortScreen(),
    );
  }
}
