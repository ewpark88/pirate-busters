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

  /// No description provided for @navBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get navBack;

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

  /// No description provided for @emphasisBoom.
  ///
  /// In en, this message translates to:
  /// **'KABOOM!'**
  String get emphasisBoom;

  /// No description provided for @emphasisDoubleHit.
  ///
  /// In en, this message translates to:
  /// **'Double hit!'**
  String get emphasisDoubleHit;

  /// No description provided for @emphasisCabin.
  ///
  /// In en, this message translates to:
  /// **'Cabin hit!'**
  String get emphasisCabin;

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

  /// No description provided for @pirate_p02_name.
  ///
  /// In en, this message translates to:
  /// **'Starry the Firestar'**
  String get pirate_p02_name;

  /// No description provided for @pirate_p02_desc.
  ///
  /// In en, this message translates to:
  /// **'Spinning fire star that leaves a burning zone'**
  String get pirate_p02_desc;

  /// No description provided for @pirate_p02_lore.
  ///
  /// In en, this message translates to:
  /// **'Loves fireworks. Has burned three ships so far.'**
  String get pirate_p02_lore;

  /// No description provided for @pirate_p03_name.
  ///
  /// In en, this message translates to:
  /// **'Crab Brothers'**
  String get pirate_p03_name;

  /// No description provided for @pirate_p03_desc.
  ///
  /// In en, this message translates to:
  /// **'Two bombs on the same arc, one after the other'**
  String get pirate_p03_desc;

  /// No description provided for @pirate_p03_lore.
  ///
  /// In en, this message translates to:
  /// **'They argue nonstop, yet always aim at the same spot.'**
  String get pirate_p03_lore;

  /// No description provided for @pirate_p05_name.
  ///
  /// In en, this message translates to:
  /// **'Volke the Volcano Crab'**
  String get pirate_p05_name;

  /// No description provided for @pirate_p05_desc.
  ///
  /// In en, this message translates to:
  /// **'Steep lob that drills 3 layers, then a big blast'**
  String get pirate_p05_desc;

  /// No description provided for @pirate_p05_lore.
  ///
  /// In en, this message translates to:
  /// **'The volcano on his back has never cooled.'**
  String get pirate_p05_lore;

  /// No description provided for @pirate_p08_name.
  ///
  /// In en, this message translates to:
  /// **'Bones the Sniper'**
  String get pirate_p08_name;

  /// No description provided for @pirate_p08_desc.
  ///
  /// In en, this message translates to:
  /// **'Lightning-fast shot with a glowing-eye scope'**
  String get pirate_p08_desc;

  /// No description provided for @pirate_p08_lore.
  ///
  /// In en, this message translates to:
  /// **'When his eye sockets glow, it is already too late.'**
  String get pirate_p08_lore;

  /// No description provided for @pirate_p09_name.
  ///
  /// In en, this message translates to:
  /// **'Lion the Spinefish'**
  String get pirate_p09_name;

  /// No description provided for @pirate_p09_desc.
  ///
  /// In en, this message translates to:
  /// **'Fan of spines that shreds nets'**
  String get pirate_p09_desc;

  /// No description provided for @pirate_p09_lore.
  ///
  /// In en, this message translates to:
  /// **'Every fin is a venomous spine cannon.'**
  String get pirate_p09_lore;

  /// No description provided for @pirate_p10_name.
  ///
  /// In en, this message translates to:
  /// **'Volt the Eel'**
  String get pirate_p10_name;

  /// No description provided for @pirate_p10_desc.
  ///
  /// In en, this message translates to:
  /// **'Chain lightning that jumps between pirates'**
  String get pirate_p10_desc;

  /// No description provided for @pirate_p10_lore.
  ///
  /// In en, this message translates to:
  /// **'Gets even livelier in wet places.'**
  String get pirate_p10_lore;

  /// No description provided for @pirate_p12_name.
  ///
  /// In en, this message translates to:
  /// **'Nar the Narwhal'**
  String get pirate_p12_name;

  /// No description provided for @pirate_p12_desc.
  ///
  /// In en, this message translates to:
  /// **'Horn lance skewers up to 3 pirates in a row'**
  String get pirate_p12_desc;

  /// No description provided for @pirate_p12_lore.
  ///
  /// In en, this message translates to:
  /// **'A quiet lancer who came down from the northern seas.'**
  String get pirate_p12_lore;

  /// No description provided for @pirate_p13_name.
  ///
  /// In en, this message translates to:
  /// **'Walrus the Anchorman'**
  String get pirate_p13_name;

  /// No description provided for @pirate_p13_desc.
  ///
  /// In en, this message translates to:
  /// **'Heavy anchor that rips blocks out'**
  String get pirate_p13_desc;

  /// No description provided for @pirate_p13_lore.
  ///
  /// In en, this message translates to:
  /// **'Likes pulling the anchor back more than throwing it.'**
  String get pirate_p13_lore;

  /// No description provided for @pirate_p14_name.
  ///
  /// In en, this message translates to:
  /// **'Saw the Sawshark'**
  String get pirate_p14_name;

  /// No description provided for @pirate_p14_desc.
  ///
  /// In en, this message translates to:
  /// **'Saw nose cuts a whole column'**
  String get pirate_p14_desc;

  /// No description provided for @pirate_p14_lore.
  ///
  /// In en, this message translates to:
  /// **'Its nose itches whenever it sees a mast.'**
  String get pirate_p14_lore;

  /// No description provided for @pirate_p15_name.
  ///
  /// In en, this message translates to:
  /// **'Moby the Whale'**
  String get pirate_p15_name;

  /// No description provided for @pirate_p15_desc.
  ///
  /// In en, this message translates to:
  /// **'Drags the enemy ship 3 cells and pins it'**
  String get pirate_p15_desc;

  /// No description provided for @pirate_p15_lore.
  ///
  /// In en, this message translates to:
  /// **'The strongest pull in the sea. Slow, but never lets go.'**
  String get pirate_p15_lore;

  /// No description provided for @pirate_p17_name.
  ///
  /// In en, this message translates to:
  /// **'Pingu the Slider'**
  String get pirate_p17_name;

  /// No description provided for @pirate_p17_desc.
  ///
  /// In en, this message translates to:
  /// **'Bounces, then belly-slides across the deck'**
  String get pirate_p17_desc;

  /// No description provided for @pirate_p17_lore.
  ///
  /// In en, this message translates to:
  /// **'No ice? No problem. Pingu slides on anything.'**
  String get pirate_p17_lore;

  /// No description provided for @pirate_p18_name.
  ///
  /// In en, this message translates to:
  /// **'Sheldon the Horseshoe'**
  String get pirate_p18_name;

  /// No description provided for @pirate_p18_desc.
  ///
  /// In en, this message translates to:
  /// **'Ricochets off walls for repeat hits'**
  String get pirate_p18_desc;

  /// No description provided for @pirate_p18_lore.
  ///
  /// In en, this message translates to:
  /// **'A shell that survived 300 million years bounces off anything.'**
  String get pirate_p18_lore;

  /// No description provided for @pirate_p19_name.
  ///
  /// In en, this message translates to:
  /// **'Dolphy the Surfer'**
  String get pirate_p19_name;

  /// No description provided for @pirate_p19_desc.
  ///
  /// In en, this message translates to:
  /// **'Clings to the hull and pounds the waterline'**
  String get pirate_p19_desc;

  /// No description provided for @pirate_p19_lore.
  ///
  /// In en, this message translates to:
  /// **'Has never stopped smiling on a wave.'**
  String get pirate_p19_lore;

  /// No description provided for @pirate_p20_name.
  ///
  /// In en, this message translates to:
  /// **'Orca the Tide'**
  String get pirate_p20_name;

  /// No description provided for @pirate_p20_desc.
  ///
  /// In en, this message translates to:
  /// **'Huge wave sweeps the deck, flooding +8%p'**
  String get pirate_p20_desc;

  /// No description provided for @pirate_p20_lore.
  ///
  /// In en, this message translates to:
  /// **'When Orca passes, the whole sea tilts.'**
  String get pirate_p20_lore;

  /// No description provided for @pirate_p22_name.
  ///
  /// In en, this message translates to:
  /// **'Jelly the Mine'**
  String get pirate_p22_name;

  /// No description provided for @pirate_p22_desc.
  ///
  /// In en, this message translates to:
  /// **'Floating mine that blows when a ship passes'**
  String get pirate_p22_desc;

  /// No description provided for @pirate_p22_lore.
  ///
  /// In en, this message translates to:
  /// **'Nobody knows where she drifts. Not even Jelly.'**
  String get pirate_p22_lore;

  /// No description provided for @pirate_p23_name.
  ///
  /// In en, this message translates to:
  /// **'Bara the Torpedo'**
  String get pirate_p23_name;

  /// No description provided for @pirate_p23_desc.
  ///
  /// In en, this message translates to:
  /// **'Straight torpedo that dives under the waterline'**
  String get pirate_p23_desc;

  /// No description provided for @pirate_p23_lore.
  ///
  /// In en, this message translates to:
  /// **'Once Bara picks a heading, it never turns.'**
  String get pirate_p23_lore;

  /// No description provided for @pirate_p24_name.
  ///
  /// In en, this message translates to:
  /// **'Moray the Eel'**
  String get pirate_p24_name;

  /// No description provided for @pirate_p24_desc.
  ///
  /// In en, this message translates to:
  /// **'Latches on, gnaws blocks and jams pumps'**
  String get pirate_p24_desc;

  /// No description provided for @pirate_p24_lore.
  ///
  /// In en, this message translates to:
  /// **'Sees a gap, sticks its teeth in first.'**
  String get pirate_p24_lore;

  /// No description provided for @pirate_p25_name.
  ///
  /// In en, this message translates to:
  /// **'Kraki the Little Kraken'**
  String get pirate_p25_name;

  /// No description provided for @pirate_p25_desc.
  ///
  /// In en, this message translates to:
  /// **'Tentacles cling on and keep the water rising'**
  String get pirate_p25_desc;

  /// No description provided for @pirate_p25_lore.
  ///
  /// In en, this message translates to:
  /// **'Just a baby, but already has three tentacles.'**
  String get pirate_p25_lore;

  /// No description provided for @pirate_p29_name.
  ///
  /// In en, this message translates to:
  /// **'Alba the Albatross'**
  String get pirate_p29_name;

  /// No description provided for @pirate_p29_desc.
  ///
  /// In en, this message translates to:
  /// **'Tap to change course; reverses the wind on hit'**
  String get pirate_p29_desc;

  /// No description provided for @pirate_p29_lore.
  ///
  /// In en, this message translates to:
  /// **'The first bird to learn to fly against the wind.'**
  String get pirate_p29_lore;

  /// No description provided for @pirate_p30_name.
  ///
  /// In en, this message translates to:
  /// **'Manta the Storm Ray'**
  String get pirate_p30_name;

  /// No description provided for @pirate_p30_desc.
  ///
  /// In en, this message translates to:
  /// **'Blinds the enemy aim line and strikes at random'**
  String get pirate_p30_desc;

  /// No description provided for @pirate_p30_lore.
  ///
  /// In en, this message translates to:
  /// **'No path is left in the sky Manta crosses.'**
  String get pirate_p30_lore;

  /// No description provided for @pirate_p32_name.
  ///
  /// In en, this message translates to:
  /// **'Crabby the Roper'**
  String get pirate_p32_name;

  /// No description provided for @pirate_p32_desc.
  ///
  /// In en, this message translates to:
  /// **'Swings over and drags a pirate into the sea'**
  String get pirate_p32_desc;

  /// No description provided for @pirate_p32_lore.
  ///
  /// In en, this message translates to:
  /// **'One big claw is all it takes.'**
  String get pirate_p32_lore;

  /// No description provided for @pirate_p33_name.
  ///
  /// In en, this message translates to:
  /// **'King the Shieldcrab'**
  String get pirate_p33_name;

  /// No description provided for @pirate_p33_desc.
  ///
  /// In en, this message translates to:
  /// **'Lands and seals a cabin for a turn'**
  String get pirate_p33_desc;

  /// No description provided for @pirate_p33_lore.
  ///
  /// In en, this message translates to:
  /// **'Has never learned how to put the shield down.'**
  String get pirate_p33_lore;

  /// No description provided for @pirate_p34_name.
  ///
  /// In en, this message translates to:
  /// **'Lob the Twin-Claw'**
  String get pirate_p34_name;

  /// No description provided for @pirate_p34_desc.
  ///
  /// In en, this message translates to:
  /// **'Leaps to the next pirate after a knockout'**
  String get pirate_p34_desc;

  /// No description provided for @pirate_p34_lore.
  ///
  /// In en, this message translates to:
  /// **'Nobody has seen both claws at rest.'**
  String get pirate_p34_lore;

  /// No description provided for @pirate_p35_name.
  ///
  /// In en, this message translates to:
  /// **'Davy the Skull Captain'**
  String get pirate_p35_name;

  /// No description provided for @pirate_p35_desc.
  ///
  /// In en, this message translates to:
  /// **'Summons 3 skeleton crew and revives once'**
  String get pirate_p35_desc;

  /// No description provided for @pirate_p35_lore.
  ///
  /// In en, this message translates to:
  /// **'A captain back from the deep. He will not sink twice.'**
  String get pirate_p35_lore;

  /// No description provided for @pirate_p37_name.
  ///
  /// In en, this message translates to:
  /// **'Pumpum the Baby Whale'**
  String get pirate_p37_name;

  /// No description provided for @pirate_p37_desc.
  ///
  /// In en, this message translates to:
  /// **'Spouts water out, cutting flooding at once'**
  String get pirate_p37_desc;

  /// No description provided for @pirate_p37_lore.
  ///
  /// In en, this message translates to:
  /// **'Proud of the spout from its blowhole.'**
  String get pirate_p37_lore;

  /// No description provided for @pirate_p38_name.
  ///
  /// In en, this message translates to:
  /// **'Cook the Hermit Crab'**
  String get pirate_p38_name;

  /// No description provided for @pirate_p38_desc.
  ///
  /// In en, this message translates to:
  /// **'Heals nearby crew and cuts cooldowns by 1'**
  String get pirate_p38_desc;

  /// No description provided for @pirate_p38_lore.
  ///
  /// In en, this message translates to:
  /// **'Believes a hungry crew cannot fight.'**
  String get pirate_p38_lore;

  /// No description provided for @pirate_p39_name.
  ///
  /// In en, this message translates to:
  /// **'Corey the Coral Golem'**
  String get pirate_p39_name;

  /// No description provided for @pirate_p39_desc.
  ///
  /// In en, this message translates to:
  /// **'Raises a coral wall for 2 turns'**
  String get pirate_p39_desc;

  /// No description provided for @pirate_p39_lore.
  ///
  /// In en, this message translates to:
  /// **'Grows slowly, but stands in front of anything.'**
  String get pirate_p39_lore;

  /// No description provided for @pirate_p40_name.
  ///
  /// In en, this message translates to:
  /// **'Lamp the Anglerfish'**
  String get pirate_p40_name;

  /// No description provided for @pirate_p40_desc.
  ///
  /// In en, this message translates to:
  /// **'Next turn: full aim line, no wind, +30 fuel'**
  String get pirate_p40_desc;

  /// No description provided for @pirate_p40_lore.
  ///
  /// In en, this message translates to:
  /// **'Has never lost the way, even in the darkest sea.'**
  String get pirate_p40_lore;

  /// No description provided for @blueprint_balanced_name.
  ///
  /// In en, this message translates to:
  /// **'Balanced'**
  String get blueprint_balanced_name;

  /// No description provided for @blueprint_balanced_desc.
  ///
  /// In en, this message translates to:
  /// **'Oak keel with a pump and a workshop. A gun port and a lookout back one star pirate.'**
  String get blueprint_balanced_desc;

  /// No description provided for @blueprint_armored_name.
  ///
  /// In en, this message translates to:
  /// **'Ironclad'**
  String get blueprint_armored_name;

  /// No description provided for @blueprint_armored_desc.
  ///
  /// In en, this message translates to:
  /// **'Iron walls guard both sides of the cabins, and a magazine adds firepower. Heavy and low in the water, so watch the flooding.'**
  String get blueprint_armored_desc;

  /// No description provided for @blueprint_fast_name.
  ///
  /// In en, this message translates to:
  /// **'Swift'**
  String get blueprint_fast_name;

  /// No description provided for @blueprint_fast_desc.
  ///
  /// In en, this message translates to:
  /// **'Pine and cork keep it light, and two fuel tanks let it roam far. It breaks easily.'**
  String get blueprint_fast_desc;

  /// No description provided for @ammoExplosive.
  ///
  /// In en, this message translates to:
  /// **'Blast {n}%'**
  String ammoExplosive(int n);

  /// No description provided for @ammoFire.
  ///
  /// In en, this message translates to:
  /// **'Fire {n}T'**
  String ammoFire(int n);

  /// No description provided for @ammoSplit.
  ///
  /// In en, this message translates to:
  /// **'Split ×{n}'**
  String ammoSplit(int n);

  /// No description provided for @ammoBurst.
  ///
  /// In en, this message translates to:
  /// **'Burst ×{n}'**
  String ammoBurst(int n);

  /// No description provided for @ammoSniper.
  ///
  /// In en, this message translates to:
  /// **'Crit ×{rate}'**
  String ammoSniper(String rate);

  /// No description provided for @ammoChain.
  ///
  /// In en, this message translates to:
  /// **'Chain {n}'**
  String ammoChain(int n);

  /// No description provided for @ammoPierce.
  ///
  /// In en, this message translates to:
  /// **'Pierce {n}'**
  String ammoPierce(int n);

  /// No description provided for @ammoSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip ×{n}'**
  String ammoSkip(int n);

  /// No description provided for @ammoMine.
  ///
  /// In en, this message translates to:
  /// **'Mine {n}T'**
  String ammoMine(int n);

  /// No description provided for @ammoFlock.
  ///
  /// In en, this message translates to:
  /// **'Drop ×{n}'**
  String ammoFlock(int n);

  /// No description provided for @ammoHoming.
  ///
  /// In en, this message translates to:
  /// **'Homing {n}°'**
  String ammoHoming(int n);

  /// No description provided for @ammoAssault.
  ///
  /// In en, this message translates to:
  /// **'Raid +{n}'**
  String ammoAssault(int n);

  /// No description provided for @ammoSupport.
  ///
  /// In en, this message translates to:
  /// **'Repair {n}%'**
  String ammoSupport(int n);

  /// No description provided for @rangeShort.
  ///
  /// In en, this message translates to:
  /// **'Short'**
  String get rangeShort;

  /// No description provided for @rangeMedium.
  ///
  /// In en, this message translates to:
  /// **'Mid'**
  String get rangeMedium;

  /// No description provided for @rangeLong.
  ///
  /// In en, this message translates to:
  /// **'Long'**
  String get rangeLong;

  /// No description provided for @rangeVeryLong.
  ///
  /// In en, this message translates to:
  /// **'Far'**
  String get rangeVeryLong;

  /// No description provided for @outOfRange.
  ///
  /// In en, this message translates to:
  /// **'Out of range'**
  String get outOfRange;

  /// No description provided for @tapToSplit.
  ///
  /// In en, this message translates to:
  /// **'Tap to split!'**
  String get tapToSplit;

  /// No description provided for @aimCancel.
  ///
  /// In en, this message translates to:
  /// **'Release to cancel'**
  String get aimCancel;

  /// No description provided for @menuHotseat.
  ///
  /// In en, this message translates to:
  /// **'Two players'**
  String get menuHotseat;

  /// No description provided for @menuShipyard.
  ///
  /// In en, this message translates to:
  /// **'Shipyard'**
  String get menuShipyard;

  /// No description provided for @menuCrew.
  ///
  /// In en, this message translates to:
  /// **'Crew'**
  String get menuCrew;

  /// No description provided for @statPoints.
  ///
  /// In en, this message translates to:
  /// **'Points {used}/{max}'**
  String statPoints(int used, int max);

  /// No description provided for @statWaterline.
  ///
  /// In en, this message translates to:
  /// **'Draft {cells}'**
  String statWaterline(String cells);

  /// No description provided for @statFuelPerCell.
  ///
  /// In en, this message translates to:
  /// **'Fuel/cell {fuel}'**
  String statFuelPerCell(String fuel);

  /// No description provided for @statTank.
  ///
  /// In en, this message translates to:
  /// **'Tank {n}'**
  String statTank(int n);

  /// No description provided for @statSpeed.
  ///
  /// In en, this message translates to:
  /// **'Speed {speed}/s'**
  String statSpeed(String speed);

  /// No description provided for @statCabins.
  ///
  /// In en, this message translates to:
  /// **'Cabins {n}/{max}'**
  String statCabins(int n, int max);

  /// No description provided for @statModules.
  ///
  /// In en, this message translates to:
  /// **'Modules {n}/{max}'**
  String statModules(int n, int max);

  /// No description provided for @statCaptain.
  ///
  /// In en, this message translates to:
  /// **'Captain {n}/1'**
  String statCaptain(int n);

  /// No description provided for @materialPine.
  ///
  /// In en, this message translates to:
  /// **'Pine'**
  String get materialPine;

  /// No description provided for @materialOak.
  ///
  /// In en, this message translates to:
  /// **'Oak'**
  String get materialOak;

  /// No description provided for @materialIron.
  ///
  /// In en, this message translates to:
  /// **'Iron'**
  String get materialIron;

  /// No description provided for @materialCork.
  ///
  /// In en, this message translates to:
  /// **'Cork'**
  String get materialCork;

  /// No description provided for @materialNet.
  ///
  /// In en, this message translates to:
  /// **'Net'**
  String get materialNet;

  /// No description provided for @toolCabin.
  ///
  /// In en, this message translates to:
  /// **'Cabin'**
  String get toolCabin;

  /// No description provided for @toolErase.
  ///
  /// In en, this message translates to:
  /// **'Erase'**
  String get toolErase;

  /// No description provided for @moduleGunPort.
  ///
  /// In en, this message translates to:
  /// **'Gun port'**
  String get moduleGunPort;

  /// No description provided for @moduleMagazine.
  ///
  /// In en, this message translates to:
  /// **'Magazine'**
  String get moduleMagazine;

  /// No description provided for @modulePump.
  ///
  /// In en, this message translates to:
  /// **'Pump'**
  String get modulePump;

  /// No description provided for @moduleWorkshop.
  ///
  /// In en, this message translates to:
  /// **'Workshop'**
  String get moduleWorkshop;

  /// No description provided for @moduleMast.
  ///
  /// In en, this message translates to:
  /// **'Pine mast'**
  String get moduleMast;

  /// No description provided for @moduleMastBamboo.
  ///
  /// In en, this message translates to:
  /// **'Bamboo mast'**
  String get moduleMastBamboo;

  /// No description provided for @moduleMastOak.
  ///
  /// In en, this message translates to:
  /// **'Oak mast'**
  String get moduleMastOak;

  /// No description provided for @moduleMastIron.
  ///
  /// In en, this message translates to:
  /// **'Iron mast'**
  String get moduleMastIron;

  /// No description provided for @moduleMastCrow.
  ///
  /// In en, this message translates to:
  /// **'Crow mast'**
  String get moduleMastCrow;

  /// No description provided for @moduleLookout.
  ///
  /// In en, this message translates to:
  /// **'Lookout'**
  String get moduleLookout;

  /// No description provided for @moduleCaptain.
  ///
  /// In en, this message translates to:
  /// **'Captain'**
  String get moduleCaptain;

  /// No description provided for @moduleFuelTank.
  ///
  /// In en, this message translates to:
  /// **'Fuel tank'**
  String get moduleFuelTank;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @cannotSave.
  ///
  /// In en, this message translates to:
  /// **'Check the red cells and counts'**
  String get cannotSave;

  /// No description provided for @sailWithThis.
  ///
  /// In en, this message translates to:
  /// **'Sail with this'**
  String get sailWithThis;

  /// No description provided for @sailing.
  ///
  /// In en, this message translates to:
  /// **'Sailing'**
  String get sailing;

  /// No description provided for @loadPreset.
  ///
  /// In en, this message translates to:
  /// **'Load preset'**
  String get loadPreset;

  /// No description provided for @planSlot.
  ///
  /// In en, this message translates to:
  /// **'Plan {n}'**
  String planSlot(int n);

  /// No description provided for @crewCost.
  ///
  /// In en, this message translates to:
  /// **'Cost {used}/{max}'**
  String crewCost(int used, int max);

  /// No description provided for @crewHint.
  ///
  /// In en, this message translates to:
  /// **'Drag pirates into the cabins'**
  String get crewHint;

  /// No description provided for @deckFamilies.
  ///
  /// In en, this message translates to:
  /// **'Types'**
  String get deckFamilies;

  /// No description provided for @deckRanges.
  ///
  /// In en, this message translates to:
  /// **'Range'**
  String get deckRanges;

  /// No description provided for @preferNear.
  ///
  /// In en, this message translates to:
  /// **'Fights close'**
  String get preferNear;

  /// No description provided for @preferFar.
  ///
  /// In en, this message translates to:
  /// **'Fights far'**
  String get preferFar;

  /// No description provided for @preferMixed.
  ///
  /// In en, this message translates to:
  /// **'Any distance'**
  String get preferMixed;

  /// No description provided for @familyLob.
  ///
  /// In en, this message translates to:
  /// **'Lob'**
  String get familyLob;

  /// No description provided for @familyDirect.
  ///
  /// In en, this message translates to:
  /// **'Direct'**
  String get familyDirect;

  /// No description provided for @familyPierce.
  ///
  /// In en, this message translates to:
  /// **'Pierce'**
  String get familyPierce;

  /// No description provided for @familySkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get familySkip;

  /// No description provided for @familyUnderwater.
  ///
  /// In en, this message translates to:
  /// **'Underwater'**
  String get familyUnderwater;

  /// No description provided for @familyAir.
  ///
  /// In en, this message translates to:
  /// **'Air'**
  String get familyAir;

  /// No description provided for @familyAssault.
  ///
  /// In en, this message translates to:
  /// **'Assault'**
  String get familyAssault;

  /// No description provided for @familySupport.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get familySupport;

  /// No description provided for @rarityCommon.
  ///
  /// In en, this message translates to:
  /// **'Common'**
  String get rarityCommon;

  /// No description provided for @rarityRare.
  ///
  /// In en, this message translates to:
  /// **'Rare'**
  String get rarityRare;

  /// No description provided for @rarityHero.
  ///
  /// In en, this message translates to:
  /// **'Hero'**
  String get rarityHero;

  /// No description provided for @rarityLegend.
  ///
  /// In en, this message translates to:
  /// **'Legend'**
  String get rarityLegend;

  /// No description provided for @rarityMyth.
  ///
  /// In en, this message translates to:
  /// **'Myth'**
  String get rarityMyth;

  /// No description provided for @opponentAi.
  ///
  /// In en, this message translates to:
  /// **'Computer (AI)'**
  String get opponentAi;

  /// No description provided for @menuBattleAi.
  ///
  /// In en, this message translates to:
  /// **'Battle the AI'**
  String get menuBattleAi;

  /// No description provided for @chooseLevel.
  ///
  /// In en, this message translates to:
  /// **'Difficulty'**
  String get chooseLevel;

  /// No description provided for @levelEasy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get levelEasy;

  /// No description provided for @levelNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get levelNormal;

  /// No description provided for @levelHard.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get levelHard;

  /// No description provided for @levelHell.
  ///
  /// In en, this message translates to:
  /// **'Hell'**
  String get levelHell;

  /// No description provided for @autoEndTurn.
  ///
  /// In en, this message translates to:
  /// **'Auto end turn after 2 shots'**
  String get autoEndTurn;

  /// No description provided for @sea_1_name.
  ///
  /// In en, this message translates to:
  /// **'Tropic Bay'**
  String get sea_1_name;

  /// No description provided for @sea_1_faction.
  ///
  /// In en, this message translates to:
  /// **'Red Claw Patrol'**
  String get sea_1_faction;

  /// No description provided for @mission_no_pirate_down.
  ///
  /// In en, this message translates to:
  /// **'Win with no pirate knocked out'**
  String get mission_no_pirate_down;

  /// No description provided for @mission_flood_below.
  ///
  /// In en, this message translates to:
  /// **'Win with flooding at {percent}% or less'**
  String mission_flood_below(Object percent);

  /// No description provided for @mission_hull_above.
  ///
  /// In en, this message translates to:
  /// **'Win with hull at {percent}% or more'**
  String mission_hull_above(Object percent);

  /// No description provided for @mission_win_by_sink.
  ///
  /// In en, this message translates to:
  /// **'Win by sinking (not by wipeout or time)'**
  String get mission_win_by_sink;

  /// No description provided for @mission_turns_within.
  ///
  /// In en, this message translates to:
  /// **'Win within {turns} turns'**
  String mission_turns_within(Object turns);

  /// No description provided for @story_t1_enemy.
  ///
  /// In en, this message translates to:
  /// **'Patrol recruit: The harbor is closed! Turn back, pirates!'**
  String get story_t1_enemy;

  /// No description provided for @story_t1_ally.
  ///
  /// In en, this message translates to:
  /// **'Octo: Pirates? We were just fixing our boat… Fine, have a bomb!'**
  String get story_t1_ally;

  /// No description provided for @story_t2_enemy.
  ///
  /// In en, this message translates to:
  /// **'Patrol recruit: Two of us this time. We\'ll keep our distance and fire!'**
  String get story_t2_enemy;

  /// No description provided for @story_t2_ally.
  ///
  /// In en, this message translates to:
  /// **'Tok: Save your fuel. Choose when to close in and when to fall back.'**
  String get story_t2_ally;

  /// No description provided for @story_t3_enemy.
  ///
  /// In en, this message translates to:
  /// **'Patrol diver: Punch a hole below the waterline and any ship goes down.'**
  String get story_t3_enemy;

  /// No description provided for @story_t3_ally.
  ///
  /// In en, this message translates to:
  /// **'Tok: I\'ll patch the holes. Run the pump before the water rises!'**
  String get story_t3_ally;

  /// No description provided for @story_s1_1_enemy.
  ///
  /// In en, this message translates to:
  /// **'Patrol guard: Pirate inspection. Where are you going in that wreck?'**
  String get story_s1_1_enemy;

  /// No description provided for @story_s1_1_ally.
  ///
  /// In en, this message translates to:
  /// **'Octo: We built this ship with our own hands. Don\'t call it a wreck!'**
  String get story_s1_1_ally;

  /// No description provided for @story_s1_2_enemy.
  ///
  /// In en, this message translates to:
  /// **'Patrol guard: We brought a harpooner. Hiding behind walls won\'t help.'**
  String get story_s1_2_enemy;

  /// No description provided for @story_s1_2_ally.
  ///
  /// In en, this message translates to:
  /// **'Suri: Watch my stone skip. Aim for the waterline, right?'**
  String get story_s1_2_ally;

  /// No description provided for @story_s1_3_enemy.
  ///
  /// In en, this message translates to:
  /// **'Patrol scout: The parrot will find you. There\'s nowhere to hide.'**
  String get story_s1_3_enemy;

  /// No description provided for @story_s1_3_ally.
  ///
  /// In en, this message translates to:
  /// **'Octo: Then let\'s finish before we spring a leak. Fast!'**
  String get story_s1_3_ally;

  /// No description provided for @story_s1_4_enemy.
  ///
  /// In en, this message translates to:
  /// **'Patrol gunner: Four of us firing and your deck won\'t survive.'**
  String get story_s1_4_enemy;

  /// No description provided for @story_s1_4_ally.
  ///
  /// In en, this message translates to:
  /// **'Polly: The sky is mine! I\'ll dive on them from above.'**
  String get story_s1_4_ally;

  /// No description provided for @story_s1_5_enemy.
  ///
  /// In en, this message translates to:
  /// **'Crab Lieutenant: See the iron bow? Your bullets bounce right off!'**
  String get story_s1_5_enemy;

  /// No description provided for @story_s1_5_ally.
  ///
  /// In en, this message translates to:
  /// **'Tok: If the front is hard, hit from above or below.'**
  String get story_s1_5_ally;

  /// No description provided for @story_s1_12_enemy.
  ///
  /// In en, this message translates to:
  /// **'Patrol captain: You\'ll never take the heart shard. The cutter is closing in!'**
  String get story_s1_12_enemy;

  /// No description provided for @story_s1_12_ally.
  ///
  /// In en, this message translates to:
  /// **'Octo: The first shard is ours. Everyone, fire!'**
  String get story_s1_12_ally;

  /// No description provided for @portLevel.
  ///
  /// In en, this message translates to:
  /// **'Lv {level}'**
  String portLevel(Object level);

  /// No description provided for @portXp.
  ///
  /// In en, this message translates to:
  /// **'XP {xp} / {next}'**
  String portXp(Object xp, Object next);

  /// No description provided for @portSail.
  ///
  /// In en, this message translates to:
  /// **'Set Sail'**
  String get portSail;

  /// No description provided for @portShipyardLocked.
  ///
  /// In en, this message translates to:
  /// **'The shipyard opens from your 4th battle'**
  String get portShipyardLocked;

  /// No description provided for @soundOn.
  ///
  /// In en, this message translates to:
  /// **'Sound effects'**
  String get soundOn;

  /// No description provided for @vibrationOn.
  ///
  /// In en, this message translates to:
  /// **'Vibration'**
  String get vibrationOn;

  /// No description provided for @calmShakeOn.
  ///
  /// In en, this message translates to:
  /// **'Reduce screen shake'**
  String get calmShakeOn;

  /// No description provided for @campaignTitle.
  ///
  /// In en, this message translates to:
  /// **'Campaign'**
  String get campaignTitle;

  /// No description provided for @stageLocked.
  ///
  /// In en, this message translates to:
  /// **'Clear the previous stage first'**
  String get stageLocked;

  /// No description provided for @stageTutorialName.
  ///
  /// In en, this message translates to:
  /// **'Tutorial {n}'**
  String stageTutorialName(Object n);

  /// No description provided for @stageNumberName.
  ///
  /// In en, this message translates to:
  /// **'{sea}-{number}'**
  String stageNumberName(Object sea, Object number);

  /// No description provided for @stageKindMidBoss.
  ///
  /// In en, this message translates to:
  /// **'Mid boss'**
  String get stageKindMidBoss;

  /// No description provided for @stageKindBoss.
  ///
  /// In en, this message translates to:
  /// **'Sea boss'**
  String get stageKindBoss;

  /// No description provided for @prepTitle.
  ///
  /// In en, this message translates to:
  /// **'Battle Prep'**
  String get prepTitle;

  /// No description provided for @prepBlueprintSlot.
  ///
  /// In en, this message translates to:
  /// **'Blueprint {slot}'**
  String prepBlueprintSlot(Object slot);

  /// No description provided for @prepBlueprintEmpty.
  ///
  /// In en, this message translates to:
  /// **'Empty (Balanced preset)'**
  String get prepBlueprintEmpty;

  /// No description provided for @prepDeck.
  ///
  /// In en, this message translates to:
  /// **'Crew'**
  String get prepDeck;

  /// No description provided for @prepCost.
  ///
  /// In en, this message translates to:
  /// **'Cost {used} / {limit}'**
  String prepCost(Object used, Object limit);

  /// No description provided for @prepEnemy.
  ///
  /// In en, this message translates to:
  /// **'Opponent'**
  String get prepEnemy;

  /// No description provided for @prepEnemyCount.
  ///
  /// In en, this message translates to:
  /// **'{count} enemy pirates'**
  String prepEnemyCount(Object count);

  /// No description provided for @prepWeather.
  ///
  /// In en, this message translates to:
  /// **'Waves {wave} · Wind up to {wind}'**
  String prepWeather(Object wave, Object wind);

  /// No description provided for @prepEditDeck.
  ///
  /// In en, this message translates to:
  /// **'Edit crew'**
  String get prepEditDeck;

  /// No description provided for @prepSail.
  ///
  /// In en, this message translates to:
  /// **'Set sail'**
  String get prepSail;

  /// No description provided for @dialogueTap.
  ///
  /// In en, this message translates to:
  /// **'Tap to continue'**
  String get dialogueTap;

  /// No description provided for @personality_bombard.
  ///
  /// In en, this message translates to:
  /// **'Bombardier'**
  String get personality_bombard;

  /// No description provided for @personality_hunter.
  ///
  /// In en, this message translates to:
  /// **'Hunter'**
  String get personality_hunter;

  /// No description provided for @personality_sinker.
  ///
  /// In en, this message translates to:
  /// **'Sinker'**
  String get personality_sinker;

  /// No description provided for @personality_rusher.
  ///
  /// In en, this message translates to:
  /// **'Rusher'**
  String get personality_rusher;

  /// No description provided for @gimmick_bow_iron_shield.
  ///
  /// In en, this message translates to:
  /// **'Iron bow shield: direct fire deals half damage while it stands. Break the bow first'**
  String get gimmick_bow_iron_shield;

  /// No description provided for @gimmick_patrol_closing_in.
  ///
  /// In en, this message translates to:
  /// **'The cutter closes in one cell each turn and its cooldowns drop twice as fast'**
  String get gimmick_patrol_closing_in;

  /// No description provided for @resultMission.
  ///
  /// In en, this message translates to:
  /// **'Mission: {text}'**
  String resultMission(Object text);

  /// No description provided for @resultInTurns.
  ///
  /// In en, this message translates to:
  /// **'Win within {turns} turns'**
  String resultInTurns(Object turns);

  /// No description provided for @rewardGold.
  ///
  /// In en, this message translates to:
  /// **'Gold +{gold}'**
  String rewardGold(Object gold);

  /// No description provided for @rewardXp.
  ///
  /// In en, this message translates to:
  /// **'XP +{xp}'**
  String rewardXp(Object xp);

  /// No description provided for @rewardPirate.
  ///
  /// In en, this message translates to:
  /// **'New pirate joined: {name}'**
  String rewardPirate(Object name);

  /// No description provided for @rewardFirstClear.
  ///
  /// In en, this message translates to:
  /// **'First clear bonus'**
  String get rewardFirstClear;

  /// No description provided for @resultToPort.
  ///
  /// In en, this message translates to:
  /// **'To port'**
  String get resultToPort;

  /// No description provided for @resultMvp.
  ///
  /// In en, this message translates to:
  /// **'MVP'**
  String get resultMvp;

  /// No description provided for @statTurns.
  ///
  /// In en, this message translates to:
  /// **'Turns used {turns}'**
  String statTurns(Object turns);

  /// No description provided for @statShots.
  ///
  /// In en, this message translates to:
  /// **'{shots} shots'**
  String statShots(Object shots);

  /// No description provided for @statFlood.
  ///
  /// In en, this message translates to:
  /// **'Flooding you {mine}% · enemy {enemy}%'**
  String statFlood(Object mine, Object enemy);

  /// No description provided for @resultDouble.
  ///
  /// In en, this message translates to:
  /// **'Watch ad for 2×'**
  String get resultDouble;

  /// No description provided for @levelUpTo.
  ///
  /// In en, this message translates to:
  /// **'Level up! Lv {level}'**
  String levelUpTo(Object level);

  /// No description provided for @storySkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get storySkip;

  /// No description provided for @story_prologue_1.
  ///
  /// In en, this message translates to:
  /// **'A calm morning in Coral Harbor. Octo the octopus and Tok the turtle carpenter are fixing a small boat.'**
  String get story_prologue_1;

  /// No description provided for @story_prologue_2.
  ///
  /// In en, this message translates to:
  /// **'The golden flagship appears and Goldfin shatters the Heart of the Sea. The sky darkens and a storm rises.'**
  String get story_prologue_2;

  /// No description provided for @story_prologue_3.
  ///
  /// In en, this message translates to:
  /// **'The waves wreck our boat. Tok: “It\'s okay. We\'ll build a new one with our own hands!”'**
  String get story_prologue_3;

  /// No description provided for @story_prologue_4.
  ///
  /// In en, this message translates to:
  /// **'The Red Claw Patrol blockades the harbor under the excuse of a “pirate crackdown”. The first shard of the broken Heart glows on their flagship.'**
  String get story_prologue_4;

  /// No description provided for @story_prologue_5.
  ///
  /// In en, this message translates to:
  /// **'Octo: “Let\'s recover all six shards and sail to Golden Isle!” First we break through the patrol blocking the harbor.'**
  String get story_prologue_5;

  /// No description provided for @story_sea_1_intro_1.
  ///
  /// In en, this message translates to:
  /// **'Red Claw Patrol: Tropic Bay is our sea. This is a pirate crackdown, turn your ship around!'**
  String get story_sea_1_intro_1;

  /// No description provided for @story_sea_1_intro_2.
  ///
  /// In en, this message translates to:
  /// **'Tok: The first shard is glowing on their flagship. Let\'s take down the patrol boats one by one and reach it.'**
  String get story_sea_1_intro_2;

  /// No description provided for @story_s1_5_before.
  ///
  /// In en, this message translates to:
  /// **'Crab Lieutenant: I\'ll give you credit for getting this far. But you\'ll never get through this iron bow!'**
  String get story_s1_5_before;

  /// No description provided for @story_s1_5_after.
  ///
  /// In en, this message translates to:
  /// **'Crab Lieutenant: Argh… Retreat to the flagship! The captain won\'t let you get away with this!'**
  String get story_s1_5_after;

  /// No description provided for @story_s1_12_before_1.
  ///
  /// In en, this message translates to:
  /// **'Patrol captain: With the shard\'s power this cutter never stops. I\'ll close in and crush you.'**
  String get story_s1_12_before_1;

  /// No description provided for @story_s1_12_before_2.
  ///
  /// In en, this message translates to:
  /// **'Octo: Come closer, then. You\'ll get a taste of my bombs up close!'**
  String get story_s1_12_before_2;

  /// No description provided for @story_s1_12_after_1.
  ///
  /// In en, this message translates to:
  /// **'Patrol captain: The shard… lost its light. The fleet of Fog Strait will be waiting for you.'**
  String get story_s1_12_after_1;

  /// No description provided for @story_s1_12_after_2.
  ///
  /// In en, this message translates to:
  /// **'Tok: We got the first shard back! The Heart feels a little warmer.'**
  String get story_s1_12_after_2;

  /// No description provided for @story_s1_12_after_3.
  ///
  /// In en, this message translates to:
  /// **'Octo: Next is Fog Strait. The skeletons want to lift their curse with a shard?'**
  String get story_s1_12_after_3;

  /// No description provided for @tutorial_hint_1.
  ///
  /// In en, this message translates to:
  /// **'Tap a pirate card, then pull the pirate on deck backwards to fire'**
  String get tutorial_hint_1;

  /// No description provided for @tutorial_hint_2.
  ///
  /// In en, this message translates to:
  /// **'Move with the ◀ ▶ buttons. You only go as far as your fuel allows'**
  String get tutorial_hint_2;

  /// No description provided for @tutorial_hint_3.
  ///
  /// In en, this message translates to:
  /// **'Holes below the waterline mean flooding! Fire Tok at your own ship to repair'**
  String get tutorial_hint_3;

  /// No description provided for @resultDoubleDone.
  ///
  /// In en, this message translates to:
  /// **'Reward doubled'**
  String get resultDoubleDone;

  /// No description provided for @replaySave.
  ///
  /// In en, this message translates to:
  /// **'Save replay'**
  String get replaySave;

  /// No description provided for @replaySaved.
  ///
  /// In en, this message translates to:
  /// **'Replay saved'**
  String get replaySaved;

  /// No description provided for @statDamage.
  ///
  /// In en, this message translates to:
  /// **'Damage dealt {damage} · blocks broken {blocks}'**
  String statDamage(Object damage, Object blocks);

  /// No description provided for @statAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Accuracy {percent}%'**
  String statAccuracy(Object percent);

  /// No description provided for @iapRemoveAds.
  ///
  /// In en, this message translates to:
  /// **'Remove ads'**
  String get iapRemoveAds;

  /// No description provided for @iapBought.
  ///
  /// In en, this message translates to:
  /// **'Purchased'**
  String get iapBought;

  /// No description provided for @iapBuy.
  ///
  /// In en, this message translates to:
  /// **'Buy'**
  String get iapBuy;

  /// No description provided for @devTestBattle.
  ///
  /// In en, this message translates to:
  /// **'Test battle'**
  String get devTestBattle;

  /// No description provided for @devMyDeck.
  ///
  /// In en, this message translates to:
  /// **'My crew'**
  String get devMyDeck;

  /// No description provided for @devEnemyDeck.
  ///
  /// In en, this message translates to:
  /// **'Enemy crew'**
  String get devEnemyDeck;

  /// No description provided for @devRandomEnemy.
  ///
  /// In en, this message translates to:
  /// **'Empty enemy crew = 4 random pirates'**
  String get devRandomEnemy;

  /// No description provided for @devStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get devStart;

  /// No description provided for @devPractice.
  ///
  /// In en, this message translates to:
  /// **'Dummy practice'**
  String get devPractice;

  /// No description provided for @devToolsOn.
  ///
  /// In en, this message translates to:
  /// **'Developer tools on'**
  String get devToolsOn;

  /// No description provided for @devToolsOff.
  ///
  /// In en, this message translates to:
  /// **'Developer tools off'**
  String get devToolsOff;

  /// No description provided for @storyReplay.
  ///
  /// In en, this message translates to:
  /// **'Replay stories'**
  String get storyReplay;

  /// No description provided for @storyReplayEmpty.
  ///
  /// In en, this message translates to:
  /// **'No stories seen yet'**
  String get storyReplayEmpty;

  /// No description provided for @storyTitlePrologue.
  ///
  /// In en, this message translates to:
  /// **'Prologue'**
  String get storyTitlePrologue;

  /// No description provided for @storyTitleSea1Intro.
  ///
  /// In en, this message translates to:
  /// **'Sea 1 intro'**
  String get storyTitleSea1Intro;

  /// No description provided for @storyTitleMidBossBefore.
  ///
  /// In en, this message translates to:
  /// **'Before the mid-boss'**
  String get storyTitleMidBossBefore;

  /// No description provided for @storyTitleMidBossAfter.
  ///
  /// In en, this message translates to:
  /// **'After the mid-boss'**
  String get storyTitleMidBossAfter;

  /// No description provided for @storyTitleBossBefore.
  ///
  /// In en, this message translates to:
  /// **'Before the sea boss'**
  String get storyTitleBossBefore;

  /// No description provided for @storyTitleBossAfter.
  ///
  /// In en, this message translates to:
  /// **'After the sea boss'**
  String get storyTitleBossAfter;

  /// No description provided for @prepMyShip.
  ///
  /// In en, this message translates to:
  /// **'My ship'**
  String get prepMyShip;

  /// No description provided for @prepCabins.
  ///
  /// In en, this message translates to:
  /// **'Cabins'**
  String get prepCabins;

  /// No description provided for @prepCabinEmpty.
  ///
  /// In en, this message translates to:
  /// **'Empty cabin'**
  String get prepCabinEmpty;

  /// No description provided for @hitTagCrit.
  ///
  /// In en, this message translates to:
  /// **'CRIT'**
  String get hitTagCrit;

  /// No description provided for @hitTagPierce.
  ///
  /// In en, this message translates to:
  /// **'PIERCE'**
  String get hitTagPierce;

  /// No description provided for @hitTagChain.
  ///
  /// In en, this message translates to:
  /// **'CHAIN'**
  String get hitTagChain;

  /// No description provided for @hitTagBurn.
  ///
  /// In en, this message translates to:
  /// **'BURN'**
  String get hitTagBurn;

  /// No description provided for @hitTagMine.
  ///
  /// In en, this message translates to:
  /// **'MINE'**
  String get hitTagMine;

  /// No description provided for @hitTagBite.
  ///
  /// In en, this message translates to:
  /// **'BITE'**
  String get hitTagBite;

  /// No description provided for @hitTagRepair.
  ///
  /// In en, this message translates to:
  /// **'REPAIR'**
  String get hitTagRepair;

  /// No description provided for @hitTagSeal.
  ///
  /// In en, this message translates to:
  /// **'SEALED'**
  String get hitTagSeal;

  /// No description provided for @hitTagPull.
  ///
  /// In en, this message translates to:
  /// **'PULLED'**
  String get hitTagPull;

  /// No description provided for @hitTagWind.
  ///
  /// In en, this message translates to:
  /// **'WIND FLIP'**
  String get hitTagWind;

  /// No description provided for @hitTagBlind.
  ///
  /// In en, this message translates to:
  /// **'BLINDED'**
  String get hitTagBlind;

  /// No description provided for @hitTagBail.
  ///
  /// In en, this message translates to:
  /// **'BAIL'**
  String get hitTagBail;

  /// No description provided for @hitTagBoost.
  ///
  /// In en, this message translates to:
  /// **'LANTERN'**
  String get hitTagBoost;

  /// No description provided for @hitTagHeal.
  ///
  /// In en, this message translates to:
  /// **'HEAL'**
  String get hitTagHeal;

  /// No description provided for @hitTagWall.
  ///
  /// In en, this message translates to:
  /// **'WALL'**
  String get hitTagWall;

  /// No description provided for @hitTagRevive.
  ///
  /// In en, this message translates to:
  /// **'REVIVE'**
  String get hitTagRevive;

  /// No description provided for @hitTagIntercept.
  ///
  /// In en, this message translates to:
  /// **'INTERCEPT'**
  String get hitTagIntercept;

  /// No description provided for @cabinSealed.
  ///
  /// In en, this message translates to:
  /// **'Sealed'**
  String get cabinSealed;

  /// No description provided for @moveLocked.
  ///
  /// In en, this message translates to:
  /// **'Pinned'**
  String get moveLocked;

  /// No description provided for @windReversed.
  ///
  /// In en, this message translates to:
  /// **'Flipped'**
  String get windReversed;

  /// No description provided for @windCalm.
  ///
  /// In en, this message translates to:
  /// **'Calm'**
  String get windCalm;

  /// 조준 각도 라벨 (설계서 §10.4)
  ///
  /// In en, this message translates to:
  /// **'{deg}°'**
  String aimAngle(String deg);

  /// 조준 힘 라벨 (설계서 §10.4)
  ///
  /// In en, this message translates to:
  /// **'Power {pct}%'**
  String aimPower(String pct);

  /// 설정: 배경음악 켜기 (설계서 §10.3)
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get musicOn;

  /// No description provided for @shipUpgrades.
  ///
  /// In en, this message translates to:
  /// **'Ship upgrades'**
  String get shipUpgrades;

  /// No description provided for @shipStage1.
  ///
  /// In en, this message translates to:
  /// **'Dinghy'**
  String get shipStage1;

  /// No description provided for @shipStage2.
  ///
  /// In en, this message translates to:
  /// **'Small sloop'**
  String get shipStage2;

  /// No description provided for @shipStage3.
  ///
  /// In en, this message translates to:
  /// **'Sloop'**
  String get shipStage3;

  /// No description provided for @shipStage4.
  ///
  /// In en, this message translates to:
  /// **'Large sloop'**
  String get shipStage4;

  /// No description provided for @shipGrowRow.
  ///
  /// In en, this message translates to:
  /// **'Grow ship'**
  String get shipGrowRow;

  /// No description provided for @shipGrowNeed.
  ///
  /// In en, this message translates to:
  /// **'Clear {stage} to unlock'**
  String shipGrowNeed(Object stage);

  /// No description provided for @shipMaxed.
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get shipMaxed;

  /// No description provided for @hullLevelRow.
  ///
  /// In en, this message translates to:
  /// **'Hull Lv {level}'**
  String hullLevelRow(Object level);

  /// 조선소 배 업그레이드 (설계서 §3.1·§13.6, A28)
  ///
  /// In en, this message translates to:
  /// **'{name} Lv {level}'**
  String mastLevelRow(Object name, Object level);

  /// No description provided for @goldCost.
  ///
  /// In en, this message translates to:
  /// **'{gold} gold'**
  String goldCost(Object gold);

  /// 조선소 배 업그레이드 (설계서 §3.1·§13.6, A28)
  ///
  /// In en, this message translates to:
  /// **'Spend {gold} gold on {name}?'**
  String buyAsk(Object name, Object gold);

  /// No description provided for @notEnoughGold.
  ///
  /// In en, this message translates to:
  /// **'Not enough gold'**
  String get notEnoughGold;

  /// No description provided for @buy.
  ///
  /// In en, this message translates to:
  /// **'Buy'**
  String get buy;

  /// No description provided for @shipGrown.
  ///
  /// In en, this message translates to:
  /// **'Your ship grew!'**
  String get shipGrown;

  /// 조선소 배 업그레이드 (설계서 §3.1·§13.6, A28)
  ///
  /// In en, this message translates to:
  /// **'{width}×{height} cells · {cabins} cabins'**
  String shipGrownBody(Object width, Object height, Object cabins);

  /// No description provided for @shipGrowReady.
  ///
  /// In en, this message translates to:
  /// **'You can grow your ship! Visit the shipyard'**
  String get shipGrowReady;

  /// No description provided for @devStagePick.
  ///
  /// In en, this message translates to:
  /// **'Pick stage (dev)'**
  String get devStagePick;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @bossBanner.
  ///
  /// In en, this message translates to:
  /// **'Boss!'**
  String get bossBanner;

  /// No description provided for @barkFire1.
  ///
  /// In en, this message translates to:
  /// **'Take that!'**
  String get barkFire1;

  /// No description provided for @barkFire2.
  ///
  /// In en, this message translates to:
  /// **'Right on target!'**
  String get barkFire2;

  /// No description provided for @barkFire3.
  ///
  /// In en, this message translates to:
  /// **'One more coming!'**
  String get barkFire3;

  /// No description provided for @barkFire4.
  ///
  /// In en, this message translates to:
  /// **'Cannonball delivery!'**
  String get barkFire4;

  /// No description provided for @barkHurt1.
  ///
  /// In en, this message translates to:
  /// **'Ouch, that stings!'**
  String get barkHurt1;

  /// No description provided for @barkHurt2.
  ///
  /// In en, this message translates to:
  /// **'Barely a scratch!'**
  String get barkHurt2;

  /// No description provided for @barkHurt3.
  ///
  /// In en, this message translates to:
  /// **'The ship\'s rocking!'**
  String get barkHurt3;

  /// No description provided for @barkHurt4.
  ///
  /// In en, this message translates to:
  /// **'You\'ll pay for that!'**
  String get barkHurt4;

  /// No description provided for @barkAllyDown1.
  ///
  /// In en, this message translates to:
  /// **'Crew down! Hold on!'**
  String get barkAllyDown1;

  /// No description provided for @barkAllyDown2.
  ///
  /// In en, this message translates to:
  /// **'I\'ll fight for both of us!'**
  String get barkAllyDown2;

  /// No description provided for @barkAllyDown3.
  ///
  /// In en, this message translates to:
  /// **'Hang in there, we\'ll finish fast!'**
  String get barkAllyDown3;

  /// No description provided for @barkAllyDown4.
  ///
  /// In en, this message translates to:
  /// **'Now I\'m angry!'**
  String get barkAllyDown4;

  /// No description provided for @barkTauntStart1.
  ///
  /// In en, this message translates to:
  /// **'Pirate patrol! Surrender!'**
  String get barkTauntStart1;

  /// No description provided for @barkTauntStart2.
  ///
  /// In en, this message translates to:
  /// **'You call that a ship?'**
  String get barkTauntStart2;

  /// No description provided for @barkTauntStart3.
  ///
  /// In en, this message translates to:
  /// **'Nothing gets past the patrol!'**
  String get barkTauntStart3;

  /// No description provided for @barkTauntStart4.
  ///
  /// In en, this message translates to:
  /// **'Taste the claw!'**
  String get barkTauntStart4;

  /// No description provided for @barkTauntLow1.
  ///
  /// In en, this message translates to:
  /// **'Th-this can\'t be!'**
  String get barkTauntLow1;

  /// No description provided for @barkTauntLow2.
  ///
  /// In en, this message translates to:
  /// **'We\'re leaking! Man the pumps!'**
  String get barkTauntLow2;

  /// No description provided for @barkTauntLow3.
  ///
  /// In en, this message translates to:
  /// **'Not bad… but not done yet!'**
  String get barkTauntLow3;

  /// No description provided for @barkTauntLow4.
  ///
  /// In en, this message translates to:
  /// **'No retreat, hold the line!'**
  String get barkTauntLow4;

  /// No description provided for @goalTitle.
  ///
  /// In en, this message translates to:
  /// **'Next goal'**
  String get goalTitle;

  /// No description provided for @goalGo.
  ///
  /// In en, this message translates to:
  /// **'Go'**
  String get goalGo;

  /// 항구 다음 목표 카드 별 진행 (설계서 §13.2)
  ///
  /// In en, this message translates to:
  /// **'Stars {have} / {total}'**
  String goalStars(Object have, Object total);

  /// No description provided for @goalShipNeed.
  ///
  /// In en, this message translates to:
  /// **'Grow ship: clear {stage}'**
  String goalShipNeed(Object stage);

  /// No description provided for @goalShipDone.
  ///
  /// In en, this message translates to:
  /// **'Ship fully grown'**
  String get goalShipDone;

  /// No description provided for @goalAllClear.
  ///
  /// In en, this message translates to:
  /// **'Every stage here is cleared!'**
  String get goalAllClear;

  /// No description provided for @emphasisMast.
  ///
  /// In en, this message translates to:
  /// **'Mast down!'**
  String get emphasisMast;
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
