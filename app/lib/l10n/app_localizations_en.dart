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
  String get navBack => 'Back';

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
      'Iron walls guard both sides of the cabins, and a magazine adds firepower. Heavy and low in the water, so watch the flooding.';

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
  String get aimCancel => 'Release to cancel';

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

  @override
  String get opponentAi => 'Computer (AI)';

  @override
  String get menuBattleAi => 'Battle the AI';

  @override
  String get chooseLevel => 'Difficulty';

  @override
  String get levelEasy => 'Easy';

  @override
  String get levelNormal => 'Normal';

  @override
  String get levelHard => 'Hard';

  @override
  String get levelHell => 'Hell';

  @override
  String get autoEndTurn => 'Auto end turn after 2 shots';

  @override
  String get sea_1_name => 'Tropic Bay';

  @override
  String get sea_1_faction => 'Red Claw Patrol';

  @override
  String get mission_no_pirate_down => 'Win with no pirate knocked out';

  @override
  String mission_flood_below(Object percent) {
    return 'Win with flooding at $percent% or less';
  }

  @override
  String mission_hull_above(Object percent) {
    return 'Win with hull at $percent% or more';
  }

  @override
  String get mission_win_by_sink => 'Win by sinking (not by wipeout or time)';

  @override
  String mission_turns_within(Object turns) {
    return 'Win within $turns turns';
  }

  @override
  String get story_t1_enemy =>
      'Patrol recruit: The harbor is closed! Turn back, pirates!';

  @override
  String get story_t1_ally =>
      'Octo: Pirates? We were just fixing our boat… Fine, have a bomb!';

  @override
  String get story_t2_enemy =>
      'Patrol recruit: Two of us this time. We\'ll keep our distance and fire!';

  @override
  String get story_t2_ally =>
      'Tok: Save your fuel. Choose when to close in and when to fall back.';

  @override
  String get story_t3_enemy =>
      'Patrol diver: Punch a hole below the waterline and any ship goes down.';

  @override
  String get story_t3_ally =>
      'Tok: I\'ll patch the holes. Run the pump before the water rises!';

  @override
  String get story_s1_1_enemy =>
      'Patrol guard: Pirate inspection. Where are you going in that wreck?';

  @override
  String get story_s1_1_ally =>
      'Octo: We built this ship with our own hands. Don\'t call it a wreck!';

  @override
  String get story_s1_2_enemy =>
      'Patrol guard: We brought a harpooner. Hiding behind walls won\'t help.';

  @override
  String get story_s1_2_ally =>
      'Suri: Watch my stone skip. Aim for the waterline, right?';

  @override
  String get story_s1_3_enemy =>
      'Patrol scout: The parrot will find you. There\'s nowhere to hide.';

  @override
  String get story_s1_3_ally =>
      'Octo: Then let\'s finish before we spring a leak. Fast!';

  @override
  String get story_s1_4_enemy =>
      'Patrol gunner: Four of us firing and your deck won\'t survive.';

  @override
  String get story_s1_4_ally =>
      'Polly: The sky is mine! I\'ll dive on them from above.';

  @override
  String get story_s1_5_enemy =>
      'Crab Lieutenant: See the iron bow? Your bullets bounce right off!';

  @override
  String get story_s1_5_ally =>
      'Tok: If the front is hard, hit from above or below.';

  @override
  String get story_s1_12_enemy =>
      'Patrol captain: You\'ll never take the heart shard. The cutter is closing in!';

  @override
  String get story_s1_12_ally =>
      'Octo: The first shard is ours. Everyone, fire!';

  @override
  String portLevel(Object level) {
    return 'Lv $level';
  }

  @override
  String portXp(Object xp, Object next) {
    return 'XP $xp / $next';
  }

  @override
  String get portSail => 'Set Sail';

  @override
  String get portShipyardLocked => 'The shipyard opens from your 4th battle';

  @override
  String get soundOn => 'Sound effects';

  @override
  String get vibrationOn => 'Vibration';

  @override
  String get campaignTitle => 'Campaign';

  @override
  String get stageLocked => 'Clear the previous stage first';

  @override
  String stageTutorialName(Object n) {
    return 'Tutorial $n';
  }

  @override
  String stageNumberName(Object sea, Object number) {
    return '$sea-$number';
  }

  @override
  String get stageKindMidBoss => 'Mid boss';

  @override
  String get stageKindBoss => 'Sea boss';

  @override
  String get prepTitle => 'Battle Prep';

  @override
  String prepBlueprintSlot(Object slot) {
    return 'Blueprint $slot';
  }

  @override
  String get prepBlueprintEmpty => 'Empty (Balanced preset)';

  @override
  String get prepDeck => 'Crew';

  @override
  String prepCost(Object used, Object limit) {
    return 'Cost $used / $limit';
  }

  @override
  String get prepEnemy => 'Opponent';

  @override
  String prepEnemyCount(Object count) {
    return '$count enemy pirates';
  }

  @override
  String prepWeather(Object wave, Object wind) {
    return 'Waves $wave · Wind up to $wind';
  }

  @override
  String get prepEditDeck => 'Edit crew';

  @override
  String get prepSail => 'Set sail';

  @override
  String get dialogueTap => 'Tap to continue';

  @override
  String get personality_bombard => 'Bombardier';

  @override
  String get personality_hunter => 'Hunter';

  @override
  String get personality_sinker => 'Sinker';

  @override
  String get personality_rusher => 'Rusher';

  @override
  String get gimmick_bow_iron_shield =>
      'Iron bow shield: direct-fire damage from the front is greatly reduced';

  @override
  String get gimmick_patrol_closing_in =>
      'The cutter closes in every turn and its cooldowns drop faster';

  @override
  String resultMission(Object text) {
    return 'Mission: $text';
  }

  @override
  String resultInTurns(Object turns) {
    return 'Win within $turns turns';
  }

  @override
  String rewardGold(Object gold) {
    return 'Gold +$gold';
  }

  @override
  String rewardXp(Object xp) {
    return 'XP +$xp';
  }

  @override
  String rewardPirate(Object name) {
    return 'New pirate joined: $name';
  }

  @override
  String get rewardFirstClear => 'First clear bonus';

  @override
  String get resultToPort => 'To port';

  @override
  String get resultMvp => 'MVP';

  @override
  String statTurns(Object turns) {
    return 'Turns used $turns';
  }

  @override
  String statShots(Object shots) {
    return '$shots shots';
  }

  @override
  String statFlood(Object mine, Object enemy) {
    return 'Flooding you $mine% · enemy $enemy%';
  }

  @override
  String get resultDouble => 'Watch ad for 2×';

  @override
  String levelUpTo(Object level) {
    return 'Level up! Lv $level';
  }

  @override
  String get storySkip => 'Skip';

  @override
  String get story_prologue_1 =>
      'A calm morning in Coral Harbor. Octo the octopus and Tok the turtle carpenter are fixing a small boat.';

  @override
  String get story_prologue_2 =>
      'The golden flagship appears and Goldfin shatters the Heart of the Sea. The sky darkens and a storm rises.';

  @override
  String get story_prologue_3 =>
      'The waves wreck our boat. Tok: “It\'s okay. We\'ll build a new one with our own hands!”';

  @override
  String get story_prologue_4 =>
      'The Red Claw Patrol blockades the harbor under the excuse of a “pirate crackdown”. The first shard of the broken Heart glows on their flagship.';

  @override
  String get story_prologue_5 =>
      'Octo: “Let\'s recover all six shards and sail to Golden Isle!” First we break through the patrol blocking the harbor.';

  @override
  String get story_sea_1_intro_1 =>
      'Red Claw Patrol: Tropic Bay is our sea. This is a pirate crackdown, turn your ship around!';

  @override
  String get story_sea_1_intro_2 =>
      'Tok: The first shard is glowing on their flagship. Let\'s take down the patrol boats one by one and reach it.';

  @override
  String get story_s1_5_before =>
      'Crab Lieutenant: I\'ll give you credit for getting this far. But you\'ll never get through this iron bow!';

  @override
  String get story_s1_5_after =>
      'Crab Lieutenant: Argh… Retreat to the flagship! The captain won\'t let you get away with this!';

  @override
  String get story_s1_12_before_1 =>
      'Patrol captain: With the shard\'s power this cutter never stops. I\'ll close in and crush you.';

  @override
  String get story_s1_12_before_2 =>
      'Octo: Come closer, then. You\'ll get a taste of my bombs up close!';

  @override
  String get story_s1_12_after_1 =>
      'Patrol captain: The shard… lost its light. The fleet of Fog Strait will be waiting for you.';

  @override
  String get story_s1_12_after_2 =>
      'Tok: We got the first shard back! The Heart feels a little warmer.';

  @override
  String get story_s1_12_after_3 =>
      'Octo: Next is Fog Strait. The skeletons want to lift their curse with a shard?';

  @override
  String get tutorial_hint_1 =>
      'Tap a pirate card, then pull the pirate on deck backwards to fire';

  @override
  String get tutorial_hint_2 =>
      'Move with the ◀ ▶ buttons. You only go as far as your fuel allows';

  @override
  String get tutorial_hint_3 =>
      'Holes below the waterline mean flooding! Fire Tok at your own ship to repair';

  @override
  String get resultDoubleDone => 'Reward doubled';

  @override
  String get replaySave => 'Save replay';

  @override
  String get replaySaved => 'Replay saved';

  @override
  String statDamage(Object damage, Object blocks) {
    return 'Damage dealt $damage · blocks broken $blocks';
  }

  @override
  String statAccuracy(Object percent) {
    return 'Accuracy $percent%';
  }

  @override
  String get iapRemoveAds => 'Remove ads';

  @override
  String get iapBought => 'Purchased';

  @override
  String get iapBuy => 'Buy';

  @override
  String get devTestBattle => 'Test battle';

  @override
  String get devMyDeck => 'My crew';

  @override
  String get devEnemyDeck => 'Enemy crew';

  @override
  String get devRandomEnemy => 'Empty enemy crew = 4 random pirates';

  @override
  String get devStart => 'Start';

  @override
  String get storyReplay => 'Replay stories';

  @override
  String get storyReplayEmpty => 'No stories seen yet';

  @override
  String get storyTitlePrologue => 'Prologue';

  @override
  String get storyTitleSea1Intro => 'Sea 1 intro';

  @override
  String get storyTitleMidBossBefore => 'Before the mid-boss';

  @override
  String get storyTitleMidBossAfter => 'After the mid-boss';

  @override
  String get storyTitleBossBefore => 'Before the sea boss';

  @override
  String get storyTitleBossAfter => 'After the sea boss';

  @override
  String get prepMyShip => 'My ship';

  @override
  String get prepCabins => 'Cabins';

  @override
  String get prepCabinEmpty => 'Empty cabin';

  @override
  String get hitTagCrit => 'CRIT';

  @override
  String get hitTagPierce => 'PIERCE';

  @override
  String get hitTagChain => 'CHAIN';

  @override
  String get hitTagBurn => 'BURN';

  @override
  String get hitTagMine => 'MINE';

  @override
  String get hitTagBite => 'BITE';

  @override
  String get hitTagRepair => 'REPAIR';

  @override
  String aimAngle(String deg) {
    return '$deg°';
  }

  @override
  String aimPower(String pct) {
    return 'Power $pct%';
  }

  @override
  String get musicOn => 'Music';
}
