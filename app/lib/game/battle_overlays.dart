import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:pirate_busters/audio/sound_service.dart';
import 'package:pirate_busters/battle/battle_session.dart';
import 'package:pirate_busters/game/countdown_cue.dart';
import 'package:pirate_busters/game/view/boarder_view.dart';
import 'package:pirate_busters/game/view/foe_aim_mark.dart';
import 'package:pirate_busters/game/view/last_impact_mark.dart';
import 'package:pirate_busters/game/view/ship_view.dart';
import 'package:pirate_busters/game/view/wind_streaks.dart';

/// 전장에 겹치는 읽기 도우미 부품 (설계서 §2.3, §10.2, §13.4): 상대가 조준하는
/// 해적 강조·남은 5초 째깍·진동(A34), 하늘의 바람 줄(A35), 직전 착탄 표시(A37).
List<Component> battleOverlays(
  BattleSession session,
  List<ShipView> ships,
  void Function(Sfx sfx) play,
  ValueListenable<bool>? vibration,
  ValueListenable<bool>? lowEnd,
) => [
  FoeAimMark(session: session, ships: ships, priority: 26),
  CountdownCue(session: session, play: play, vibration: vibration),
  WindStreaks(session: session, lowEnd: lowEnd, priority: -20),
  LastImpactMark(session: session, priority: 15),
  // 적 배 위에 선 강습 해적 (설계서 §2.3, ADR-110). 배(0)와 앞 바다(10) 사이.
  BoarderView(session: session, ships: ships, priority: 5),
];
