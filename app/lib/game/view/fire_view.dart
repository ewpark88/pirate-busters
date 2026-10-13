import 'dart:ui';

import 'package:flame/components.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/battle/battle_session.dart';
import 'package:pirate_busters/battle/playback.dart';
import 'package:pirate_busters/game/coords.dart';
import 'package:pirate_busters/game/sprites.dart';
import 'package:pirate_busters/game/view/ship_view.dart';

/// 불붙은 블록과 그을린 블록 (설계서 §2.5, §10.4, 에셋 v0.23 `ship/tiles_v2/burn_*`·
/// `charred`). `ShipView` 의 자식이라 배의 이동·뒤집기·기울기를 그대로 따른다.
///
/// 불은 시뮬레이션 칸별 지속 턴(`SideState.fireTurns`)을 그리기만 한다. 탄이 날아가는
/// 동안에는 직전 모습을 고정해 착탄 전에 불이 먼저 보이지 않게 한다. 불이 꺼진 칸은
/// 기억했다가 블록이 남아 있는 동안 그을린 그림을 덧그린다(시뮬레이션은 기록하지 않음).
class FireView extends Component {
  FireView({required this.session, required this.side, required this.sprites})
    : super(priority: -1);

  final BattleSession session;
  final int side;
  final BattleSprites sprites;

  /// 불꽃 3프레임 한 장의 시간(초).
  static const double frameSec = 0.12;

  /// 불꽃 그림은 칸보다 위로 솟는다: 64×76 @2x → 32×38, 위로 6px.
  static const double flameHeight = 38;

  static List<String> get files => [
    for (var i = 0; i < 3; i++) 'ship/tiles_v2/burn_$i.png',
    'ship/tiles_v2/charred.png',
  ];

  List<int> _shown = const [];
  final Set<int> charred = {};
  double _t = 0;

  SideState get _ship => session.state.sides[side];

  /// 지금 그리는 불 칸(지속 턴 > 0).
  List<int> get burning => [
    for (var i = 0; i < _shown.length; i++)
      if (_shown[i] > 0) i,
  ];

  @override
  void update(double dt) {
    _t += dt;
    if (session.playback is ShotPlayback && _shown.isNotEmpty) return;
    final grid = _ship.grid;
    final now = _ship.fireTurns;
    for (var i = 0; i < now.length; i++) {
      final was = i < _shown.length && _shown[i] > 0;
      if (was && now[i] == 0 && grid.hasBlockAt(i)) charred.add(i);
      if (!grid.hasBlockAt(i) || now[i] > 0) charred.remove(i);
    }
    _shown = List.of(now);
  }

  @override
  void render(Canvas canvas) {
    final grid = _ship.grid;
    final w = grid.width;
    Rect cell(int i) => Rect.fromLTWH(
      (i % w - w / 2) * Coords.cell,
      -(i ~/ w + 1) * Coords.cell,
      Coords.cell,
      Coords.cell,
    );
    final soot = sprites.get('ship/tiles_v2/charred.png');
    for (final i in charred) {
      if (!grid.hasBlockAt(i)) continue;
      final r = cell(i);
      soot.render(
        canvas,
        position: Vector2(r.left, r.top),
        size: Vector2.all(Coords.cell),
        overridePaint: _soot,
      );
    }
    // 저사양은 불꽃을 두 장만, 절반 빠르기로 바꾼다 (설계서 §10.4 저사양, A57).
    final low = parent is ShipView && (parent! as ShipView).fewer;
    final frame = low
        ? (_t / (frameSec * 2)).floor() % 2 * 2
        : (_t / frameSec).floor() % 3;
    final flame = sprites.get('ship/tiles_v2/burn_$frame.png');
    for (final i in burning) {
      if (!grid.hasBlockAt(i)) continue;
      final r = cell(i);
      flame.render(
        canvas,
        position: Vector2(r.left, r.bottom - flameHeight),
        size: Vector2(Coords.cell, flameHeight),
      );
      _smoke(canvas, r, i, low ? 1 : 2);
    }
  }

  /// 연기가 오른다 (설계서 §10.4 화재, A54): 불꽃 위로 회색 연기 [puffs] 개가 칸마다
  /// 엇갈린 박자로 떠오르며 커지고 흐려진다. 저사양은 하나.
  void _smoke(Canvas canvas, Rect r, int cell, int puffs) {
    for (var k = 0; k < puffs; k++) {
      final phase = (_t / smokeSec + cell * .37 + k / puffs) % 1;
      final x = r.center.dx + (phase - .5) * 6 + (k.isEven ? -3 : 3);
      final y = r.bottom - flameHeight - phase * smokeRise;
      _smokePaint.color = Color.fromRGBO(70, 66, 62, (1 - phase) * .45);
      canvas.drawCircle(Offset(x, y), 4 + phase * 8, _smokePaint);
    }
  }

  /// 연기 한 줄기가 떠올라 사라지는 시간(초)과 오르는 높이(px).
  static const double smokeSec = 1.6;
  static const double smokeRise = 34;

  static final Paint _soot = Paint()..color = const Color(0xC0FFFFFF);
  static final Paint _smokePaint = Paint();
}
