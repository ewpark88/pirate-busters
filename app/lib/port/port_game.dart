import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pirate_busters/battle/battle_session.dart';
import 'package:pirate_busters/game/anim/anim_data.dart';
import 'package:pirate_busters/game/coords.dart';
import 'package:pirate_busters/game/sprites.dart';
import 'package:pirate_busters/game/view/backdrop_view.dart';
import 'package:pirate_busters/game/view/sea_theme.dart';
import 'package:pirate_busters/game/view/sea_view.dart';
import 'package:pirate_busters/game/view/ship_view.dart';

/// 항구 배경 (설계서 §13.2): 내 대표 설계도 배가 물 위에 떠 있고 선실의 해적이 대기 동작을
/// 한다. 전장과 같은 배·바다 그리기를 쓰고, 판은 진행하지 않는다(파도 시계만 흐른다).
class PortGame extends FlameGame {
  PortGame(this.session, {this.lowEnd});

  /// 내 배(진영 0)만 그리는 정지된 판.
  final BattleSession session;

  /// 저사양 모드: 배경 구름·안개·빛 겹을 뺀다 (설계서 §12).
  final ValueListenable<bool>? lowEnd;

  /// 화면에 보이는 월드 폭(px). 배 한 척이 크게 보이는 정도.
  static const double viewWidth = 620;

  late final ShipView _ship;

  @override
  Future<void> onLoad() async {
    final sprites = await BattleSprites.load(images);
    final anims = PbAnims.fromJsonString(
      await rootBundle.loadString(PbAnims.path),
    );
    // 항구 배경은 내 티어의 해역이다(§13.2). MVP 는 해역 1 낮.
    const theme = SeaTheme.tropicalDay;
    _ship = ShipView(session: session, side: 0, sprites: sprites, anims: anims);
    await world.addAll([
      await BackdropView.load(
        images,
        rootBundle,
        lowEnd: lowEnd,
        priority: -30,
      ),
      SeaView(front: false, theme: theme, swell: _swell, priority: -10),
      _ship,
      SeaView(front: true, theme: theme, swell: _swell, priority: 10),
    ]);
  }

  double _swell(double x) => Coords.y(_ship.heave);

  double get _shipCenterX =>
      Coords.x(_ship.bowX) -
      session.state.sides[0].grid.width * Coords.cell / 2;

  @override
  void update(double dt) {
    // 판정은 돌리지 않고 파도 시계만 흘려 배가 흔들리게 한다.
    session.turnMs += (dt * 1000).round().clamp(0, 100);
    super.update(dt);
    if (size.x > 0) {
      camera.viewfinder
        ..position = Vector2(_shipCenterX, -110)
        ..zoom = size.x / viewWidth;
    }
  }
}
