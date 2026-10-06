import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:pirate_busters/game/coords.dart';

/// 떨어지는 조각의 그림 한 장: 조각 가운데에서 [offset] 만큼 떨어진 곳에 [size] 로.
class PiecePart {
  const PiecePart(this.sprite, this.offset, this.size);

  final Sprite sprite;
  final Vector2 offset;
  final Vector2 size;
}

/// 떨어지는 조각 (설계서 §10.4 파괴·붕괴, A32): 부서진 칸의 판자·철판 조각이나 지지가
/// 끊긴 덩어리. [delay] 동안 제자리에서 삐걱이다가 [velocity] 로 튀어 [spin] 으로 돌며
/// 떨어지고, 수면에 닿으면 [onSplash] 를 부른 뒤 사라진다. 그리기만 한다.
class FallingPiece extends PositionComponent {
  FallingPiece({
    required this.parts,
    required Vector2 at,
    required this.velocity,
    required this.spin,
    required this.onSplash,
    this.delay = 0,
    super.priority = 2,
  }) : super(position: at.clone(), anchor: Anchor.center) {
    var half = Vector2.zero();
    for (final p in parts) {
      half = Vector2(
        math.max(half.x, p.offset.x.abs() + p.size.x / 2),
        math.max(half.y, p.offset.y.abs() + p.size.y / 2),
      );
    }
    size = half * 2;
  }

  final List<PiecePart> parts;
  final Vector2 velocity;

  /// 도는 빠르기(라디안/초, + 시계 방향).
  final double spin;

  /// 수면에 닿은 자리(월드 px)를 넘긴다.
  final void Function(Vector2 at) onSplash;

  /// 떨어지기 전 삐걱이는 시간(초).
  double delay;
  double _t = 0;

  /// 떨어지는 가속도(월드 px/초²).
  static const double gravity = 900;

  /// 삐걱임 기울기(rad).
  static const double creak = 0.05;

  @override
  void update(double dt) {
    super.update(dt);
    if (delay > 0) {
      delay -= dt;
      _t += dt;
      angle = creak * spin.sign * math.sin(_t * 60);
      return;
    }
    velocity.y += gravity * dt;
    position.add(velocity * dt);
    angle += spin * dt;
    // 해수면은 y = 0 이다 (Coords).
    if (position.y >= 0) {
      onSplash(Vector2(position.x, 0));
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final mid = size / 2;
    for (final p in parts) {
      p.sprite.render(
        canvas,
        position: mid + p.offset - p.size / 2,
        size: p.size,
      );
    }
  }
}

/// 조각 하나의 계획: 타일에서 잘라 낼 부분(0~1 비율)과 튀는 속도·회전.
class ShardSpec {
  const ShardSpec(this.src, this.velocity, this.spin);

  /// 타일 안의 사각형(가로·세로 0~1).
  final Rect src;
  final Vector2 velocity;
  final double spin;
}

/// 부서진 칸의 조각 계획 (설계서 §10.4 파괴, A32). 나무는 결을 따라 가로 판자로, 철판은
/// 네 조각으로 갈라진다(저사양 [fewer] 이면 절반). [away] 는 착탄 지점에서 칸으로 향하는
/// 가로 방향(−1~1). 같은 [seed](칸 위치)면 같은 조각이라 리플레이에서도 같다.
List<ShardSpec> shardPlan(
  int seed, {
  required bool iron,
  bool fewer = false,
  double away = 0,
}) {
  final rnd = math.Random(seed);
  final rects = iron
      ? fewer
            ? const [Rect.fromLTWH(0, 0, .5, 1), Rect.fromLTWH(.5, 0, .5, 1)]
            : const [
                Rect.fromLTWH(0, 0, .5, .5),
                Rect.fromLTWH(.5, 0, .5, .5),
                Rect.fromLTWH(0, .5, .5, .5),
                Rect.fromLTWH(.5, .5, .5, .5),
              ]
      : fewer
      ? const [Rect.fromLTWH(0, 0, 1, .5), Rect.fromLTWH(0, .5, 1, .5)]
      : const [
          Rect.fromLTWH(0, 0, 1, 1 / 3),
          Rect.fromLTWH(0, 1 / 3, 1, 1 / 3),
          Rect.fromLTWH(0, 2 / 3, 1, 1 / 3),
        ];
  return [
    for (final r in rects)
      ShardSpec(
        r,
        Vector2(
          (away * 0.7 + (r.center.dx - .5) + (rnd.nextDouble() - .5) * .6) *
              260,
          -140 - rnd.nextDouble() * 160,
        ),
        (rnd.nextBool() ? 1 : -1) * (5 + rnd.nextDouble() * 7),
      ),
  ];
}

/// 지지가 끊긴 칸 [cells] 를 이웃(상하좌우)끼리 이은 덩어리로 묶는다 (설계서 §10.4 붕괴,
/// A32). [width] 는 격자 폭. 덩어리는 가장 작은 칸 번호 순(아래 줄 먼저)이고, 덩어리 안
/// 칸도 번호 순이다. 같은 입력이면 같은 결과다.
List<List<int>> groupCells(Iterable<int> cells, int width) {
  final left = cells.toSet();
  final groups = <List<int>>[];
  for (final start in [...left]..sort()) {
    if (!left.remove(start)) continue;
    final group = <int>[start];
    for (var i = 0; i < group.length; i++) {
      final c = group[i];
      final x = c % width;
      for (final n in [
        if (x > 0) c - 1,
        if (x < width - 1) c + 1,
        c - width,
        c + width,
      ]) {
        if (left.remove(n)) group.add(n);
      }
    }
    groups.add(group..sort());
  }
  return groups;
}

/// 덩어리마다 떨어지기 시작하는 시간 차(초): 연쇄되는 덩어리가 차례로 무너진다.
const double collapseStagger = 0.08;

/// 덩어리 크기(칸 수)에 따른 회전 빠르기: 큰 덩어리는 천천히 기운다.
double collapseSpin(int cells) => 2.2 / math.sqrt(cells.toDouble());

/// 칸 한 개 크기(월드 px).
const double pieceCell = Coords.cell;
