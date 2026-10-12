import 'dart:async';

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pirate_busters/audio/sound_service.dart';
import 'package:pirate_busters/battle/battle_session.dart';
import 'package:pirate_busters/battle/session_views.dart';

/// 남은 5초 째깍 (설계서 §2.3 “5초부터 카운트다운”, §13.4, A34): 내 턴이 5·4·3·2·1
/// 초로 넘어갈 때마다 째깍 소리와 가벼운 진동(진동 설정을 따른다)을 한 번씩 낸다.
/// 탄 연출로 타이머가 멈춘 동안이나 상대 턴에는 내지 않는다.
class CountdownCue extends Component {
  CountdownCue({required this.session, required this.play, this.vibration});

  final BattleSession session;
  final void Function(Sfx sfx) play;
  final ValueListenable<bool>? vibration;

  /// 째깍을 내기 시작하는 남은 초.
  static const int from = 5;

  int? _last;

  /// 이번에 째깍을 낼 초. 같은 초를 두 번 내지 않는다. 낼 것이 없으면 null.
  @visibleForTesting
  static int? due(
    int remainingMs,
    int? last, {
    required bool myTurn,
    required bool running,
  }) {
    if (!myTurn || !running) return null;
    final s = (remainingMs + 999) ~/ 1000;
    if (s < 1 || s > from || s == last) return null;
    return s;
  }

  @override
  void update(double dt) {
    final s = due(
      session.remainingMs,
      _last,
      myTurn: session.isHumanTurn && !session.isOver,
      running: session.playback == null,
    );
    if (!session.isHumanTurn) _last = null;
    if (s == null) return;
    _last = s;
    play(Sfx.tick);
    if (vibration?.value ?? true) unawaited(HapticFeedback.selectionClick());
  }
}
