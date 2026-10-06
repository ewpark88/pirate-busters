// art/pb_assets_v0.15/tools/flame/pb_anim.dart 에서 가져와 고쳤다 (docs/ASSETS.md).
import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:pirate_busters/game/anim/anim_data.dart';
import 'package:pirate_busters/game/anim/rig_expressions.dart';

/// 부위 하나. anchor = pivot / size 라서 position 이 곧 회전 중심이다.
class PartComponent extends SpriteComponent {
  PartComponent({
    required this.partId,
    required this.anim,
    required Sprite sprite,
    required Vector2 offset,
    required Vector2 pivot,
    required int z,
  }) : base = offset + pivot,
       super(
         sprite: sprite,
         size: sprite.srcSize.clone(),
         anchor: Anchor(pivot.x / sprite.srcSize.x, pivot.y / sprite.srcSize.y),
         position: offset + pivot,
         priority: z,
       );

  final String partId;

  /// shadow fx back body head eyes arm held …
  final String anim;
  final Vector2 base;

  late final Sprite _homeSprite = sprite!;
  late final Vector2 _homeBase = base.clone();
  late final Anchor _homeAnchor = anchor;

  /// 표정 부위 [part] 로 바꿔 끼운다. null 이면 원래 그림으로 돌아간다 (설계서 §10.1).
  void swap(ExprPart? part) {
    // 처음 바꾸기 전에 원래 값을 잡아 둔다.
    final (homeSprite, homeBase, homeAnchor) = (
      _homeSprite,
      _homeBase,
      _homeAnchor,
    );
    final next = part?.sprite ?? homeSprite;
    sprite = next;
    size.setFrom(next.srcSize);
    if (part == null) {
      anchor = homeAnchor;
      base.setFrom(homeBase);
    } else {
      anchor = Anchor(part.pivot.x / size.x, part.pivot.y / size.y);
      base.setFrom(part.offset + part.pivot);
    }
  }

  /// [unit] = 캔버스 1px 이 이 스프라이트에서 몇 px 인지. [alpha] 는 캐릭터 전체 투명도.
  /// [flash] 는 흰 번쩍임 세기(0~1).
  void applyPose(
    PartPose p,
    double unit, {
    double alpha = 1,
    double flash = 0,
  }) {
    position.setValues(base.x + p.dx * unit, base.y + p.dy * unit);
    angle = p.rot * math.pi / 180;
    scale.setValues(p.sx, p.sy);
    opacity = (p.op * alpha).clamp(0.0, 1.0);
    paint.colorFilter = flash > 0
        ? ColorFilter.mode(
            Color.fromRGBO(255, 255, 255, flash),
            BlendMode.srcATop,
          )
        : null;
  }
}
