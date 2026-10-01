import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/battle/battle_session.dart';
import 'package:pirate_busters/battle/playback.dart';
import 'package:pirate_busters/game/anim/anim_data.dart';
import 'package:pirate_busters/game/anim/character_rig.dart';
import 'package:pirate_busters/game/coords.dart';
import 'package:pirate_busters/game/sprites.dart';
import 'package:pirate_busters/game/view/damage_painter.dart';
import 'package:pirate_busters/game/view/torn_edge_painter.dart';

/// 배 한 척: 격자 타일, 돛대, 선실의 해적. 시뮬레이션 상태를 그리기만 한다.
///
/// 로컬 원점은 배 가운데의 용골 바닥이고, 오른쪽 배는 좌우를 뒤집는다(scale.x = −1).
/// 파도 위아래·기울기(파도 + 침수)와 이동 연출을 반영한다 (설계서 §2.5, §2.6).
class ShipView extends PositionComponent with HasGameReference {
  ShipView({
    required this.session,
    required this.side,
    required this.sprites,
    required this.anims,
  }) : _built = GridSnapshot(session.state.sides[side].grid);

  final BattleSession session;
  final int side;
  final BattleSprites sprites;
  final PbAnims anims;
  final GridSnapshot _built;
  final List<CharacterRig> rigs = [];

  static const double _cell = Coords.cell;

  SideState get _state => session.state.sides[side];

  int get _width => _state.grid.width;

  @override
  Future<void> onLoad() async {
    final team = side == 0 ? 'blue' : 'red';
    for (var slot = 0; slot < _state.crew.size; slot++) {
      final id = session.speciesOf(_state.crew.pirates[slot].spec.id);
      final rig = await CharacterRig.load(
        game.images,
        id,
        team,
        phase: slot * 0.27,
      );
      final cabin = _state.cabins[slot];
      rig.home.setValues(_localX(cabin.x + 0.5), -cabin.y * _cell);
      rigs.add(rig);
      await add(rig);
    }
  }

  double _localX(num cx) => (cx - _width / 2) * _cell;

  /// 해적 [slot] 의 공격 동작.
  void playAttack(int slot) {
    final id = session.speciesOf(_state.crew.pirates[slot].spec.id);
    final clip = anims.attacks[id];
    if (clip != null && slot < rigs.length) rigs[slot].play(clip);
  }

  /// 판 시작 때 [cell] 칸이 철판이었는가 (착탄 소리).
  bool isIron(int cell) =>
      cell >= 0 &&
      cell < _built.materials.length &&
      _built.materials[cell] == BlockMaterial.iron.index;

  void playHit(int slot) {
    if (slot >= 0 && slot < rigs.length) rigs[slot].play(anims.hit);
  }

  /// 지금 그리는 뱃머리 x(시뮬레이션 단위). 이동 연출 중이면 중간 값.
  double get bowX {
    final p = session.playback;
    if (p is MovePlayback && p.side == side) return p.bowX;
    return _state.bowX.toDouble();
  }

  /// 파도 위아래 흔들림(시뮬레이션 단위).
  int get heave =>
      Wave(session.state.rules, session.state.turn).heave(side, session.turnMs);

  @override
  void update(double dt) {
    super.update(dt);
    final facing = facingOf(side);
    final midX = bowX - facing * _width * cellUnit / 2;
    position = Coords.point(midX, heave - _state.draft);
    scale.x = facing.toDouble();
    final rules = session.state.rules;
    final tilt =
        Wave(rules, session.state.turn).roll(side, session.turnMs) +
        floodTilt(_state, rules);
    angle = -facing * tilt * math.pi / 180000;
    _updateCrew(dt);
  }

  final List<Vector2> _targets = [];
  double _t = 0;

  /// 해적 자세 (설계서 §10.1): 선실에서 대기, 조준할 때 몸을 젖히고, 선실이
  /// 부서지면 바다로 떨어져 헤엄치고, 돌아오면 선실로 올라가고, 쓰러지면 사라진다.
  /// 착탄 전(탄 비행 중)에는 쏘기 전 자세를 유지한다.
  void _updateCrew(double dt) {
    _t += dt;
    final crew = _state.crew;
    final shot = session.playback;
    final frozen = shot is ShotPlayback && !shot.landed;
    final k = 1 - math.exp(-6 * dt);
    while (_targets.length < rigs.length) {
      _targets.add(rigs[_targets.length].home.clone());
    }
    for (var slot = 0; slot < rigs.length; slot++) {
      final rig = rigs[slot];
      final status = crew.pirates[slot].status;
      if (!frozen) {
        switch (status) {
          case PirateStatus.aboard:
            final cabin = _state.cabins[slot];
            _targets[slot].setValues(_localX(cabin.x + 0.5), -cabin.y * _cell);
          case PirateStatus.swimming:
            // 뱃머리 1칸 앞 해수면(시뮬레이션 swimmerPosition), 물결에 까딱인다.
            final sea = (heave - _state.draft) * _cell / cellUnit;
            final bob = math.sin(_t * 3 + slot) * 2;
            _targets[slot].setValues(
              _localX(_width + 1 + slot * 0.6),
              sea + bob,
            );
          case PirateStatus.down:
            break;
        }
        rig.alpha += ((status == PirateStatus.down ? 0 : 1) - rig.alpha) * k;
      }
      rig.home.add((_targets[slot] - rig.home) * k);
      rig.lean = _leanOf(slot);
    }
  }

  /// 조준 자세: 사람은 당긴 만큼, 상대는 쏘기 직전에 몸을 젖힌다 (설계서 §2.3).
  double _leanOf(int slot) {
    final aim = session.aim;
    if (aim != null && aim.slot == slot && session.state.activeSide == side) {
      return 14 * aim.stretch;
    }
    final foe = session.opponentAim;
    if (foe != null && foe.slot == slot && session.state.activeSide == side) {
      return 14 * foe.progress;
    }
    return 0;
  }

  @override
  void render(Canvas canvas) {
    final shot = session.playback;
    final grid = _state.grid;
    // 착탄 전까지는 쏘기 전 모습, 착탄 뒤(부서지는 연출)는 지금 모습.
    final snap = shot is ShotPlayback && !shot.landed
        ? shot.before[side]
        : null;
    final materials = snap?.materials ?? grid.rawMaterials;
    final hp = snap?.hp ?? grid.rawHp;
    _renderRig(canvas, materials);
    for (var y = 0; y < grid.height; y++) {
      for (var x = 0; x < grid.width; x++) {
        final i = y * grid.width + x;
        final rect = Rect.fromLTWH(_localX(x), -(y + 1) * _cell, _cell, _cell);
        final m = materials[i];
        if (m == ShipGrid.emptyCell) {
          if (_built.materials[i] != ShipGrid.emptyCell) {
            DamagePainter.broken(canvas, rect, i);
          }
          continue;
        }
        final mat = BlockMaterial.values[m];
        final stage = ShipGrid.stageFor(hp[i], mat.durability);
        final tile = sprites.tile(mat, variant: i * 7, keel: y == 0);
        if (tile == null) {
          _renderNet(canvas, rect, stage);
          continue;
        }
        tile.render(
          canvas,
          position: rect.topLeft.toVector2(),
          size: Vector2.all(_cell),
        );
        // 금은 이웃 부서진 칸 쪽에서 들어와 이어져 보인다 (설계서 §10.2).
        TornEdgePainter.damage(canvas, rect, i, stage, _mask(materials, x, y));
      }
    }
    // 부서진 칸의 가장자리는 타일을 모두 그린 뒤 이웃 블록 쪽으로 찢어 그린다.
    for (var y = 0; y < grid.height; y++) {
      for (var x = 0; x < grid.width; x++) {
        final i = y * grid.width + x;
        if (materials[i] != ShipGrid.emptyCell ||
            _built.materials[i] == ShipGrid.emptyCell) {
          continue;
        }
        final rect = Rect.fromLTWH(_localX(x), -(y + 1) * _cell, _cell, _cell);
        TornEdgePainter.torn(
          canvas,
          rect,
          i,
          _mask(materials, x, y, block: true),
        );
      }
    }
  }

  /// ([x], [y]) 의 상하좌우 이웃 마스크. [block] 이면 블록이 남은 이웃, 아니면
  /// 설계도에 있었다가 부서진 이웃.
  int _mask(List<int> materials, int x, int y, {bool block = false}) {
    final grid = _state.grid;
    bool at(int nx, int ny) {
      if (!grid.inBounds(nx, ny)) return false;
      final i = ny * grid.width + nx;
      final has = materials[i] != ShipGrid.emptyCell;
      return block ? has : !has && _built.materials[i] != ShipGrid.emptyCell;
    }

    return (at(x - 1, y) ? TornEdgePainter.left : 0) |
        (at(x + 1, y) ? TornEdgePainter.right : 0) |
        (at(x, y + 1) ? TornEdgePainter.up : 0) |
        (at(x, y - 1) ? TornEdgePainter.down : 0);
  }

  static final Paint _netPaint = Paint()
    ..color = const Color(0xFFD9CBA8)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;

  /// 망사(돛) 칸: 에셋에 없어 코드로 그린다 (ADR-029).
  void _renderNet(Canvas canvas, Rect r, DamageStage stage) {
    final step = stage == DamageStage.intact ? 8.0 : 12.0;
    for (var d = 0.0; d <= r.width; d += step) {
      canvas
        ..drawLine(
          Offset(r.left + d, r.top),
          Offset(r.left + d, r.bottom),
          _netPaint,
        )
        ..drawLine(
          Offset(r.left, r.top + d),
          Offset(r.right, r.top + d),
          _netPaint,
        );
    }
  }

  /// 돛대·돛·깃발 (장식, 판정 없음). 가장 높은 블록 위 가운데에 세운다.
  void _renderRig(Canvas canvas, List<int> materials) {
    var top = 0;
    for (var i = 0; i < materials.length; i++) {
      if (materials[i] != ShipGrid.emptyCell) top = i ~/ _width + 1;
    }
    final team = side == 0 ? 'blue' : 'red';
    final mast = sprites.get('ship/rig/mast.png');
    final mastSize = mast.srcSize / 3.2;
    final baseY = -top * _cell;
    final mastPos = Vector2(-mastSize.x / 2, baseY - mastSize.y);
    mast.render(canvas, position: mastPos, size: mastSize);
    final sail = sprites.get('ship/rig/sail_$team.png');
    final sailSize = sail.srcSize / 4.2;
    sail.render(
      canvas,
      position: Vector2(-sailSize.x / 2, mastPos.y + 16),
      size: sailSize,
    );
    final flag = sprites.get('ship/rig/flag_$team.png');
    flag.render(
      canvas,
      position: Vector2(4, mastPos.y - 10),
      size: flag.srcSize / 3.6,
    );
  }
}

extension on Offset {
  Vector2 toVector2() => Vector2(dx, dy);
}
