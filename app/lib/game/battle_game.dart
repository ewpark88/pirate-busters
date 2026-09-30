import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/audio/sound_service.dart';
import 'package:pirate_busters/battle/battle_session.dart';
import 'package:pirate_busters/battle/playback.dart';
import 'package:pirate_busters/game/anim/anim_data.dart';
import 'package:pirate_busters/game/camera_director.dart';
import 'package:pirate_busters/game/coords.dart';
import 'package:pirate_busters/game/sprites.dart';
import 'package:pirate_busters/game/view/fx_layer.dart';
import 'package:pirate_busters/game/view/sea_theme.dart';
import 'package:pirate_busters/game/view/sea_view.dart';
import 'package:pirate_busters/game/view/ship_view.dart';
import 'package:pirate_busters/game/view/shot_view.dart';

/// 전장 (개발 계획서 M4). 매 프레임 [BattleSession] 을 진행하고 결과를 그린다.
/// 판정은 하지 않는다 (CLAUDE.md 절대 규칙 3).
class BattleGame extends FlameGame {
  BattleGame(this.session, {this.sound = const SilentSoundService()});

  final BattleSession session;

  /// 코드 합성 효과음 (설계서 §10.3).
  final SoundService sound;
  final CameraDirector director = CameraDirector();

  /// ‘전체 보기’ (설계서 §2.1). HUD 버튼이 바꾼다.
  final ValueNotifier<bool> overview = ValueNotifier(false);

  /// 피해 숫자 글자. 화면이 l10n·NumberFormat 으로 바꿔 넣는다 (설계서 §14.2).
  String Function(int amount) damageText = (amount) => '$amount';

  /// 저사양 모드: 바다 굴절 셰이더를 끈다 (설계서 §10.2).
  final ValueNotifier<bool> lowEnd = ValueNotifier(false);

  static const String seaShaderAsset = 'shaders/sea_refraction.frag';

  late final List<ShipView> _ships;
  late final ShotView _shot;
  late final FxLayer _fx;
  double _pinchStart = 1;

  /// 사람이 보는 진영(허수아비전은 0, 핫시트는 지금 턴 진영).
  int get viewSide =>
      session.humanSides.length == 2 ? session.state.activeSide : 0;

  @override
  Future<void> onLoad() async {
    final sprites = await BattleSprites.load(images);
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
    camera.backdrop.add(SkyBackdrop(theme));
    _ships = [
      for (final side in const [0, 1])
        ShipView(session: session, side: side, sprites: sprites, anims: anims),
    ];
    _shot = ShotView(session: session, sprites: sprites, priority: 20);
    _fx = FxLayer(sprites: sprites, priority: 30);
    await world.addAll([
      ParallaxScenery(theme: theme, factor: 0.15, seed: 1, priority: -30),
      ParallaxScenery(theme: theme, factor: 0.4, seed: 2, priority: -20),
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
      _fx,
    ]);
    overview.addListener(() => director.overview = overview.value);
  }

  @override
  void update(double dt) {
    session.update((dt * 1000).round().clamp(0, 100));
    _dispatch(session.takeCues());
    _updateCamera(dt);
    super.update(dt);
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
      ..zoom = size.x / director.width;
  }

  Vector2 _cellWorld(int side, int cell) {
    final s = session.state.sides[side];
    final (x, y) = s.frame.cellCenter(
      cell % s.grid.width,
      cell ~/ s.grid.width,
    );
    return Coords.point(x, y);
  }

  void _dispatch(List<SimEvent> cues) {
    var woodPlayed = false;
    for (final e in cues) {
      switch (e.kind) {
        case SimEventKind.fire:
          _ships[e.side].playAttack(e.slot);
          sound.play(Sfx.cannon);
        case SimEventKind.impact:
          final at = Coords.point(e.x, e.y);
          _fx.explosion(at);
          director.impact(at);
          sound.play(
            _ships[e.side].isIron(e.cell) ? Sfx.clang : Sfx.cannon,
            volume: 0.8,
          );
        case SimEventKind.splash:
          final at = Coords.point(e.x, 0);
          _fx.splash(at);
          director.impact(at);
          sound.play(Sfx.splash);
        case SimEventKind.blockDestroyed:
          _fx.blockBroken(_cellWorld(e.side, e.cell));
          if (!woodPlayed) sound.play(Sfx.wood);
          woodPlayed = true;
        case SimEventKind.blockCollapsed:
          _fx.collapsed(_cellWorld(e.side, e.cell));
        case SimEventKind.move:
          // 한계선에 닿으면 물살이 튄다 (설계서 §2.6).
          final side = session.state.sides[e.side];
          final (lo, hi) = moveLimits(session.state.rules, session.state.turn);
          if (side.offset == lo || side.offset == hi) {
            _fx.splash(Coords.point(e.x, 0));
          }
        case SimEventKind.bounce:
          _fx.splash(Coords.point(e.x, 0));
          sound.play(Sfx.splash, volume: 0.6);
        case SimEventKind.pirateHit:
          _ships[e.side].playHit(e.slot);
          final rig = e.slot >= 0 && e.slot < _ships[e.side].rigs.length
              ? _ships[e.side].rigs[e.slot]
              : null;
          if (rig != null) {
            _fx.damageNumber(
              rig.absolutePosition - Vector2(0, 40),
              damageText(e.value),
            );
          }
        case SimEventKind.turnStart ||
            SimEventKind.turnEnd ||
            SimEventKind.pirateFell ||
            SimEventKind.pirateReturned ||
            SimEventKind.pirateDown ||
            SimEventKind.flood ||
            SimEventKind.stormStart ||
            // 분열·설치·수리·턴 효과 연출은 M5 앱 단계에서 붙인다.
            SimEventKind.divide ||
            SimEventKind.mineAttached ||
            SimEventKind.repaired ||
            SimEventKind.effectFired:
          break;
      }
    }
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
      // 발 위치에서 몸 가운데(약 0.8칸 위)를 잡는다.
      final body = ship.rigs[slot].absolutePosition - Vector2(0, 26);
      final d = body.distanceToSquared(world);
      if (d < bestDist) {
        bestDist = d;
        best = slot;
      }
    }
    return best;
  }
}
