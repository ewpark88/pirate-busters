// art/pb_assets_v0.15/tools/flame/pb_anim.dart 에서 가져와 고쳤다 (docs/ASSETS.md):
// 경로(parts_<team>, assets/data/anims.json), 린트, 대기 위상은 슬롯으로 정한다.
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/cache.dart';
import 'package:flame/components.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pirate_busters/game/anim/anim_data.dart';
import 'package:pirate_busters/game/anim/part_component.dart';
import 'package:pirate_busters/game/anim/rarity_fx.dart';
import 'package:pirate_busters/game/anim/rig_expressions.dart';
import 'package:pirate_busters/game/coords.dart';
import 'package:pirate_busters/game/view/rarity_painter.dart';

export 'package:pirate_busters/game/anim/part_component.dart';

/// 캐릭터 한 명을 부위별로 움직인다 (설계서 §10.1). position = 발(기준점).
class CharacterRig extends PositionComponent {
  CharacterRig._(this._n, this._battleScale, Vector2 canvas, Vector2 anchorPx)
    : super(
        size: canvas,
        anchor: Anchor(anchorPx.x / canvas.x, anchorPx.y / canvas.y),
      );

  /// 캐릭터 [id], 팀 [team](blue | red)의 부위를 게임의 [images] 로 읽는다.
  /// [phase] 는 대기 동작 위상(0~1). [battleScale] 은 선실 한 칸에 맞춘
  /// 에셋 tokens.json 의 값이다 (ADR-057, ADR-062).
  static Future<CharacterRig> load(
    Images images,
    String id,
    String team, {
    double phase = 0,
    double battleScale = Coords.pirateScale,
    bool battleOutline = true,
    Map<String, AnimClip> states = const {},
  }) async {
    // 전장에서는 전투 외곽선을 구운 부위를 쓴다. 사방 여백은 그 폴더
    // battle.json 의 `outlinePad`(offset −pad, pivot +pad, docs/ASSETS.md).
    // 위치 정보는 일반 부위의 parts.json 을 쓴다.
    final dir = 'characters/$id/parts_$team';
    final imageDir = battleOutline ? 'characters/$id/parts_battle_$team' : dir;
    Future<Map<String, dynamic>> json(String file) async =>
        jsonDecode(await rootBundle.loadString('assets/images/$file'))
            as Map<String, dynamic>;
    final pad = battleOutline
        ? ((await json('$imageDir/battle.json'))['outlinePad'] as num)
              .toDouble()
        : 0.0;
    final j = await json('$dir/parts.json');
    Vector2 v(dynamic a) {
      final l = a as List<dynamic>;
      return Vector2((l[0] as num).toDouble(), (l[1] as num).toDouble());
    }

    final n = (j['scale'] as num?)?.toInt() ?? 2;
    final rig = CharacterRig._(n, battleScale, v(j['canvas']), v(j['anchor']))
      .._phase = phase
      .._states = states
      .._expressions = await RigExpressions.load(images, id, team);
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

  /// 등급 연출 값: 발밑 고리, 외곽 빛, 발사 순간 반짝 (설계서 §10.5).
  RarityTier tier = RarityFx.common;
  double _glintT = double.infinity;

  /// 저사양 모드: 떠오르는 반짝임을 줄이고 외곽 빛을 끈다 (설계서 §12).
  bool fewer = false;

  Map<String, AnimClip> _states = const {};
  RigExpressions? _expressions;
  String _clipExpr = 'attack';
  String _shown = RigExpressions.normal;
  double _stateT = 0;

  /// 되풀이하는 상태 동작(aim · fall · swim · win · lose). 한 번 재생하는 동작
  /// (공격·피격)이 끝나면 이 동작으로 돌아간다. null 이면 대기 (설계서 §10.1).
  String? state;

  /// 지금 짓고 있는 표정.
  String get expression => _shown;

  /// [glint] 이면 발사 순간 손끝 반짝도 함께 시작한다. [expr] 는 동작 동안의 표정,
  /// [from] 은 시작 시각(초). 동작의 `flash` 이벤트는 몸을 하얗게 번쩍인다 (A32).
  void play(
    AnimClip clip, {
    bool loop = false,
    bool glint = false,
    String expr = 'attack',
    double from = 0,
  }) {
    _clip = clip;
    _loop = loop;
    _t = from;
    _clipExpr = expr;
    if (glint) _glintT = 0;
    final f = clip.events.where((e) => e.type == 'flash').firstOrNull;
    if (f != null) {
      flash = 1;
      _flashSec = (f.raw['dur'] as num).toDouble();
    }
  }

  /// 흰 번쩍임 세기(0~1)와 사라지는 시간(초).
  double flash = 0;
  double _flashSec = .12;

  /// 머리·눈 부위를 표정 [name] 으로 바꾼다. 표정 에셋이 없으면 그대로 둔다.
  void _show(String name) {
    if (name == _shown) return;
    _shown = name;
    final parts = name == RigExpressions.normal ? null : _expressions?.of(name);
    for (final id in const ['head', 'eyes']) {
      _parts[id]?.swap(parts?[id]);
    }
  }

  /// 부위보다 먼저(뒤에) 그린다. 캔버스를 월드 px 단위로 돌려 놓고 발 기준으로 그린다.
  @override
  void render(Canvas canvas) {
    if (tier.color == null || alpha <= 0) return;
    canvas
      ..save()
      ..translate(size.x * anchor.x, size.y * anchor.y)
      ..scale(_n / _battleScale);
    if (!fewer) {
      RarityPainter.glow(canvas, Offset.zero, tier, alpha, sec: _idleT);
    }
    RarityPainter.aura(
      canvas,
      Offset.zero,
      tier,
      _idleT,
      alpha: alpha,
      fewer: fewer,
    );
    RarityPainter.glint(
      canvas,
      const Offset(6, -Coords.pirateHeight * .55),
      tier,
      _glintT,
    );
    canvas.restore();
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
    _glintT += dt;
    flash = math.max(0, flash - dt / _flashSec);
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
    // 한 번 재생하는 동작이 없으면 상태 동작을 되풀이한다.
    final found = _clip == null ? _states[state] : null;
    final looped = found != null && found.duration > 0 ? found : null;
    if (looped != null) _stateT = (_stateT + dt) % looped.duration;
    _show(
      _clip != null
          ? _clipExpr
          : looped?.expr ?? (lean > 0 ? 'aim' : RigExpressions.normal),
    );
    final tracks =
        _clip?.tracks ?? looped?.tracks ?? const <String, List<AnimKey>>{};
    final at = _clip != null ? _t : _stateT;
    final r = PartPose.sample(tracks['root'], at)
      ..sy *= 1 + .012 * math.sin((_idleT / 2.4 + _phase) * 2 * math.pi);
    _applyRoot(r);
    final bob = 1.2 * math.sin((_idleT / 2.4 + _phase - .25) * 2 * math.pi);
    final sway = math.sin((_idleT / 3 + _phase) * 2 * math.pi);
    for (final p in _parts.values) {
      final s = PartPose.sample(tracks[p.partId], at);
      if (p.anim == 'fx' && !tracks.containsKey('fx')) s.op = 0;
      switch (p.anim) {
        case 'head' || 'eyes':
          s.dy += bob;
        case 'arm' || 'held':
          s.rot += 2.5 * sway;
        case 'back':
          s.rot += 1.5 * math.sin((_idleT / 3 + _phase + .3) * 2 * math.pi);
      }
      p.applyPose(s, _n.toDouble(), alpha: alpha, flash: flash);
    }
  }
}
