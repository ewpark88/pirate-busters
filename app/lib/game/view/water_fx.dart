import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/particles.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/battle/battle_session.dart';
import 'package:pirate_busters/game/view/fx_layer.dart';

/// 물 연출 (설계서 §10.4 침수·격침): 거품, 물방울, 큰 물보라와 물안개. 그리기만 한다.
abstract final class WaterFx {
  static const String bubble = 'fx/collapse/bubble.png';
  static const String drop = 'fx/collapse/water_drop.png';
  static const String mist = 'fx/collapse/mist.png';
  static const String splashBig = 'fx/collapse/splash_big.png';

  /// 전장이 미리 읽는 그림.
  static const List<String> files = [bubble, drop, mist];

  /// 수면 아래 칸에서 이번에 거품을 낼 칸들: 잠긴 새는 칸을 칸 순서로 모아
  /// [tick] 번째 묶음([perTick] 개)을 고른다. 고르는 순서가 정해져 있어 깜빡이지 않고
  /// 고르게 돈다.
  static List<(int, int)> bubbleCells(SideState side, int tick, int perTick) {
    final all = <(int, int)>[];
    forEachSubmergedLeak(side, (x, y, _) => all.add((x, y)));
    if (all.isEmpty) return const [];
    return [
      for (var i = 0; i < math.min(perTick, all.length); i++)
        all[(tick * perTick + i) % all.length],
    ];
  }
}

/// 물 연출 띄우기.
extension WaterEffects on FxLayer {
  /// 거품 하나가 [at] 에서 수면([surfaceY])까지 흔들리며 떠오른다.
  void bubbleUp(Vector2 at, double surfaceY) {
    final rise = math.max(8, at.y - surfaceY);
    final size = 5 + rnd.nextDouble() * 5;
    spawn(
      SpriteComponent(
        sprite: sprites.get(WaterFx.bubble),
        position: at + Vector2((rnd.nextDouble() - .5) * 14, 0),
        size: Vector2.all(size),
        anchor: Anchor.center,
        children: [
          MoveByEffect(
            Vector2(0, -rise.toDouble()),
            EffectController(duration: .5 + rise / 120),
          ),
          MoveByEffect(
            Vector2(4, 0),
            EffectController(duration: .25, alternate: true, infinite: true),
          ),
          OpacityEffect.fadeOut(
            EffectController(duration: .25, startDelay: .3 + rise / 120),
          ),
          RemoveEffect(delay: .55 + rise / 120),
        ],
      ),
    );
  }

  /// 물방울: 수면 [at] 에서 튀어 올랐다가 떨어진다(턴 끝 침수 증가).
  void droplets(Vector2 at, {int count = 8}) => spawn(
    ParticleSystemComponent(
      position: at.clone(),
      particle: Particle.generate(
        count: few(count),
        lifespan: .7,
        generator: (i) => AcceleratedParticle(
          speed: Vector2(
            (rnd.nextDouble() - .5) * 120,
            -120 - rnd.nextDouble() * 120,
          ),
          acceleration: Vector2(0, 520),
          child: SpriteParticle(
            sprite: sprites.get(WaterFx.drop),
            size: Vector2.all(6 + rnd.nextDouble() * 4),
          ),
        ),
      ),
    ),
  );

  /// 격침: 배 둘레 [width] 에 큰 물보라와 물안개, 거품 (설계서 §10.4).
  void sinkSplash(Vector2 at, double width) {
    for (final dx in [-width * .35, 0.0, width * .35]) {
      spawn(
        popSprite(WaterFx.splashBig, at + Vector2(dx, -30), width * .45, .9),
      );
    }
    for (var i = 0; i < few(3); i++) {
      final dx = (i - 1) * width * .3;
      spawn(
        SpriteComponent(
          sprite: sprites.get(WaterFx.mist),
          position: at + Vector2(dx, -10),
          size: Vector2.all(width * .5),
          anchor: Anchor.center,
          children: [
            OpacityEffect.to(0, EffectController(duration: 0)),
            OpacityEffect.to(.7, EffectController(duration: .4)),
            MoveByEffect(Vector2(0, -30), EffectController(duration: 2.4)),
            OpacityEffect.to(
              0,
              EffectController(duration: 1.2, startDelay: 1.4),
            ),
            RemoveEffect(delay: 2.7),
          ],
        ),
      );
    }
    for (var i = 0; i < few(12); i++) {
      bubbleUp(at + Vector2((rnd.nextDouble() - .5) * width, 40), at.y);
    }
    droplets(at, count: 14);
    shake = math.max(shake, 10);
  }
}

/// 흘수선 아래 구멍 칸에서 거품이 올라온다 (설계서 §10.4 침수). 시뮬 상태를 읽기만
/// 한다. 저사양 모드에서는 간격이 두 배다.
class LeakBubbles extends Component {
  LeakBubbles({
    required this.session,
    required this.fx,
    required this.cellWorld,
  });

  final BattleSession session;
  final FxLayer fx;

  /// 칸 (진영, 칸 번호) → 월드 위치.
  final Vector2 Function(int side, int cell) cellWorld;

  /// 거품을 내는 간격(초)과 한 번에 내는 칸 수.
  static const double interval = .45;
  static const int perTick = 2;

  double _t = 0;
  int _tick = 0;

  @override
  void update(double dt) {
    _t += dt;
    final gap = fx.few(2) == 1 ? interval * 2 : interval;
    if (_t < gap) return;
    _t = 0;
    _tick++;
    for (final side in session.state.sides) {
      for (final (x, y) in WaterFx.bubbleCells(side, _tick, perTick)) {
        fx.bubbleUp(cellWorld(side.side, y * side.grid.width + x), 0);
      }
    }
  }
}
