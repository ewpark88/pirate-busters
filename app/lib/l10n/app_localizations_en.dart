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
  String timeVerdict(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count turns to turn limit',
      one: '1 turn to turn limit',
    );
    return '$_temp0 · most crew HP wins';
  }

  @override
  String timeVerdictHp(String mine, String theirs) {
    return 'You $mine% : Foe $theirs%';
  }

  @override
  String get timeVerdictByHull => 'HP tied: cabin decides';

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
  String get firedDone => 'Fired';

  @override
  String get noPirateCanFire =>
      'No pirate can attack. Passing the turn to your opponent.';

  @override
  String get pirateReady => 'Ready!';

  @override
  String get pirateDown => 'Down';

  @override
  String get pirateBoarding => 'On enemy ship';

  @override
  String get wind => 'Wind';

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
  String get outcomeCaptainLost => 'Captain\'s cabin lost';

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
  String get emphasisBoom => 'KABOOM!';

  @override
  String get emphasisDoubleHit => 'Double hit!';

  @override
  String get emphasisCabin => 'Cabin hit!';

  @override
  String get bannerCaptainLost => 'Cabin down!';

  @override
  String get bannerMyTurn => 'Your turn!';

  @override
  String get bannerAnnihilation => 'Wiped out!';

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
  String get pirate_p07_desc => 'Focused 3-shot burst on one spot';

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
  String get pirate_p16_desc => 'Stone skips off the water into the lower hull';

  @override
  String get pirate_p16_lore =>
      'Skips stones with the same knack she uses to crack clams.';

  @override
  String get pirate_p21_name => 'Puffy the Blaster';

  @override
  String get pirate_p21_desc => 'Sticks under the hull, blows at my next turn';

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
  String get pirate_p28_desc => 'Drops 4 small bombs from the top';

  @override
  String get pirate_p28_lore =>
      'Nobody knows what\'s in her pouch until it drops.';

  @override
  String get pirate_p31_name => 'Sharky the Brawler';

  @override
  String get pirate_p31_desc =>
      'Leaps onto the enemy deck and bites nearby pirates';

  @override
  String get pirate_p31_lore =>
      'Nothing makes him happier than jumping aboard.';

  @override
  String get pirate_p36_name => 'Tok the Shipwright';

  @override
  String get pirate_p36_desc => 'Shell cannon shockwave pushes the ship 1 cell';

  @override
  String get pirate_p36_lore => 'Slow but careful. He keeps the ship afloat.';

  @override
  String get pirate_p02_name => 'Starry the Firestar';

  @override
  String get pirate_p02_desc => 'Spinning fire star bursts wide';

  @override
  String get pirate_p02_lore =>
      'Loves fireworks. Has burned three ships so far.';

  @override
  String get pirate_p03_name => 'Crab Brothers';

  @override
  String get pirate_p03_desc => 'Big claw bomb, bursts on impact';

  @override
  String get pirate_p03_lore =>
      'They argue nonstop, yet always aim at the same spot.';

  @override
  String get pirate_p05_name => 'Volke the Volcano Crab';

  @override
  String get pirate_p05_desc => '★ Sky-high lob, drills 2 layers then blows';

  @override
  String get pirate_p05_lore => 'The volcano on his back has never cooled.';

  @override
  String get pirate_p08_name => 'Bones the Sniper';

  @override
  String get pirate_p08_desc => 'Lightning-fast snipe, crits on pirates';

  @override
  String get pirate_p08_lore =>
      'When his eye sockets glow, it is already too late.';

  @override
  String get pirate_p09_name => 'Lion the Spinefish';

  @override
  String get pirate_p09_desc => 'Scatter burst, sprays wide';

  @override
  String get pirate_p09_lore => 'Every fin is a venomous spine cannon.';

  @override
  String get pirate_p10_name => 'Volt the Eel';

  @override
  String get pirate_p10_desc => 'Chain lightning jumps from the hit pirate';

  @override
  String get pirate_p10_lore => 'Gets even livelier in wet places.';

  @override
  String get pirate_p12_name => 'Nar the Narwhal';

  @override
  String get pirate_p12_desc => 'Horn spear pierces blocks';

  @override
  String get pirate_p12_lore =>
      'A quiet lancer who came down from the northern seas.';

  @override
  String get pirate_p13_name => 'Walrus the Anchorman';

  @override
  String get pirate_p13_desc => 'Heavy anchor pierces blocks';

  @override
  String get pirate_p13_lore =>
      'Likes pulling the anchor back more than throwing it.';

  @override
  String get pirate_p14_name => 'Saw the Sawshark';

  @override
  String get pirate_p14_desc => 'Saw nose pierces blocks';

  @override
  String get pirate_p14_lore => 'Its nose itches whenever it sees a mast.';

  @override
  String get pirate_p15_name => 'Moby the Whale';

  @override
  String get pirate_p15_desc => '★ Drags the enemy ship 3 cells on a hull hit';

  @override
  String get pirate_p15_lore =>
      'The strongest pull in the sea. Slow, but never lets go.';

  @override
  String get pirate_p17_name => 'Pingu the Slider';

  @override
  String get pirate_p17_desc => 'Belly-slides off the water into the hull';

  @override
  String get pirate_p17_lore => 'No ice? No problem. Pingu slides on anything.';

  @override
  String get pirate_p18_name => 'Sheldon the Horseshoe';

  @override
  String get pirate_p18_desc => 'Shell skips into the hull';

  @override
  String get pirate_p18_lore =>
      'A shell that survived 300 million years bounces off anything.';

  @override
  String get pirate_p19_name => 'Dolphy the Surfer';

  @override
  String get pirate_p19_desc => 'Surfs a wave into the hull';

  @override
  String get pirate_p19_lore => 'Has never stopped smiling on a wave.';

  @override
  String get pirate_p20_name => 'Orca the Tide';

  @override
  String get pirate_p20_desc =>
      '★ Big wave sweeps the deck and pushes the ship 2 cells';

  @override
  String get pirate_p20_lore => 'When Orca passes, the whole sea tilts.';

  @override
  String get pirate_p22_name => 'Jelly the Mine';

  @override
  String get pirate_p22_desc => 'Sticks under the hull, blows at my next turn';

  @override
  String get pirate_p22_lore =>
      'Nobody knows where she drifts. Not even Jelly.';

  @override
  String get pirate_p23_name => 'Bara the Torpedo';

  @override
  String get pirate_p23_desc =>
      'Straight torpedo that dives under the waterline';

  @override
  String get pirate_p23_lore => 'Once Bara picks a heading, it never turns.';

  @override
  String get pirate_p24_name => 'Moray the Eel';

  @override
  String get pirate_p24_desc => 'Sticks under the hull, blows at my next turn';

  @override
  String get pirate_p24_lore => 'Sees a gap, sticks its teeth in first.';

  @override
  String get pirate_p25_name => 'Kraki the Little Kraken';

  @override
  String get pirate_p25_desc =>
      '★ Blows on contact, tentacles smash nearby blocks for 2 turns';

  @override
  String get pirate_p25_lore => 'Just a baby, but already has three tentacles.';

  @override
  String get pirate_p29_name => 'Alba the Albatross';

  @override
  String get pirate_p29_desc => 'Curves toward the nearest pirate';

  @override
  String get pirate_p29_lore =>
      'The first bird to learn to fly against the wind.';

  @override
  String get pirate_p30_name => 'Manta the Storm Ray';

  @override
  String get pirate_p30_desc => '★ Hides the foe\'s aim line next turn';

  @override
  String get pirate_p30_lore => 'No path is left in the sky Manta crosses.';

  @override
  String get pirate_p32_name => 'Crabby the Roper';

  @override
  String get pirate_p32_desc =>
      'Swings over on a rope and bites nearby pirates';

  @override
  String get pirate_p32_lore => 'One big claw is all it takes.';

  @override
  String get pirate_p33_name => 'King the Shieldcrab';

  @override
  String get pirate_p33_desc => 'Jumps aboard and bites nearby pirates';

  @override
  String get pirate_p33_lore => 'Has never learned how to put the shield down.';

  @override
  String get pirate_p34_name => 'Lob the Twin-Claw';

  @override
  String get pirate_p34_desc => 'Spinning claws slash nearby pirates';

  @override
  String get pirate_p34_lore => 'Nobody has seen both claws at rest.';

  @override
  String get pirate_p35_name => 'Davy the Skull Captain';

  @override
  String get pirate_p35_desc => '★ Three skeleton crew bite along';

  @override
  String get pirate_p35_lore =>
      'A captain back from the deep. He will not sink twice.';

  @override
  String get pirate_p37_name => 'Pumpum the Baby Whale';

  @override
  String get pirate_p37_desc => 'Water-jet shockwave pushes the ship 1 cell';

  @override
  String get pirate_p37_lore => 'Proud of the spout from its blowhole.';

  @override
  String get pirate_p38_name => 'Cook the Hermit Crab';

  @override
  String get pirate_p38_desc => 'Pot-bomb shockwave pushes the ship 1 cell';

  @override
  String get pirate_p38_lore => 'Believes a hungry crew cannot fight.';

  @override
  String get pirate_p39_name => 'Corey the Coral Golem';

  @override
  String get pirate_p39_desc => 'Coral-chunk shockwave pushes the ship 1 cell';

  @override
  String get pirate_p39_lore =>
      'Grows slowly, but stands in front of anything.';

  @override
  String get pirate_p40_name => 'Lamp the Anglerfish';

  @override
  String get pirate_p40_desc => '★ Huge shockwave pushes the ship 2 cells';

  @override
  String get pirate_p40_lore =>
      'Has never lost the way, even in the darkest sea.';

  @override
  String get blueprint_balanced_name => 'Balanced';

  @override
  String get blueprint_balanced_desc =>
      'Oak keel with an iron-clad captain\'s cabin. Oak guards the bow, and a mast midship holds the crow\'s nest.';

  @override
  String get blueprint_armored_name => 'Ironclad';

  @override
  String get blueprint_armored_desc =>
      'Iron plates the bow for a tough front. The cabin roofs stay thin.';

  @override
  String get blueprint_fast_name => 'Swift';

  @override
  String get blueprint_fast_desc =>
      'A low ship that hides the captain\'s cabin in a mid oak deck. Fewer blocks, fewer points spent.';

  @override
  String ammoExplosive(int n) {
    return 'Blast $n%';
  }

  @override
  String ammoFire(int n) {
    return 'Fire r$n';
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
    return 'Mine r$n';
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
    return 'Raid r$n';
  }

  @override
  String ammoShock(int n) {
    return 'Push $n';
  }

  @override
  String get tapToSplit => 'Tap to split!';

  @override
  String get foeAiming => 'Enemy aiming';

  @override
  String get shotIncoming => 'Incoming!';

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
  String get toolCabin => 'Cabin';

  @override
  String get toolErase => 'Erase';

  @override
  String get toolTabMaterials => 'Materials';

  @override
  String get toolTabModules => 'Modules';

  @override
  String get toolTabMasts => 'Masts';

  @override
  String toolPoints(int n) {
    return '$n pt';
  }

  @override
  String get moduleMast => 'Pine mast';

  @override
  String get moduleCaptain => 'Captain';

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
  String get crewHint => 'Hold a pirate, then drag it into a cabin';

  @override
  String get deckFamilies => 'Types';

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
  String get familyShock => 'Shock';

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
  String mission_hull_above(Object percent) {
    return 'Win with hull at $percent% or more';
  }

  @override
  String mission_turns_within(Object turns) {
    return 'Win within $turns of your turns';
  }

  @override
  String get story_t1_enemy =>
      'Patrol recruit: The harbor is closed! Turn back, pirates!';

  @override
  String get story_t1_ally =>
      'Octo: Pirates? We were just fixing our boat… Fine, have a bomb!';

  @override
  String get story_t2_enemy =>
      'Patrol recruit: We\'ll keep our distance and fire! Catch us if you can!';

  @override
  String get story_t2_ally =>
      'Tok: The wind pushes your shots. Read it, then choose when to close in or fall back.';

  @override
  String get story_t3_enemy =>
      'Patrol diver: Good luck aiming on these rough waves!';

  @override
  String get story_t3_ally =>
      'Tok: Let\'s move to calm water. Our lookout hits hard, but falls if the mast breaks!';

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
      'Crab Lieutenant: See the iron bow? Half of every shot bounces right off!';

  @override
  String get story_s1_5_ally =>
      'Tok: If the front is hard, hit from above or below.';

  @override
  String get story_s1_6_enemy =>
      'Patrol shocker: One hammer blow and your ship drifts into rough water!';

  @override
  String get story_s1_6_ally =>
      'Tok: If we get pushed, we sail back to calm water. Fuel refills every turn.';

  @override
  String get story_s1_7_enemy =>
      'Patrol sniper: From the masthead I can see right into your cabins.';

  @override
  String get story_s1_7_ally =>
      'Octo: Bring down that lookout and the sniper falls with it. Aim for the mast!';

  @override
  String get story_s1_8_enemy =>
      'Crab bosun: The waves out here are wild. Good luck aiming!';

  @override
  String get story_s1_8_ally =>
      'Suri: When the ship rocks, release at the top where it pauses.';

  @override
  String get story_s1_9_enemy =>
      'Crab raiders: We\'ll leap onto your deck and finish you with our claws!';

  @override
  String get story_s1_9_ally =>
      'Pang: If they board, blast the planks they stand on. No footing, and into the sea they go!';

  @override
  String get story_s1_10_enemy =>
      'Patrol gull scout: The wind is on our side today. Your shots will all miss!';

  @override
  String get story_s1_10_ally =>
      'Polly: Watch which way the clouds drift. Ride the wind and fly farther!';

  @override
  String get story_s1_11_enemy =>
      'Patrol first mate: You won\'t reach the captain. I\'ll sink you all right here.';

  @override
  String get story_s1_11_ally =>
      'Octo: Wind, waves, lookout… let\'s use everything we learned. The first shard is close!';

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
  String get calmShakeOn => 'Reduce screen shake';

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
  String prepWeather(Object wind) {
    return 'Wind up to $wind';
  }

  @override
  String get prepWaves => 'Wave zones';

  @override
  String get prepWavesCalm => 'Calm sea';

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
  String get personality_shover => 'Shover';

  @override
  String get personality_rusher => 'Rusher';

  @override
  String resultMission(Object text) {
    return 'Mission: $text';
  }

  @override
  String resultInTurns(Object turns) {
    return 'Win within $turns of your turns';
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
      'Hold ◀ ▶ to sail as far as your fuel allows. The wind (arrow at the top) pushes your shots';

  @override
  String get tutorial_hint_3 =>
      'Rough wave zones rock your ship. Move to calm water and fire from the crow\'s nest for big hits';

  @override
  String get resultDoubleDone => 'Reward doubled';

  @override
  String get replaySave => 'Save replay';

  @override
  String get replaySaved => 'Replay saved';

  @override
  String statDamage(Object damage, Object blocks) {
    return 'Damage to pirates $damage · blocks broken $blocks';
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
  String get devPractice => 'Dummy practice';

  @override
  String get operatorMode => 'Operator mode';

  @override
  String get operatorEnter => 'Enter operator mode';

  @override
  String get operatorExit => 'Back to player mode';

  @override
  String get operatorPassword => 'Password';

  @override
  String get operatorWrongPassword => 'Wrong password';

  @override
  String get operatorOn => 'Operator mode on';

  @override
  String get operatorOff => 'Back in player mode';

  @override
  String get operatorRevealed => 'Operator button unlocked';

  @override
  String get operatorStages => 'Stages (all open)';

  @override
  String get operatorPirates => 'Pirates';

  @override
  String get operatorShip => 'Ship';

  @override
  String get operatorProgress => 'Progress (changes your save)';

  @override
  String get operatorMotions => 'Pirate motions';

  @override
  String get operatorShipMax => 'Max out ship';

  @override
  String operatorGold(String gold) {
    return 'Gold +$gold';
  }

  @override
  String get operatorLevelMax => 'Max player level';

  @override
  String get operatorAllPirates => 'Get all pirates';

  @override
  String get operatorReset => 'Reset progress';

  @override
  String get operatorResetAsk =>
      'Erase all progress (stars, gold, pirates, ship)?';

  @override
  String get operatorDone => 'Done';

  @override
  String get motionIdle => 'Idle';

  @override
  String get motionAttack => 'Attack';

  @override
  String get motionHit => 'Hit';

  @override
  String get motionAim => 'Aim';

  @override
  String get motionFall => 'Fall';

  @override
  String get motionSwim => 'Swim';

  @override
  String get motionWin => 'Win';

  @override
  String get motionLose => 'Lose';

  @override
  String get motionTeamBlue => 'Blue';

  @override
  String get motionTeamRed => 'Red';

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
  String get hitTagMine => 'MINE';

  @override
  String get hitTagMineBlast => 'MINE BLAST!';

  @override
  String get hitTagBite => 'BITE';

  @override
  String get hitTagBoarded => 'BOARDED!';

  @override
  String get hitTagRepel => 'REPEL!';

  @override
  String get hitTagShakenOff => 'SHAKEN OFF!';

  @override
  String get hitTagPull => 'PULLED';

  @override
  String get hitTagBlind => 'BLINDED';

  @override
  String get windCalm => 'Calm';

  @override
  String windSemantics(String direction, int level) {
    return 'Wind $direction, level $level';
  }

  @override
  String get windLeft => 'left';

  @override
  String get windRight => 'right';

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

  @override
  String buyAsk(Object name, Object gold) {
    return 'Spend $gold gold on $name?';
  }

  @override
  String get notEnoughGold => 'Not enough gold';

  @override
  String get buy => 'Buy';

  @override
  String get ok => 'OK';

  @override
  String crewHpPercent(int percent) {
    return 'Crew HP $percent%';
  }

  @override
  String captainPercent(int percent) {
    return 'Cabin $percent%';
  }

  @override
  String crewNestHint(int seat) {
    return 'Seat $seat is the crow\'s nest: hits harder, but falls overboard (KO) if the mast breaks';
  }

  @override
  String get prepNest => 'Crow\'s nest';

  @override
  String fuelPercent(int percent) {
    return '$percent%';
  }

  @override
  String get bossBanner => 'Boss!';

  @override
  String get barkFire1 => 'Take that!';

  @override
  String get barkFire2 => 'Right on target!';

  @override
  String get barkFire3 => 'One more coming!';

  @override
  String get barkFire4 => 'Cannonball delivery!';

  @override
  String get barkHurt1 => 'Ouch, that stings!';

  @override
  String get barkHurt2 => 'Barely a scratch!';

  @override
  String get barkHurt3 => 'The ship\'s rocking!';

  @override
  String get barkHurt4 => 'You\'ll pay for that!';

  @override
  String get barkAllyDown1 => 'Crew down! Hold on!';

  @override
  String get barkAllyDown2 => 'I\'ll fight for both of us!';

  @override
  String get barkAllyDown3 => 'Hang in there, we\'ll finish fast!';

  @override
  String get barkAllyDown4 => 'Now I\'m angry!';

  @override
  String get barkTauntStart1 => 'Pirate patrol! Surrender!';

  @override
  String get barkTauntStart2 => 'You call that a ship?';

  @override
  String get barkTauntStart3 => 'Nothing gets past the patrol!';

  @override
  String get barkTauntStart4 => 'Taste the claw!';

  @override
  String get barkTauntLow1 => 'Th-this can\'t be!';

  @override
  String get barkTauntLow2 => 'We\'re leaking! Man the pumps!';

  @override
  String get barkTauntLow3 => 'Not bad… but not done yet!';

  @override
  String get barkTauntLow4 => 'No retreat, hold the line!';

  @override
  String get goalTitle => 'Next goal';

  @override
  String get goalGo => 'Go';

  @override
  String goalStars(Object have, Object total) {
    return 'Stars $have / $total';
  }

  @override
  String get goalAllClear => 'Every stage here is cleared!';

  @override
  String get emphasisMast => 'Mast down!';

  @override
  String get crewFilterRarity => 'Rarity';

  @override
  String get crewFilterFamily => 'Type';

  @override
  String get crewFilterAmmo => 'Shot';

  @override
  String get crewFilterReset => 'Reset';

  @override
  String crewFilterCount(int shown, int total) {
    return '$shown/$total';
  }

  @override
  String get crewFilterEmpty => 'No pirates match';

  @override
  String get ammoKindExplosive => 'Blast';

  @override
  String get ammoKindFire => 'Fire';

  @override
  String get ammoKindSplit => 'Split';

  @override
  String get ammoKindBurst => 'Burst';

  @override
  String get ammoKindSniper => 'Sniper';

  @override
  String get ammoKindChain => 'Chain';

  @override
  String get ammoKindPierce => 'Pierce';

  @override
  String get ammoKindSkip => 'Skip';

  @override
  String get ammoKindMine => 'Mine';

  @override
  String get ammoKindFlock => 'Drop';

  @override
  String get ammoKindHoming => 'Homing';

  @override
  String get ammoKindAssault => 'Assault';

  @override
  String get ammoKindShock => 'Shock shot';

  @override
  String pirateCost(int n) {
    return 'Cost $n';
  }

  @override
  String pirateHp(int n) {
    return 'HP $n';
  }

  @override
  String get pirateBoard => 'Board';

  @override
  String get pirateUnboard => 'Unboard';

  @override
  String get pirateClose => 'Close';
}
