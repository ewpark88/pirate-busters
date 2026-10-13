import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/battle/battle_session.dart';
import 'package:pirate_busters/game/coords.dart';
import 'package:pirate_busters/game/view/ship_view.dart';

/// 적 배 위에 선 강습 해적 (설계서 §2.3 적 배에 오른 해적, §10.4, ADR-110): 밟은 칸
/// 위에 몸 그림을 세우고 배와 함께 흔들린다. 흔들리거나 받침을 잃거나 쓰러지면
/// 아래로 떨어지며 사라진다(헤엄은 자기 배 쪽 해적 그림이 이어 그린다). 시뮬레이션
/// 상태를 그리기만 한다.
class BoarderView extends Component with HasGameReference {
  BoarderView({required this.session, required this.ships, super.priority});

  final BattleSession session;
  final List<ShipView> ships;

  /// 떨어지는 연출 길이(초)와 떨어지는 거리(월드 px).
  static const double fallTime = 0.5;
  static const double fallDrop = 70;

  /// 몸 그림 크기: 비행하는 강습 해적과 같다(`ShotView`).
  static final Vector2 bodySize = Vector2(240, 324) * Coords.pirateScale;

  final Map<String, Sprite> _bodies = {};

  /// 진영·슬롯별 마지막으로 선 발 위치(월드), 떨어지는 연출 남은 시간.
  final List<List<Vector2?>> _feet = [[], []];
  final List<List<double>> _fall = [[], []];
  double _t = 0;

  static final Paint _paint = Paint();

  @override
  Future<void> onLoad() async {
    final images = game.images;
    for (final side in session.state.sides) {
      for (final pirate in side.crew.pirates) {
        if (pirate.spec.ammo != AmmoType.assault) continue;
        final id = session.speciesOf(pirate.spec.id);
        final team = side.side == 0 ? 'blue' : 'red';
        _bodies['${side.side}/$id'] = Sprite(
          await images.load('characters/$id/${id}_${team}_battle.png'),
        );
      }
      _feet[side.side] = List.filled(side.crew.size, null);
      _fall[side.side] = List.filled(side.crew.size, 0);
    }
  }

  /// 진영 [side] 의 [slot] 강습 해적이 지금(또는 마지막으로) 선 발 위치(월드).
  /// 적 배 위에 선 적이 없으면 null. 연출이 이름표·피해 숫자 자리로 쓴다.
  Vector2? feetOf(int side, int slot) {
    final pirate = session.state.sides[side].crew.pirates[slot];
    if (pirate.status == PirateStatus.boarding) {
      return liveFeet(ships[1 - side], pirate.boardCell);
    }
    final list = _feet[side];
    return slot < list.length ? list[slot] : null;
  }

  /// [ship] 배의 밟은 칸 [cell] 위 가운데(월드). 배의 기울기·뒤집힘을 따른다.
  static Vector2 liveFeet(ShipView ship, int cell) {
    final w = ship.session.state.sides[ship.side].grid.width;
    final r = ship.cellRect(cell % w, cell ~/ w);
    return ship.absolutePositionOf(Vector2(r.center.dx, r.top));
  }

  /// 한 번도 그리지 못하고 떨어진 해적(같은 묶음에서 올라타고 떨어짐)을 [at] 에서
  /// 떨어뜨린다.
  void dropFrom(int side, int slot, Vector2 at) {
    if (slot >= _feet[side].length || _feet[side][slot] != null) return;
    _feet[side][slot] = at;
    _fall[side][slot] = fallTime;
  }

  /// 지금 떨어지는 중인가. 테스트가 본다.
  bool fallingOf(int side, int slot) =>
      slot < _fall[side].length && _fall[side][slot] > 0;

  @override
  void update(double dt) {
    _t += dt;
    for (final s in session.state.sides) {
      final feet = _feet[s.side];
      final fall = _fall[s.side];
      for (var slot = 0; slot < feet.length; slot++) {
        final p = s.crew.pirates[slot];
        if (p.status == PirateStatus.boarding) {
          feet[slot] = liveFeet(ships[1 - s.side], p.boardCell);
          fall[slot] = 0;
        } else if (feet[slot] != null && fall[slot] == 0) {
          // 원래 선실로 돌아왔으면 바로 지우고, 아니면 떨어뜨린다.
          if (p.status == PirateStatus.aboard) {
            feet[slot] = null;
          } else {
            fall[slot] = fallTime;
          }
        } else if (fall[slot] > 0) {
          fall[slot] = math.max(0, fall[slot] - dt);
          if (fall[slot] == 0) feet[slot] = null;
        }
      }
    }
  }

  @override
  void render(Canvas canvas) {
    for (final s in session.state.sides) {
      for (var slot = 0; slot < _feet[s.side].length; slot++) {
        final at = _feet[s.side][slot];
        if (at == null) continue;
        final spec = s.crew.pirates[slot].spec;
        final body = _bodies['${s.side}/${session.speciesOf(spec.id)}'];
        if (body == null) continue;
        final left = _fall[s.side][slot];
        final k = left > 0 ? 1 - left / fallTime : 0.0;
        final bob = left > 0 ? 0 : math.sin(_t * 4 + slot) * 1.5;
        _paint.color = Color.fromRGBO(255, 255, 255, 1 - k);
        canvas
          ..save()
          ..translate(at.x, at.y + bob + fallDrop * k * k)
          ..rotate(k * 0.8 * facingOf(s.side))
          ..scale(facingOf(s.side).toDouble(), 1);
        body.render(
          canvas,
          size: bodySize,
          anchor: Anchor.bottomCenter,
          overridePaint: _paint,
        );
        canvas.restore();
      }
    }
  }
}
