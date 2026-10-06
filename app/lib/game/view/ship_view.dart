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
import 'package:pirate_busters/game/view/cabin_painter.dart';
import 'package:pirate_busters/game/view/crew_reactions.dart';
import 'package:pirate_busters/game/view/damage_layer.dart';
import 'package:pirate_busters/game/view/fire_view.dart';
import 'package:pirate_busters/game/view/hull_trim.dart';
import 'package:pirate_busters/game/view/mast_painter.dart';
import 'package:pirate_busters/game/view/module_painter.dart';
import 'package:pirate_busters/game/view/plank_join.dart';
import 'package:pirate_busters/game/view/ship_motion.dart';

/// 배 한 척: 격자 타일, 돛대, 선실 칸 안의 해적, 불(`FireView`). 그리기만 한다.
/// 원점은 배 가운데 용골 바닥, 오른쪽 배는 좌우 뒤집음. 파도·기울기·이동 반영 (§2.5·§2.6).
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
      final spec = _state.crew.pirates[slot].spec;
      final rig = await CharacterRig.load(
        game.images,
        session.speciesOf(spec.id),
        team,
        phase: slot * 0.27,
        states: anims.states,
      );
      rig
        ..tier = anims.rarity.of(spec.rarity)
        ..home.setFrom(cabinFeet(slot));
      rigs.add(rig);
      await add(rig);
    }
    await add(FireView(session: session, side: side, sprites: sprites));
  }

  double _localX(num cx) => (cx - _width / 2) * _cell;

  /// [x], [y] 칸의 사각형(로컬 좌표).
  Rect cellRect(int x, int y) =>
      Rect.fromLTWH(_localX(x), -(y + 1) * _cell, _cell, _cell);

  /// 해적 [slot] 이 선실 칸 안에 설 발 위치: 칸 가운데, 바닥 널 위 (ADR-057).
  Vector2 cabinFeet(int slot) {
    final cabin = _state.cabins[slot];
    return Vector2(
      _localX(cabin.x + 0.5),
      -cabin.y * _cell - Coords.cabinFloor,
    );
  }

  bool _isCabin(int x, int y) => _state.cabins.any((c) => c.x == x && c.y == y);

  /// 손상 표현 한 장 (설계서 §10.2·§10.4, ADR-070). 칸 단계가 바뀔 때만 다시 그린다.
  final DamageLayer _damage = DamageLayer();

  @override
  void onRemove() {
    _damage.dispose();
    super.onRemove();
  }

  /// 해적 반응: 밀림·바다 추락 포물선 (설계서 §10.4, A32).
  final CrewReactions reactions = CrewReactions();

  /// 판 시작 때 [cell] 칸이 철판이었는가 (착탄 소리).
  bool isIron(int cell) =>
      cell >= 0 &&
      cell < _built.materials.length &&
      _built.materials[cell] == BlockMaterial.iron.index;

  /// 판 시작 때 [cell] 칸의 타일 그림(무너지는 덩어리용). 빈 칸이면 null.
  Sprite? builtTile(int cell) {
    final m = cell >= 0 && cell < _built.materials.length
        ? _built.materials[cell]
        : ShipGrid.emptyCell;
    return m == ShipGrid.emptyCell
        ? null
        : sprites.tileOf(m, cell % _width, cell ~/ _width, _state.draft);
  }

  /// 흔들림·격침 연출 (설계서 §10.4).
  final ShipMotion motion = ShipMotion();

  /// 맞은 방향으로 흔들렸다가 돌아온다 (설계서 §10.4).
  void rock(int dir) => motion.rock(dir);

  void recoil(int dir) => motion.recoil(dir); // 쏠 때 반동 (A20).

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
    final state = session.state;
    // 판이 격침으로 끝나면 진 배가 기울며 가라앉는다(재생이 끝난 뒤).
    if (state.isOver && isSinkOutcome(state.outcome) && state.winner != side) {
      if (session.playback == null) motion.startSink();
    }
    motion.update(dt);
    position = Coords.point(midX, heave - _state.draft)
      ..x += motion.recoilX
      ..y += motion.depth + motion.dip;
    scale.x = facing.toDouble();
    final rules = state.rules;
    final flood = floodTilt(_state, rules);
    final tilt = Wave(rules, state.turn).roll(side, session.turnMs) + flood;
    angle =
        -facing * tilt * math.pi / 180000 +
        motion.rockAngle +
        motion.recoilAngle -
        facing * motion.extraTilt(flood == 0 ? -1 : flood.sign.toDouble());
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
    final state = session.state;
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
            _targets[slot].setFrom(cabinFeet(slot));
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
      } else if (shot.side == side &&
          shot.slot == slot &&
          crew.pirates[slot].spec.ammo == AmmoType.assault) {
        // 강습탄은 해적 자신이 날아간다: 나는 동안 선실은 비어 보인다 (§10.4).
        rig.alpha = 0;
      }
      reactions.move(slot, rig.home, _targets[slot], k, dt);
      // 상태 동작과 표정 (설계서 §10.1): 떨어지는 중, 헤엄, 판이 끝나면 승리·패배.
      rig
        ..lean = leanOf(session, side, slot)
        ..state = status == PirateStatus.swimming
            ? (rig.home.distanceTo(_targets[slot]) > 8 ? 'fall' : 'swim')
            : state.isOver && state.winner >= 0
            ? (state.winner == side ? 'win' : 'lose')
            : (rig.lean > 0 ? 'aim' : null);
    }
  }

  @override
  void render(Canvas canvas) {
    final shot = session.playback;
    final grid = _state.grid;
    // 탄 연출 중에는 착탄 이벤트가 나온 만큼만 부서진 모습 (A33).
    final snap = shot is ShotPlayback ? shot.live[side] : null;
    final materials = snap?.materials ?? grid.rawMaterials;
    final hp = snap?.hp ?? grid.rawHp;
    MastPainter.paint(canvas, sprites, _state, materials, cellRect);
    for (var y = 0; y < grid.height; y++) {
      for (var x = 0; x < grid.width; x++) {
        final i = y * grid.width + x;
        final rect = cellRect(x, y);
        final m = materials[i];
        _mats[i] = m == ShipGrid.emptyCell ? _built.materials[i] : m;
        // 돛대 칸은 타일·손상 대신 MastPainter 가 기둥으로 그린다 (§3.3).
        _codes[i] = DamageLayer.codeOf(
          m,
          _built.materials[i],
          hp[i],
          grid.maxHpAt(i),
        );
        if (m == ShipGrid.emptyCell || BlockMaterial.values[m].rig) continue;
        final join = PlankJoin.mask(materials, _width, x, y);
        final tile = sprites.tileOf(m, x, y, _state.draft);
        PlankJoin.drawTile(canvas, tile, rect, join);
        // 선실 칸은 재질 테두리 안에 안쪽 벽을 깐다. 해적은 그 위에 그려진다.
        if (_isCabin(x, y)) {
          CabinPainter.room(canvas, rect, sprites.roomWall(x, y));
        }
        final module = _moduleAt[i];
        if (module != null) ModulePainter.draw(canvas, sprites, rect, module);
      }
    }
    HullTrim.paint(
      canvas,
      hull: grid.hull,
      materials: materials,
      tileAt: (m, x, y) => sprites.tileOf(m, x, y, _state.draft),
      cellRect: cellRect,
    );
    // 배 속·그을음·금·구멍·찢긴 변·파편은 타일을 모두 그린 뒤 한 장으로 얹는다.
    var wetRows = 0;
    while (wetRows < grid.height &&
        BattleSprites.isWet(wetRows, _state.draft)) {
      wetRows++;
    }
    _damage.paint(
      canvas,
      width: _width,
      codes: _codes,
      materials: _mats,
      wetRows: wetRows,
      origin: cellRect(0, grid.height - 1).topLeft,
      cell: _cell,
    );
  }

  /// 칸별 손상 코드 (`DamageLayer.none`·단계 0~2·`DamageLayer.broken`).
  late final List<int> _codes = List.filled(
    _state.grid.width * _state.grid.height,
    DamageLayer.none,
  );

  /// 칸별 재질 (부서진 칸은 판 시작 때 재질).
  late final List<int> _mats = List.of(_built.materials);

  /// 칸 번호 → 모듈 (설계도 그대로). 블록이 부서지면 그 칸과 함께 안 그린다.
  late final Map<int, ModuleKind> _moduleAt = ModulePainter.byCell(
    _state.modules,
    _width,
  );
}
