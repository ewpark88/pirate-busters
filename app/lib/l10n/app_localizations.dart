import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ko'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Pirate Busters'**
  String get appTitle;

  /// No description provided for @turnsLeft.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 turn left} other{{count} turns left}}'**
  String turnsLeft(int count);

  /// No description provided for @yourTurn.
  ///
  /// In en, this message translates to:
  /// **'Your turn'**
  String get yourTurn;

  /// No description provided for @enemyTurn.
  ///
  /// In en, this message translates to:
  /// **'Enemy turn'**
  String get enemyTurn;

  /// No description provided for @playerTurn.
  ///
  /// In en, this message translates to:
  /// **'Player {side} turn'**
  String playerTurn(int side);

  /// No description provided for @hull.
  ///
  /// In en, this message translates to:
  /// **'Hull'**
  String get hull;

  /// No description provided for @flood.
  ///
  /// In en, this message translates to:
  /// **'Flood {percent}%'**
  String flood(String percent);

  /// No description provided for @crewAlive.
  ///
  /// In en, this message translates to:
  /// **'Crew {alive}/{total}'**
  String crewAlive(int alive, int total);

  /// No description provided for @endTurn.
  ///
  /// In en, this message translates to:
  /// **'End turn'**
  String get endTurn;

  /// No description provided for @retreat.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get retreat;

  /// No description provided for @advance.
  ///
  /// In en, this message translates to:
  /// **'Ahead'**
  String get advance;

  /// No description provided for @fuel.
  ///
  /// In en, this message translates to:
  /// **'Fuel'**
  String get fuel;

  /// No description provided for @firesLeft.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 shot left} other{{count} shots left}}'**
  String firesLeft(int count);

  /// No description provided for @cooldown.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Rest 1 turn} other{Rest {count} turns}}'**
  String cooldown(int count);

  /// No description provided for @cabinFlooded.
  ///
  /// In en, this message translates to:
  /// **'Flooded'**
  String get cabinFlooded;

  /// No description provided for @pirateDown.
  ///
  /// In en, this message translates to:
  /// **'Down'**
  String get pirateDown;

  /// No description provided for @pirateSwimming.
  ///
  /// In en, this message translates to:
  /// **'Swimming'**
  String get pirateSwimming;

  /// No description provided for @wind.
  ///
  /// In en, this message translates to:
  /// **'Wind'**
  String get wind;

  /// No description provided for @stormTime.
  ///
  /// In en, this message translates to:
  /// **'Storm!'**
  String get stormTime;

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// No description provided for @gapCells.
  ///
  /// In en, this message translates to:
  /// **'Gap {cells}'**
  String gapCells(int cells);

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @surrender.
  ///
  /// In en, this message translates to:
  /// **'Surrender'**
  String get surrender;

  /// No description provided for @surrenderConfirm.
  ///
  /// In en, this message translates to:
  /// **'Give up this battle?'**
  String get surrenderConfirm;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// No description provided for @languageKorean.
  ///
  /// In en, this message translates to:
  /// **'한국어'**
  String get languageKorean;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @opponent.
  ///
  /// In en, this message translates to:
  /// **'Opponent'**
  String get opponent;

  /// No description provided for @opponentDummy.
  ///
  /// In en, this message translates to:
  /// **'Training dummy'**
  String get opponentDummy;

  /// No description provided for @opponentHotseat.
  ///
  /// In en, this message translates to:
  /// **'Two players (one device)'**
  String get opponentHotseat;

  /// No description provided for @resultWin.
  ///
  /// In en, this message translates to:
  /// **'Victory!'**
  String get resultWin;

  /// No description provided for @resultLose.
  ///
  /// In en, this message translates to:
  /// **'Defeat'**
  String get resultLose;

  /// No description provided for @resultDraw.
  ///
  /// In en, this message translates to:
  /// **'Draw'**
  String get resultDraw;

  /// No description provided for @outcomeSunk.
  ///
  /// In en, this message translates to:
  /// **'Ship wrecked'**
  String get outcomeSunk;

  /// No description provided for @outcomeFloodSunk.
  ///
  /// In en, this message translates to:
  /// **'Sunk by flooding'**
  String get outcomeFloodSunk;

  /// No description provided for @outcomeAnnihilation.
  ///
  /// In en, this message translates to:
  /// **'Crew wiped out'**
  String get outcomeAnnihilation;

  /// No description provided for @outcomeTimeDecision.
  ///
  /// In en, this message translates to:
  /// **'Time decision'**
  String get outcomeTimeDecision;

  /// No description provided for @outcomeSurrender.
  ///
  /// In en, this message translates to:
  /// **'Surrender'**
  String get outcomeSurrender;

  /// No description provided for @playAgain.
  ///
  /// In en, this message translates to:
  /// **'Play again'**
  String get playAgain;

  /// No description provided for @playerWins.
  ///
  /// In en, this message translates to:
  /// **'Player {side} wins!'**
  String playerWins(int side);

  /// No description provided for @lowEndMode.
  ///
  /// In en, this message translates to:
  /// **'Low-end mode'**
  String get lowEndMode;

  /// No description provided for @damagePopup.
  ///
  /// In en, this message translates to:
  /// **'-{amount}'**
  String damagePopup(String amount);

  /// No description provided for @sunkBanner.
  ///
  /// In en, this message translates to:
  /// **'Sunk!'**
  String get sunkBanner;

  /// No description provided for @surrenderQueued.
  ///
  /// In en, this message translates to:
  /// **'You will surrender at the start of your turn'**
  String get surrenderQueued;

  /// No description provided for @pirate_p01_name.
  ///
  /// In en, this message translates to:
  /// **'Octo the Bomber'**
  String get pirate_p01_name;

  /// No description provided for @pirate_p01_desc.
  ///
  /// In en, this message translates to:
  /// **'Lobbed bomb that bursts in a 1-cell radius'**
  String get pirate_p01_desc;

  /// No description provided for @pirate_p01_lore.
  ///
  /// In en, this message translates to:
  /// **'Raised in Coral Harbor, Octo juggles bombs with all eight arms.'**
  String get pirate_p01_lore;

  /// No description provided for @pirate_p04_name.
  ///
  /// In en, this message translates to:
  /// **'Uni the Urchin'**
  String get pirate_p04_name;

  /// No description provided for @pirate_p04_desc.
  ///
  /// In en, this message translates to:
  /// **'Tap in flight to split into 4 spikes'**
  String get pirate_p04_desc;

  /// No description provided for @pirate_p04_lore.
  ///
  /// In en, this message translates to:
  /// **'As prickly as her spines. She picks the moment to burst.'**
  String get pirate_p04_lore;

  /// No description provided for @pirate_p06_name.
  ///
  /// In en, this message translates to:
  /// **'Pang the Pistol Shrimp'**
  String get pirate_p06_name;

  /// No description provided for @pirate_p06_desc.
  ///
  /// In en, this message translates to:
  /// **'Claw-snap water bullet, critical on pirates'**
  String get pirate_p06_desc;

  /// No description provided for @pirate_p06_lore.
  ///
  /// In en, this message translates to:
  /// **'One snap of his claw fires a bubble bullet.'**
  String get pirate_p06_lore;

  /// No description provided for @pirate_p07_name.
  ///
  /// In en, this message translates to:
  /// **'Hippo the Gunslinger'**
  String get pirate_p07_name;

  /// No description provided for @pirate_p07_desc.
  ///
  /// In en, this message translates to:
  /// **'Short-range triple shot'**
  String get pirate_p07_desc;

  /// No description provided for @pirate_p07_lore.
  ///
  /// In en, this message translates to:
  /// **'Anchors with his tail and fires two pistols at once.'**
  String get pirate_p07_lore;

  /// No description provided for @pirate_p11_name.
  ///
  /// In en, this message translates to:
  /// **'Finn the Harpooner'**
  String get pirate_p11_name;

  /// No description provided for @pirate_p11_desc.
  ///
  /// In en, this message translates to:
  /// **'Harpoon charge that pierces 2 blocks'**
  String get pirate_p11_desc;

  /// No description provided for @pirate_p11_lore.
  ///
  /// In en, this message translates to:
  /// **'His long nose is the harpoon. Hiding behind walls won\'t help.'**
  String get pirate_p11_lore;

  /// No description provided for @pirate_p16_name.
  ///
  /// In en, this message translates to:
  /// **'Suri the Slinger'**
  String get pirate_p16_name;

  /// No description provided for @pirate_p16_desc.
  ///
  /// In en, this message translates to:
  /// **'Stone skips twice and hits the waterline'**
  String get pirate_p16_desc;

  /// No description provided for @pirate_p16_lore.
  ///
  /// In en, this message translates to:
  /// **'Skips stones with the same knack she uses to crack clams.'**
  String get pirate_p16_lore;

  /// No description provided for @pirate_p21_name.
  ///
  /// In en, this message translates to:
  /// **'Puffy the Blaster'**
  String get pirate_p21_name;

  /// No description provided for @pirate_p21_desc.
  ///
  /// In en, this message translates to:
  /// **'Clings below the waterline, bursts next turn'**
  String get pirate_p21_desc;

  /// No description provided for @pirate_p21_lore.
  ///
  /// In en, this message translates to:
  /// **'Puffs up, sticks under the hull, and then... boom.'**
  String get pirate_p21_lore;

  /// No description provided for @pirate_p26_name.
  ///
  /// In en, this message translates to:
  /// **'Polly the Parrot'**
  String get pirate_p26_name;

  /// No description provided for @pirate_p26_desc.
  ///
  /// In en, this message translates to:
  /// **'Homes in on the nearest pirate and pecks'**
  String get pirate_p26_desc;

  /// No description provided for @pirate_p26_lore.
  ///
  /// In en, this message translates to:
  /// **'Leaves the captain\'s shoulder to chase enemy crew.'**
  String get pirate_p26_lore;

  /// No description provided for @pirate_p27_name.
  ///
  /// In en, this message translates to:
  /// **'Wing the Bombardier'**
  String get pirate_p27_name;

  /// No description provided for @pirate_p27_desc.
  ///
  /// In en, this message translates to:
  /// **'Dives and drops 3 small bombs'**
  String get pirate_p27_desc;

  /// No description provided for @pirate_p27_lore.
  ///
  /// In en, this message translates to:
  /// **'Circles the sea, then dives in a flash.'**
  String get pirate_p27_lore;

  /// No description provided for @pirate_p28_name.
  ///
  /// In en, this message translates to:
  /// **'Pelly the Pelican'**
  String get pirate_p28_name;

  /// No description provided for @pirate_p28_desc.
  ///
  /// In en, this message translates to:
  /// **'Drops 4 small bombs from her pouch next turn'**
  String get pirate_p28_desc;

  /// No description provided for @pirate_p28_lore.
  ///
  /// In en, this message translates to:
  /// **'Nobody knows what\'s in her pouch until it drops.'**
  String get pirate_p28_lore;

  /// No description provided for @pirate_p31_name.
  ///
  /// In en, this message translates to:
  /// **'Sharky the Brawler'**
  String get pirate_p31_name;

  /// No description provided for @pirate_p31_desc.
  ///
  /// In en, this message translates to:
  /// **'Leaps onto the deck and bites pirates within 1 cell'**
  String get pirate_p31_desc;

  /// No description provided for @pirate_p31_lore.
  ///
  /// In en, this message translates to:
  /// **'Nothing makes him happier than jumping aboard.'**
  String get pirate_p31_lore;

  /// No description provided for @pirate_p36_name.
  ///
  /// In en, this message translates to:
  /// **'Tok the Shipwright'**
  String get pirate_p36_name;

  /// No description provided for @pirate_p36_desc.
  ///
  /// In en, this message translates to:
  /// **'Fire at your ship to patch 3 holed blocks'**
  String get pirate_p36_desc;

  /// No description provided for @pirate_p36_lore.
  ///
  /// In en, this message translates to:
  /// **'Slow but careful. He keeps the ship afloat.'**
  String get pirate_p36_lore;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
