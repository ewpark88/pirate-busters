import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:flutter/services.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/game/anim/anim_data.dart';
import 'package:pirate_busters/game/anim/character_rig.dart';

/// 모션 보기에서 고를 수 있는 동작 (설계서 §10.1). 렌더 전용이다.
enum Motion { idle, attack, hit, aim, fall, swim, win, lose }

/// 운영자 모드 해적 모션 보기 (ADR-099): 해적 한 명을 크게 세워 두고 전장과 같은
/// 부위 동작(`anims.json`)을 재생한다. 판은 없다.
class MotionPreviewGame extends FlameGame {
  MotionPreviewGame({this.anims});

  /// 미리 읽은 동작 자료(테스트). null 이면 에셋에서 읽는다.
  PbAnims? anims;

  CharacterRig? _rig;
  String? _species;
  Motion _motion = Motion.idle;

  /// 지금 세워 둔 해적 종(그림 키).
  String? get species => _species;

  Motion get motion => _motion;

  @override
  Color backgroundColor() => const Color(0xFF1C3D5A);

  @override
  Future<void> onLoad() async {
    anims ??= PbAnims.fromJsonString(
      await rootBundle.loadString(PbAnims.path),
    );
  }

  /// 종 [species]·등급 [rarity] 해적을 [team](blue | red)으로 세운다.
  Future<void> show(String species, Rarity rarity, String team) async {
    await loaded;
    final a = anims!;
    final rig = await CharacterRig.load(
      images,
      species,
      team,
      states: a.states,
    );
    rig.rarity(a.rarity, rarity);
    _rig?.removeFromParent();
    _rig = rig;
    _species = species;
    await world.add(rig);
    play(_motion);
  }

  /// [m] 동작을 재생한다. 공격·피격은 한 번, 나머지는 되풀이한다.
  void play(Motion m) {
    _motion = m;
    final rig = _rig;
    final a = anims;
    if (rig == null || a == null) return;
    rig.state = switch (m) {
      Motion.aim => 'aim',
      Motion.fall => 'fall',
      Motion.swim => 'swim',
      Motion.win => 'win',
      Motion.lose => 'lose',
      _ => null,
    };
    switch (m) {
      case Motion.attack:
        final clip = a.attacks[_species];
        if (clip != null) rig.play(clip, glint: true);
      case Motion.hit:
        rig.play(a.hit, expr: 'hit');
      case Motion.idle ||
          Motion.aim ||
          Motion.fall ||
          Motion.swim ||
          Motion.win ||
          Motion.lose:
        break;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    final rig = _rig;
    if (rig == null || size.y <= 0) return;
    // 발이 원점이다. 해적 키가 화면 높이의 약 60% 가 되게 맞춘다.
    final h = math.max(1, rig.size.y * rig.scale.y.abs()).toDouble();
    camera.viewfinder
      ..position = Vector2(0, -h * 0.45)
      ..zoom = size.y * 0.6 / h;
  }
}
