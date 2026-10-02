import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/audio/sound_service.dart';
import 'package:pirate_busters/battle/battle_session.dart';
import 'package:pirate_busters/battle/battle_stats.dart';
import 'package:pirate_busters/battle/playback.dart';
import 'package:pirate_busters/game/anim/anim_data.dart';
import 'package:pirate_busters/game/battle_cues.dart';
import 'package:pirate_busters/game/camera_director.dart';
import 'package:pirate_busters/game/coords.dart';
import 'package:pirate_busters/game/hit_tag.dart';
import 'package:pirate_busters/game/sprites.dart';
import 'package:pirate_busters/game/view/backdrop_view.dart';
import 'package:pirate_busters/game/view/effect_badges.dart';
import 'package:pirate_busters/game/view/fx_layer.dart';
import 'package:pirate_busters/game/view/sea_theme.dart';
import 'package:pirate_busters/game/view/sea_view.dart';
import 'package:pirate_busters/game/view/ship_view.dart';
import 'package:pirate_busters/game/view/shot_view.dart';
import 'package:pirate_busters/game/view/water_fx.dart';
import 'package:pirate_busters/game/weapon_styles.dart';

/// 전장 (개발 계획서 M4). 매 프레임 [BattleSession] 을 진행하고 결과를 그린다.
/// 판정은 하지 않는다 (CLAUDE.md 절대 규칙 3).
class BattleGame extends FlameGame {
  BattleGame(this.session, {this.sound = const SilentSoundService()});

  final BattleSession session;

  /// 코드 합성 효과음 (설계서 §10.3).
  final SoundService sound;
  final CameraDirector director = CameraDirector();

  /// 전투 통계 (설계서 §13.5). 렌더 이벤트를 세기만 한다.
  final BattleStats stats = BattleStats();

  /// 턴이 끝날 때(분석 이벤트용). 판정과 무관하다.
  void Function(SimEvent e)? onTurnEnd;

  /// ‘전체 보기’ (설계서 §2.1). HUD 버튼이 바꾼다.
  final ValueNotifier<bool> overview = ValueNotifier(false);

  /// 피해 숫자 글자. 화면이 l10n·NumberFormat 으로 바꿔 넣는다 (설계서 §14.2).
  String Function(int amount) damageText = (amount) => '$amount';

  /// 명중 이름표와 남은 턴 수 글자 (설계서 §10.4). 화면이 l10n 으로 바꿔 넣는다.
  String Function(HitTag tag) tagText = (tag) => tag.name;
  String Function(int turns) turnsText = (turns) => '$turns';

  /// 조준 각도·힘 글자 (설계서 §10.4). 화면이 l10n 으로 바꿔 넣는다.
  String Function(int degrees) aimAngleText = (d) => '$d°';
  String Function(int percent) aimPowerText = (p) => '$p%';

  /// 판이 끝난 뒤 연출(격침)까지 끝났다. 결과 창은 이것을 기다린다 (설계서 §10.4).
  final ValueNotifier<bool> settled = ValueNotifier(false);
  final Set<int> _sinkShown = {};
  bool _endPlayed = false;

  /// 저사양 모드: 바다 굴절 셰이더를 끈다 (설계서 §10.2).
  final ValueNotifier<bool> lowEnd = ValueNotifier(false);

  /// 설정의 효과음·진동 (설계서 §13.8). 화면이 설정 값을 넣는다.
  final ValueNotifier<bool> soundOn = ValueNotifier(true);
  final ValueNotifier<bool> vibrationOn = ValueNotifier(true);

  static const String seaShaderAsset = 'shaders/sea_refraction.frag';

  late final List<ShipView> _ships;
  late final ShotView _shot;
  late final FxLayer _fx;
  late final BattleCues _cues;
  double _pinchStart = 1;

  /// 사람이 보는 진영(AI 전은 0, 핫시트는 지금 턴 진영).
  int get viewSide =>
      session.humanSides.length == 2 ? session.state.activeSide : 0;

  @override
  Future<void> onLoad() async {
    final sprites = await BattleSprites.load(images);
    final weapons = await WeaponStyles.load(images, rootBundle);
    final anims = PbAnims.fromJsonString(
      await rootBundle.loadString(PbAnims.path),
    );
    FragmentShader? seaShader;
    try {
      seaShader = (await FragmentProgram.fromAsset(
        seaShaderAsset,
      )).fragmentShader();
    } on Object catch (e) {
      // 셰이더를 못 쓰는 기기는 그라데이션 바다로 그린다.
      debugPrint('바다 셰이더 없음: $e');
    }
    // 해역 1 일반 모드: 맑은 낮 (설계서 §10.2). 해역·모드 톤은 R3.
    const theme = SeaTheme.tropicalDay;
    final backdrop = await BackdropView.load(
      images,
      rootBundle,
      lowEnd: lowEnd,
      priority: -30,
    );
    _ships = [
      for (final side in const [0, 1])
        ShipView(session: session, side: side, sprites: sprites, anims: anims),
    ];
    _shot =
        ShotView(
            session: session,
            sprites: sprites,
            weapons: weapons,
            rarity: anims.rarity,
            priority: 20,
          )
          ..angleText = ((d) => aimAngleText(d))
          ..powerText = ((p) => aimPowerText(p));
    _fx = FxLayer(
      sprites: sprites,
      lowEnd: lowEnd,
      vibration: vibrationOn,
      priority: 30,
    );
    await world.addAll([
      backdrop,
      SeaView(front: false, theme: theme, swell: _swell, priority: -10),
      ..._ships,
      SeaView(
        front: true,
        theme: theme,
        swell: _swell,
        shader: seaShader,
        lowEnd: lowEnd,
        priority: 10,
      ),
      _shot,
      LeakBubbles(
        session: session,
        fx: _fx,
        cellWorld: (side, cell) => _cues.cellWorld(side, cell),
      ),
      EffectBadges(session: session, weapons: weapons, priority: 25)
        ..turnsText = (turns) => turnsText(turns),
      _fx,
    ]);
    _cues = BattleCues(
      session: session,
      ships: _ships,
      fx: _fx,
      director: director,
      rarity: anims.rarity,
      weapons: weapons,
      playSfx: playSfx,
      damageText: (amount) => damageText(amount),
      tagText: (tag) => tagText(tag),
    );
    overview.addListener(() => director.overview = overview.value);
    // 저사양 모드에서는 등급 고리의 입자와 외곽 빛을 줄인다 (설계서 §12).
    void applyLowEnd() {
      _shot.fewer = lowEnd.value;
      for (final ship in _ships) {
        for (final rig in ship.rigs) {
          rig.fewer = lowEnd.value;
        }
      }
    }

    lowEnd.addListener(applyLowEnd);
    applyLowEnd();
  }

  @override
  void update(double dt) {
    session.update((dt * 1000).round().clamp(0, 100));
    final cues = session.takeCues();
    for (final e in cues) {
      stats.record(e);
      if (e.kind == SimEventKind.turnEnd) onTurnEnd?.call(e);
    }
    _cues.dispatch(cues);
    _watchEnd();
    // 명중 순간 0.07초는 연출만 멈춘다. 시뮬레이션은 위에서 이미 진행했다 (§10.4).
    final visual = _cues.stop.visualDt(dt);
    _updateCamera(visual);
    super.update(visual);
  }

  /// 판이 끝난 뒤: 가라앉기 시작한 배에 큰 물보라·물안개와 격침음, 다 가라앉으면
  /// 승리·패배 악구를 내고 [settled] 를 켠다 (설계서 §10.3, §10.4).
  void _watchEnd() {
    if (!session.state.isOver) return;
    for (final ship in _ships) {
      if (ship.motion.sinking && _sinkShown.add(ship.side)) {
        _fx.sinkSplash(
          Vector2(_shipCenterX(ship.side), 0),
          session.state.sides[ship.side].grid.width * Coords.cell,
        );
        playSfx(Sfx.sink);
      }
    }
    if (session.playback != null || !_ships.every((s) => s.motion.settled)) {
      return;
    }
    if (!_endPlayed) {
      _endPlayed = true;
      final winner = session.state.winner;
      playSfx(winner >= 0 && winner == viewSide ? Sfx.win : Sfx.lose);
    }
    settled.value = true;
  }

  /// 수면 높이(월드 px): 두 배의 파도 위아래 사이를 잇는다. 배와 물이 함께 오르내린다.
  double _swell(double x) {
    final x0 = _shipCenterX(0);
    final x1 = _shipCenterX(1);
    final h0 = Coords.y(_ships[0].heave);
    final h1 = Coords.y(_ships[1].heave);
    final t = ((x - x0) / (x1 - x0)).clamp(0.0, 1.0);
    return h0 + (h1 - h0) * t;
  }

  double _shipCenterX(int side) =>
      Coords.x(_ships[side].bowX) -
      facingOf(side) * session.state.sides[side].grid.width * Coords.cell / 2;

  void _updateCamera(double dt) {
    final me = viewSide;
    final aim = session.aim;
    final shot = session.playback;
    // 카드로 고른 해적이 있으면 그 해적으로 줌인 (설계서 §2.2, ADR-033).
    final focus = session.focusSlot;
    director.focusFeet = focus != null && focus < _ships[me].rigs.length
        ? _ships[me].rigs[focus].absolutePosition
        : null;
    final goal = director.target(
      myX: _shipCenterX(me),
      enemyX: _shipCenterX(1 - me),
      facing: facingOf(me),
      projectile: _shot.projectile,
      targetX: shot is ShotPlayback ? _shipCenterX(1 - shot.side) : null,
      aimStretch: aim?.stretch ?? 0,
      holdImpact: shot is ShotPlayback && shot.landed && !shot.isDone,
      aspect: size.x > 0 ? size.y / size.x : 0.46,
    );
    director.update(dt, goal);
    final shake = _fx.shake;
    camera.viewfinder
      ..position =
          director.center +
          Vector2(
            shake * ((session.turnMs ~/ 16).isEven ? 1 : -1),
            shake * 0.5,
          )
      ..zoom = size.x / (director.width * director.punchScale);
  }

  /// 효과음. 설정의 효과음을 끄면 내지 않는다 (설계서 §13.8). HUD 버튼 소리도 쓴다.
  void playSfx(Sfx sfx, {double volume = 1}) {
    if (soundOn.value) sound.play(sfx, volume: volume);
  }

  /// 핀치 줌 시작·진행 (설계서 §2.1). 화면이 제스처를 넘긴다.
  void pinchStart() => _pinchStart = director.userZoom;

  void pinchUpdate(double scale) => director.setUserZoom(_pinchStart * scale);

  /// 비행 중 탭 → `TAP` (설계서 §2.2).
  void tap() => session.tap();

  /// 화면 좌표 [screen] 에 있는 사람 쪽 해적 슬롯. 배 위 캐릭터를 끌어 조준한다
  /// (설계서 §2.2 “배 위 캐릭터”). 없으면 null.
  int? pirateAt(Vector2 screen) {
    final world = camera.globalToLocal(screen);
    final ship = _ships[viewSide];
    int? best;
    var bestDist = 30.0 * 30.0;
    for (var slot = 0; slot < ship.rigs.length; slot++) {
      // 발 위치에서 몸 가운데(키의 절반 위)를 잡는다.
      final body =
          ship.rigs[slot].absolutePosition -
          Vector2(0, Coords.pirateHeight / 2);
      final d = body.distanceToSquared(world);
      if (d < bestDist) {
        bestDist = d;
        best = slot;
      }
    }
    return best;
  }
}
