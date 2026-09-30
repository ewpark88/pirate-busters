// art/pb_assets_v0.15/tools/flame/pb_anim.dart 에서 가져와 고쳤다 (docs/ASSETS.md):
// 경로(parts_<team>, assets/data/anims.json), 린트, 대기 위상은 슬롯으로 정한다.
import 'dart:convert';
import 'dart:math' as math;

import 'package:flame/cache.dart';
import 'package:flame/components.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pirate_busters/game/anim/anim_data.dart';

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

  /// [unit] = 캔버스 1px 이 이 스프라이트에서 몇 px 인지. [alpha] 는 캐릭터 전체 투명도.
  void applyPose(PartPose p, double unit, {double alpha = 1}) {
    position.setValues(base.x + p.dx * unit, base.y + p.dy * unit);
    angle = p.rot * math.pi / 180;
    scale.setValues(p.sx, p.sy);
    opacity = (p.op * alpha).clamp(0.0, 1.0);
  }
}

/// 캐릭터 한 명을 부위별로 움직인다 (설계서 §10.1). position = 발(기준점).
class CharacterRig extends PositionComponent {
  CharacterRig._(this._n, this._battleScale, Vector2 canvas, Vector2 anchorPx)
    : super(
        size: canvas,
        anchor: Anchor(anchorPx.x / canvas.x, anchorPx.y / canvas.y),
      );

  /// 캐릭터 [id], 팀 [team](blue | red)의 부위를 게임의 [images] 로 읽는다.
  /// [phase] 는 대기 동작 위상(0~1).
  static Future<CharacterRig> load(
    Images images,
    String id,
    String team, {
    double phase = 0,
    double battleScale = 0.16,
    bool battleOutline = true,
  }) async {
    // 전장에서는 전투 외곽선을 구운 부위를 쓴다(사방 14px 여백: offset −14,
    // pivot +14, docs/ASSETS.md). 위치 정보는 일반 부위의 parts.json 을 쓴다.
    final dir = 'characters/$id/parts_$team';
    final imageDir = battleOutline ? 'characters/$id/parts_battle_$team' : dir;
    final pad = battleOutline ? 14.0 : 0.0;
    final j =
        jsonDecode(await rootBundle.loadString('assets/images/$dir/parts.json'))
            as Map<String, dynamic>;
    Vector2 v(dynamic a) {
      final l = a as List<dynamic>;
      return Vector2((l[0] as num).toDouble(), (l[1] as num).toDouble());
    }

    final n = (j['scale'] as num?)?.toInt() ?? 2;
    final rig = CharacterRig._(n, battleScale, v(j['canvas']), v(j['anchor']))
      .._phase = phase;
    for (final p in j['parts'] as List<dynamic>) {
      final m = p as Map<String, dynamic>;
      final img = await images.load('$imageDir/${m['file']}');
      final c = PartComponent(
        partId: m['id'] as String,
        anim: m['anim'] as String,
        sprite: Sprite(img),
        offset: v(m['offset']) - Vector2.all(pad),
        pivot: v(m['pivot']) + Vector2.all(pad),
        z: m['z'] as int,
      );
      rig._parts[c.partId] = c;
      await rig.add(c);
    }
    return rig;
  }

  final int _n;
  final double _battleScale;
  final Map<String, PartComponent> _parts = {};
  double _phase = 0;
  AnimClip? _clip;
  bool _loop = false;
  double _t = 0;
  double _idleT = 0;

  /// 좌우를 뒤집는다(오른쪽 배 해적은 왼쪽을 본다).
  bool flip = false;

  /// 캐릭터 전체 투명도(쓰러지면 사라진다).
  double alpha = 1;

  /// 몸을 뒤로 젖히는 각(도). 조준 자세에 쓴다 (설계서 §10.1).
  double lean = 0;

  /// 발 위치(부모 좌표). 동작의 root 이동은 여기에 더한다.
  final Vector2 home = Vector2.zero();

  void play(AnimClip clip, {bool loop = false}) {
    _clip = clip;
    _loop = loop;
    _t = 0;
  }

  bool get isPlaying => _clip != null;

  void _applyRoot(PartPose r) {
    final s = _battleScale / _n;
    scale.setValues(s * r.sx * (flip ? -1 : 1), s * r.sy);
    angle = (r.rot - lean) * math.pi / 180;
    position.setValues(
      home.x + r.dx * _battleScale * (flip ? -1 : 1),
      home.y + r.dy * _battleScale,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    _idleT += dt;
    final clip = _clip;
    if (clip != null) {
      _t += dt;
      if (_t >= clip.duration) {
        if (_loop) {
          _t -= clip.duration;
        } else {
          _clip = null;
          _t = 0;
        }
      }
    }
    final tracks = _clip?.tracks ?? const <String, List<AnimKey>>{};
    final r = PartPose.sample(tracks['root'], _t)
      ..sy *= 1 + .012 * math.sin((_idleT / 2.4 + _phase) * 2 * math.pi);
    _applyRoot(r);
    final bob = 1.2 * math.sin((_idleT / 2.4 + _phase - .25) * 2 * math.pi);
    final sway = math.sin((_idleT / 3 + _phase) * 2 * math.pi);
    for (final p in _parts.values) {
      final s = PartPose.sample(tracks[p.partId], _t);
      if (p.anim == 'fx' && !tracks.containsKey('fx')) s.op = 0;
      switch (p.anim) {
        case 'head' || 'eyes':
          s.dy += bob;
        case 'arm' || 'held':
          s.rot += 2.5 * sway;
        case 'back':
          s.rot += 1.5 * math.sin((_idleT / 3 + _phase + .3) * 2 * math.pi);
      }
      p.applyPose(s, _n.toDouble(), alpha: alpha);
    }
  }
}
