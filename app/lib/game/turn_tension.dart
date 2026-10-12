import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:pirate_busters/audio/sound_service.dart';
import 'package:pirate_busters/battle/battle_session.dart';
import 'package:pirate_busters/game/countdown_cue.dart';
import 'package:pirate_busters/game/view/foe_aim_mark.dart';
import 'package:pirate_busters/game/view/ship_view.dart';

/// 상대 턴 읽기와 남은 5초 긴장감의 월드 쪽 부품 (설계서 §2.3, §13.4, A34):
/// 상대가 조준하는 해적 강조와 남은 5초 째깍·진동.
List<Component> turnTension(
  BattleSession session,
  List<ShipView> ships,
  void Function(Sfx sfx) play,
  ValueListenable<bool>? vibration,
) => [
  FoeAimMark(session: session, ships: ships, priority: 26),
  CountdownCue(session: session, play: play, vibration: vibration),
];
