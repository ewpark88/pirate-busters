import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/audio/sound_service.dart';
import 'package:pirate_busters/battle/battle_session.dart';
import 'package:pirate_busters/game/battle_cues.dart';
import 'package:pirate_busters/game/coords.dart';
import 'package:pirate_busters/game/emotion_cues.dart';
import 'package:pirate_busters/game/hit_stop.dart';
import 'package:pirate_busters/game/start_gate.dart';
import 'package:pirate_busters/game/view/fx_layer.dart';
import 'package:pirate_busters/game/view/sea_shape.dart';
import 'package:pirate_busters/game/view/ship_view.dart';
import 'package:pirate_busters/game/view/water_fx.dart';

/// 전장 배너 종류 (설계서 §10.4 격침·마무리, §13.4 턴 전환).
enum BattleBannerKind {
  myTurn,
  foeTurn,
  storm,
  sunk,
  annihilation,
  timeDecision,
  draw,
}

/// 지금 띄울 배너와 몇 번째인지(같은 종류가 이어져도 다시 띄우게).
@immutable
class BattleBanner {
  const BattleBanner(this.kind, this.serial);

  final BattleBannerKind kind;
  final int serial;

  /// 판이 끝난 뒤의 배너인가.
  bool get isEnd => kind.index >= BattleBannerKind.sunk.index;
}

/// 판의 끝과 턴 사이 연출 (설계서 §10.4 격침·마무리, §13.4 턴 전환, A54).
///
/// - 격침: 진 배가 가라앉기 시작하면 물보라·격침음·슬로모, 다 가라앉으면 ‘격침!’
///   배너를 [endBannerSec] 동안 띄운 뒤 [settled] 를 켠다(결과 화면은 그 뒤).
/// - 전멸: 마지막 해적이 쓰러지는 순간 슬로모, 연출이 끝나면 ‘전멸!’ 배너.
/// - 시간 판정: 양쪽 침수량을 나란히 보여 주는 배너를 [timeBannerSec] 동안.
/// - 턴 전환: 턴이 바뀌면 [turnPauseSec] 동안 판 시계를 세우고 ‘내 턴!’ /
///   ‘상대 턴’ 배너, 폭풍 타임이 시작되면 ‘폭풍 타임!’.
///
/// 판정은 하지 않고 시뮬레이션이 낸 이벤트와 상태를 읽기만 한다 (절대 규칙 3).
class FinaleDirector {
  FinaleDirector({
    required this.session,
    required this.ships,
    required this.fx,
    required this.stop,
    required this.gate,
    required this.settled,
    required this.playSfx,
    required this.viewSide,
    required this.lowEnd,
    required this.banner,
    this.sound = const SilentSoundService(),
    this.soundOn,
    this.blastOf = BattleCues.blastRadius,
  }) {
    soundOn?.addListener(_ambience);
    _ambience();
  }

  final BattleSession session;
  final List<ShipView> ships;
  final FxLayer fx;
  final HitStop stop;
  final StartGate gate;
  final ValueNotifier<bool> settled;
  final void Function(Sfx sfx) playSfx;
  final int Function() viewSide;
  final ValueListenable<bool> lowEnd;

  /// 지금 배너. HUD 가 그린다.
  final ValueNotifier<BattleBanner?> banner;

  /// 판 끝 배너 동안 음악 줄이기(덕킹)와 바다·바람 환경음 (§10.3, A56).
  final SoundService sound;

  /// 효과음 설정. 환경음이 따른다. 없으면 켜진 것으로 본다.
  final ValueListenable<bool>? soundOn;

  void _ambience() => sound.ambience(on: soundOn?.value ?? true);

  /// 전장이 닫힐 때: 환경음을 멈춘다.
  void dispose() {
    soundOn?.removeListener(_ambience);
    sound.ambience(on: false);
  }

  /// 부서진 모듈 종류 번호의 유폭 반경(0 이면 터지지 않음). 유폭 진동에 쓴다.
  final int Function(int kindIndex) blastOf;

  /// 이동 물살 소리 간격(초): 버튼을 누르고 있는 동안 너무 자주 내지 않는다.
  static const double wakeGapSec = .45;
  double _clock = 0;
  double _lastWake = -1;

  static const double endBannerSec = 1.2;
  static const double timeBannerSec = 2.2;
  static const double turnPauseSec = 0.5;

  final Set<int> _sinkShown = {};
  int _serial = 0;
  double _endLeft = -1;

  void _show(BattleBannerKind kind) =>
      banner.value = BattleBanner(kind, ++_serial);

  /// 한 프레임. [dt] 는 실제 초, [cues] 는 이번 프레임에 재생된 이벤트.
  void update(double dt, List<SimEvent> cues) {
    _clock += dt;
    cues.forEach(_onCue);
    final state = session.state;
    if (!state.isOver) return;
    _watchSinking();
    if (settled.value) return;
    if (_endLeft >= 0) {
      _endLeft -= dt;
      if (_endLeft < 0) settled.value = true;
      return;
    }
    if (session.playback != null || !ships.every((s) => s.motion.settled)) {
      return;
    }
    final winner = state.winner;
    playSfx(winner >= 0 && winner == viewSide() ? Sfx.win : Sfx.lose);
    sound.duck(on: true);
    fx.buzz(long: true);
    final kind = endKindOf(state);
    if (kind == null) {
      settled.value = true;
      return;
    }
    _show(kind);
    _endLeft = kind == BattleBannerKind.timeDecision
        ? timeBannerSec
        : endBannerSec;
  }

  /// 판이 끝난 방식의 배너. 항복은 배너 없이 바로 결과로 간다.
  static BattleBannerKind? endKindOf(MatchState state) =>
      switch (state.outcome) {
        MatchOutcome.sunk || MatchOutcome.floodSunk => BattleBannerKind.sunk,
        MatchOutcome.annihilation => BattleBannerKind.annihilation,
        MatchOutcome.timeDecision when state.winner < 0 =>
          BattleBannerKind.draw,
        MatchOutcome.timeDecision => BattleBannerKind.timeDecision,
        _ => null,
      };

  void _onCue(SimEvent e) {
    final state = session.state;
    if (e.kind == SimEventKind.pirateDown &&
        state.outcome == MatchOutcome.annihilation) {
      // 전멸 마무리: 쓰러질 때마다 느리게, 마지막 한 명이 가장 늦게 풀린다.
      stop.slow(EmotionCues.slowFor(lowEnd: lowEnd.value));
    } else if (e.kind == SimEventKind.turnStart && !state.isOver) {
      gate.pause(turnPauseSec);
      playSfx(Sfx.turn);
      _show(
        session.humanSides.contains(e.side)
            ? BattleBannerKind.myTurn
            : BattleBannerKind.foeTurn,
      );
    } else if (e.kind == SimEventKind.stormStart && !state.isOver) {
      _show(BattleBannerKind.storm);
      playSfx(Sfx.rumble);
    } else {
      _onSoundCue(e);
    }
  }

  /// 소리·진동만 내는 이벤트 (설계서 §10.3·§10.4, A56).
  void _onSoundCue(SimEvent e) {
    final k = e.kind;
    if (k == SimEventKind.fire && session.humanSides.contains(e.side)) {
      fx.buzz();
    } else if (k == SimEventKind.flood && e.value > 0) {
      playSfx(Sfx.gurgle);
    } else if (k == SimEventKind.ignited) {
      playSfx(Sfx.crackle);
    } else if (k == SimEventKind.move && _clock - _lastWake >= wakeGapSec) {
      _lastWake = _clock;
      playSfx(Sfx.wake);
    } else if (k == SimEventKind.moduleDestroyed && blastOf(e.value) > 0) {
      fx.buzz(twice: true);
    }
  }

  /// 가라앉기 시작한 배: 큰 물보라·물안개와 격침음, 슬로모 (설계서 §10.3, §10.4).
  void _watchSinking() {
    for (final ship in ships) {
      if (ship.motion.sinking && _sinkShown.add(ship.side)) {
        fx.sinkSplash(
          Vector2(shipOnSea(ship).x, 0),
          session.state.sides[ship.side].grid.width * Coords.cell,
        );
        playSfx(Sfx.sink);
        stop.slow(EmotionCues.slowFor(lowEnd: lowEnd.value));
      }
    }
  }
}
