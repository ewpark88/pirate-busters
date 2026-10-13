import 'package:flame/components.dart';
import 'package:pirate_busters/audio/sound_service.dart';
import 'package:pirate_busters/battle/battle_session.dart';

/// 바람 소리 지휘 (설계서 §2.4 “바람이 셀수록 바람 소리가 커진다”, §10.3): 턴이 바뀌어
/// 바람이 바뀌면 소리 서비스에 새 단계를 알린다. 판이 끝나면 0 이다. 효과음 설정은 환경음 켜기·끄기(`FinaleDirector`)를 따른다.
class WindSound extends Component {
  WindSound({required this.session, required this.sound});

  final BattleSession session;
  final SoundService sound;
  int? _told;

  @override
  void update(double dt) {
    final wind = session.state.isOver ? 0 : session.state.wind;
    if (wind == _told) return;
    _told = wind;
    sound.windLevel(wind);
  }
}
