// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Pirate Busters';

  @override
  String turnsLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count turns left',
      one: '1 turn left',
    );
    return '$_temp0';
  }

  @override
  String get yourTurn => 'Your turn';

  @override
  String get enemyTurn => 'Enemy turn';

  @override
  String playerTurn(int side) {
    return 'Player $side turn';
  }

  @override
  String get hull => 'Hull';

  @override
  String flood(String percent) {
    return 'Flood $percent%';
  }

  @override
  String crewAlive(int alive, int total) {
    return 'Crew $alive/$total';
  }

  @override
  String get endTurn => 'End turn';

  @override
  String get retreat => 'Back';

  @override
  String get advance => 'Ahead';

  @override
  String get fuel => 'Fuel';

  @override
  String firesLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count shots left',
      one: '1 shot left',
    );
    return '$_temp0';
  }

  @override
  String cooldown(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Rest $count turns',
      one: 'Rest 1 turn',
    );
    return '$_temp0';
  }

  @override
  String get cabinFlooded => 'Flooded';

  @override
  String get pirateDown => 'Down';

  @override
  String get pirateSwimming => 'Swimming';

  @override
  String get wind => 'Wind';

  @override
  String get stormTime => 'Storm!';

  @override
  String get overview => 'Overview';

  @override
  String gapCells(int cells) {
    return 'Gap $cells';
  }

  @override
  String get pause => 'Pause';

  @override
  String get resume => 'Resume';

  @override
  String get surrender => 'Surrender';

  @override
  String get surrenderConfirm => 'Give up this battle?';

  @override
  String get cancel => 'Cancel';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'System';

  @override
  String get languageKorean => '한국어';

  @override
  String get languageEnglish => 'English';

  @override
  String get opponent => 'Opponent';

  @override
  String get opponentDummy => 'Training dummy';

  @override
  String get opponentHotseat => 'Two players (one device)';

  @override
  String get resultWin => 'Victory!';

  @override
  String get resultLose => 'Defeat';

  @override
  String get resultDraw => 'Draw';

  @override
  String get outcomeSunk => 'Ship wrecked';

  @override
  String get outcomeFloodSunk => 'Sunk by flooding';

  @override
  String get outcomeAnnihilation => 'Crew wiped out';

  @override
  String get outcomeTimeDecision => 'Time decision';

  @override
  String get outcomeSurrender => 'Surrender';

  @override
  String get playAgain => 'Play again';

  @override
  String playerWins(int side) {
    return 'Player $side wins!';
  }

  @override
  String get lowEndMode => 'Low-end mode';

  @override
  String damagePopup(String amount) {
    return '-$amount';
  }

  @override
  String get sunkBanner => 'Sunk!';

  @override
  String get surrenderQueued => 'You will surrender at the start of your turn';

  @override
  String get pirate_p01_name => 'Octo the Bomber';

  @override
  String get pirate_p01_desc => 'Lobbed bomb that bursts in a 1-cell radius';

  @override
  String get pirate_p01_lore =>
      'Raised in Coral Harbor, Octo juggles bombs with all eight arms.';

  @override
  String get pirate_p04_name => 'Uni the Urchin';

  @override
  String get pirate_p04_desc => 'Tap in flight to split into 4 spikes';

  @override
  String get pirate_p04_lore =>
      'As prickly as her spines. She picks the moment to burst.';

  @override
  String get pirate_p06_name => 'Pang the Pistol Shrimp';

  @override
  String get pirate_p06_desc => 'Claw-snap water bullet, critical on pirates';

  @override
  String get pirate_p06_lore => 'One snap of his claw fires a bubble bullet.';

  @override
  String get pirate_p07_name => 'Hippo the Gunslinger';

  @override
  String get pirate_p07_desc => 'Short-range triple shot';

  @override
  String get pirate_p07_lore =>
      'Anchors with his tail and fires two pistols at once.';

  @override
  String get pirate_p11_name => 'Finn the Harpooner';

  @override
  String get pirate_p11_desc => 'Harpoon charge that pierces 2 blocks';

  @override
  String get pirate_p11_lore =>
      'His long nose is the harpoon. Hiding behind walls won\'t help.';

  @override
  String get pirate_p16_name => 'Suri the Slinger';

  @override
  String get pirate_p16_desc => 'Stone skips twice and hits the waterline';

  @override
  String get pirate_p16_lore =>
      'Skips stones with the same knack she uses to crack clams.';

  @override
  String get pirate_p21_name => 'Puffy the Blaster';

  @override
  String get pirate_p21_desc => 'Clings below the waterline, bursts next turn';

  @override
  String get pirate_p21_lore =>
      'Puffs up, sticks under the hull, and then... boom.';

  @override
  String get pirate_p26_name => 'Polly the Parrot';

  @override
  String get pirate_p26_desc => 'Homes in on the nearest pirate and pecks';

  @override
  String get pirate_p26_lore =>
      'Leaves the captain\'s shoulder to chase enemy crew.';

  @override
  String get pirate_p27_name => 'Wing the Bombardier';

  @override
  String get pirate_p27_desc => 'Dives and drops 3 small bombs';

  @override
  String get pirate_p27_lore => 'Circles the sea, then dives in a flash.';

  @override
  String get pirate_p28_name => 'Pelly the Pelican';

  @override
  String get pirate_p28_desc => 'Drops 4 small bombs from her pouch next turn';

  @override
  String get pirate_p28_lore =>
      'Nobody knows what\'s in her pouch until it drops.';

  @override
  String get pirate_p31_name => 'Sharky the Brawler';

  @override
  String get pirate_p31_desc =>
      'Leaps onto the deck and bites pirates within 1 cell';

  @override
  String get pirate_p31_lore =>
      'Nothing makes him happier than jumping aboard.';

  @override
  String get pirate_p36_name => 'Tok the Shipwright';

  @override
  String get pirate_p36_desc => 'Fire at your ship to patch 3 holed blocks';

  @override
  String get pirate_p36_lore => 'Slow but careful. He keeps the ship afloat.';
}
