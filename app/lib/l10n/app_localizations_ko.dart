// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'Pirate Busters';

  @override
  String turnsLeft(int count) {
    return '남은 턴 $count';
  }

  @override
  String get yourTurn => '내 턴';

  @override
  String get enemyTurn => '상대 턴';

  @override
  String playerTurn(int side) {
    return '플레이어 $side 턴';
  }

  @override
  String get hull => '선체';

  @override
  String flood(String percent) {
    return '침수 $percent%';
  }

  @override
  String crewAlive(int alive, int total) {
    return '선원 $alive/$total';
  }

  @override
  String get endTurn => '턴 종료';

  @override
  String get retreat => '후퇴';

  @override
  String get advance => '전진';

  @override
  String get fuel => '연료';

  @override
  String firesLeft(int count) {
    return '남은 발사 $count';
  }

  @override
  String cooldown(int count) {
    return '쉬는 턴 $count';
  }

  @override
  String get cabinFlooded => '잠김';

  @override
  String get pirateDown => '쓰러짐';

  @override
  String get pirateSwimming => '헤엄 중';

  @override
  String get wind => '바람';

  @override
  String get stormTime => '폭풍 타임!';

  @override
  String get overview => '전체 보기';

  @override
  String gapCells(int cells) {
    return '간격 $cells칸';
  }

  @override
  String get pause => '일시정지';

  @override
  String get resume => '계속하기';

  @override
  String get surrender => '항복';

  @override
  String get surrenderConfirm => '이번 해전을 포기할까요?';

  @override
  String get cancel => '취소';

  @override
  String get settings => '설정';

  @override
  String get language => '언어';

  @override
  String get languageSystem => '시스템 설정';

  @override
  String get languageKorean => '한국어';

  @override
  String get languageEnglish => 'English';

  @override
  String get opponent => '상대';

  @override
  String get opponentDummy => '허수아비';

  @override
  String get opponentHotseat => '두 사람 (한 기기)';

  @override
  String get resultWin => '승리!';

  @override
  String get resultLose => '패배';

  @override
  String get resultDraw => '무승부';

  @override
  String get outcomeSunk => '격침';

  @override
  String get outcomeFloodSunk => '침몰';

  @override
  String get outcomeAnnihilation => '전멸';

  @override
  String get outcomeTimeDecision => '시간 판정';

  @override
  String get outcomeSurrender => '항복';

  @override
  String get playAgain => '다시 하기';

  @override
  String playerWins(int side) {
    return '플레이어 $side 승리!';
  }

  @override
  String get lowEndMode => '저사양 모드';

  @override
  String damagePopup(String amount) {
    return '-$amount';
  }

  @override
  String get sunkBanner => '격침!';

  @override
  String get surrenderQueued => '내 턴이 오면 항복합니다';
}
