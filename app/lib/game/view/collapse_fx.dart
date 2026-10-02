import 'package:flame/components.dart';
import 'package:pirate_busters/game/coords.dart';

/// 지지가 끊겨 떨어지는 블록 한 칸 (설계서 §10.4 붕괴). 끊긴 쪽으로 기울며 떨어지고
/// 수면에 닿으면 [onSplash] 를 부른 뒤 사라진다. 그리기만 한다. 판정은 이미 끝났다.
class FallingChunk extends SpriteComponent {
  FallingChunk({
    required Sprite sprite,
    required Vector2 at,
    required this.lean,
    required this.onSplash,
  }) : super(
         sprite: sprite,
         position: at.clone(),
         size: Vector2.all(Coords.cell),
         anchor: Anchor.center,
         priority: 2,
       );

  /// 기우는 방향과 세기(+ 시계 방향, 라디안/초). 배 가운데에서 먼 쪽으로 기운다.
  final double lean;

  /// 수면에 닿은 자리(월드 px)를 넘긴다.
  final void Function(Vector2 at) onSplash;

  /// 떨어지는 가속도(월드 px/초²).
  static const double gravity = 900;

  double _vy = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _vy += gravity * dt;
    position
      ..y += _vy * dt
      ..x += lean * 14 * dt;
    angle += lean * dt;
    // 해수면은 y = 0 이다 (Coords).
    if (position.y >= 0) {
      onSplash(Vector2(position.x, 0));
      removeFromParent();
    }
  }
}
