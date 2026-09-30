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
    return '$count turns left';
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
    return '$count shots left';
  }

  @override
  String cooldown(int count) {
    return 'Rest $count';
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
}
