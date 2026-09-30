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

  @override
  String get blueprint_balanced_name => 'Balanced';

  @override
  String get blueprint_balanced_desc =>
      'Oak keel with a pump and a workshop. A gun port and a lookout back one star pirate.';

  @override
  String get blueprint_armored_name => 'Ironclad';

  @override
  String get blueprint_armored_desc =>
      'Iron walls guard both sides of the cabins. Heavy and low in the water, so the pump keeps it afloat.';

  @override
  String get blueprint_fast_name => 'Swift';

  @override
  String get blueprint_fast_desc =>
      'Pine and cork keep it light, and two fuel tanks let it roam far. It breaks easily.';

  @override
  String ammoExplosive(int n) {
    return 'Blast $n%';
  }

  @override
  String ammoFire(int n) {
    return 'Fire ${n}T';
  }

  @override
  String ammoSplit(int n) {
    return 'Split ×$n';
  }

  @override
  String ammoBurst(int n) {
    return 'Burst ×$n';
  }

  @override
  String ammoSniper(String rate) {
    return 'Crit ×$rate';
  }

  @override
  String ammoChain(int n) {
    return 'Chain $n';
  }

  @override
  String ammoPierce(int n) {
    return 'Pierce $n';
  }

  @override
  String ammoSkip(int n) {
    return 'Skip ×$n';
  }

  @override
  String ammoMine(int n) {
    return 'Mine ${n}T';
  }

  @override
  String ammoFlock(int n) {
    return 'Drop ×$n';
  }

  @override
  String ammoHoming(int n) {
    return 'Homing $n°';
  }

  @override
  String ammoAssault(int n) {
    return 'Raid +$n';
  }

  @override
  String ammoSupport(int n) {
    return 'Repair $n%';
  }

  @override
  String get rangeShort => 'Short';

  @override
  String get rangeMedium => 'Mid';

  @override
  String get rangeLong => 'Long';

  @override
  String get rangeVeryLong => 'Far';

  @override
  String get outOfRange => 'Out of range';

  @override
  String get tapToSplit => 'Tap to split!';

  @override
  String get menuBattle => 'Battle the dummy';

  @override
  String get menuHotseat => 'Two players';

  @override
  String get menuShipyard => 'Shipyard';

  @override
  String get menuCrew => 'Crew';

  @override
  String statPoints(int used, int max) {
    return 'Points $used/$max';
  }

  @override
  String statWaterline(String cells) {
    return 'Draft $cells';
  }

  @override
  String statFuelPerCell(String fuel) {
    return 'Fuel/cell $fuel';
  }

  @override
  String statTank(int n) {
    return 'Tank $n';
  }

  @override
  String statSpeed(String speed) {
    return 'Speed $speed/s';
  }

  @override
  String statCabins(int n, int max) {
    return 'Cabins $n/$max';
  }

  @override
  String statModules(int n, int max) {
    return 'Modules $n/$max';
  }

  @override
  String statCaptain(int n) {
    return 'Captain $n/1';
  }

  @override
  String get materialPine => 'Pine';

  @override
  String get materialOak => 'Oak';

  @override
  String get materialIron => 'Iron';

  @override
  String get materialCork => 'Cork';

  @override
  String get materialNet => 'Net';

  @override
  String get toolCabin => 'Cabin';

  @override
  String get toolErase => 'Erase';

  @override
  String get moduleGunPort => 'Gun port';

  @override
  String get moduleMagazine => 'Magazine';

  @override
  String get modulePump => 'Pump';

  @override
  String get moduleWorkshop => 'Workshop';

  @override
  String get moduleMast => 'Mast';

  @override
  String get moduleLookout => 'Lookout';

  @override
  String get moduleCaptain => 'Captain';

  @override
  String get moduleFuelTank => 'Fuel tank';

  @override
  String get undo => 'Undo';

  @override
  String get save => 'Save';

  @override
  String get saved => 'Saved';

  @override
  String get cannotSave => 'Check the red cells and counts';

  @override
  String get sailWithThis => 'Sail with this';

  @override
  String get sailing => 'Sailing';

  @override
  String get loadPreset => 'Load preset';

  @override
  String planSlot(int n) {
    return 'Plan $n';
  }

  @override
  String crewCost(int used, int max) {
    return 'Cost $used/$max';
  }

  @override
  String get crewHint => 'Drag pirates into the cabins';

  @override
  String get deckFamilies => 'Types';

  @override
  String get deckRanges => 'Range';

  @override
  String get preferNear => 'Fights close';

  @override
  String get preferFar => 'Fights far';

  @override
  String get preferMixed => 'Any distance';

  @override
  String get familyLob => 'Lob';

  @override
  String get familyDirect => 'Direct';

  @override
  String get familyPierce => 'Pierce';

  @override
  String get familySkip => 'Skip';

  @override
  String get familyUnderwater => 'Underwater';

  @override
  String get familyAir => 'Air';

  @override
  String get familyAssault => 'Assault';

  @override
  String get familySupport => 'Support';

  @override
  String get rarityCommon => 'Common';

  @override
  String get rarityRare => 'Rare';

  @override
  String get rarityHero => 'Hero';

  @override
  String get rarityLegend => 'Legend';

  @override
  String get rarityMyth => 'Myth';
}
