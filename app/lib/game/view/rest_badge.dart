import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart' show TextStyle;
import 'package:pirate_busters/app/app_theme.dart';
import 'package:pirate_busters/battle/battle_session.dart';
import 'package:pirate_busters/battle/rest_turns.dart';
import 'package:pirate_busters/game/battle_texts.dart';
import 'package:pirate_busters/game/coords.dart';
import 'package:pirate_busters/game/view/ship_view.dart';

/// 쉬는 해적 머리 위 배지 (설계서 §13.4, ADR-102): 모래시계와 남은 쉬는 턴 수.
/// 숫자는 HUD 카드와 같은 [restTurnsOf] 이고, 줄면 짧게 눌리며, 쉬는 턴이 풀린 그
/// 진영 턴이 시작되면 ‘준비!’가 튀어 올랐다 사라진다. 시뮬레이션 상태를 그리기만 한다.
class RestBadges extends Component {
  RestBadges({
    required this.session,
    required this.ships,
    required this.texts,
    super.priority,
  });

  final BattleSession session;
  final List<ShipView> ships;
  final BattleTexts texts;

  /// 눌림·준비 연출 길이(초).
  static const double pressTime = 0.35;
  static const double readyTime = 0.8;

  /// 머리 위 높이(해적 키 배수).
  static const double lift = 1.3;

  /// 진영·슬롯별 마지막으로 보인 숫자, 눌림·준비 연출 남은 시간, 준비 대기.
  final List<List<int>> _shown = [[], []];
  final List<List<double>> _press = [[], []];
  final List<List<double>> _ready = [[], []];
  final List<List<bool>> _pending = [[], []];

  static final Paint _fill = Paint()..color = const Color(0xE614161C);
  static final Paint _ring = Paint()
    ..color = const Color(0xFFFFC24A)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.4;
  static final Paint _sand = Paint()..color = const Color(0xFFFFC24A);
  static final TextPaint _number = TextPaint(
    style: const TextStyle(
      fontFamily: AppFonts.display,
      fontSize: 11,
      color: Color(0xFFFFE082),
    ),
  );

  /// 슬롯 [slot] 의 지금 배지 숫자(0 이면 숨김). 테스트가 본다.
  int shownOf(int side, int slot) =>
      slot < _shown[side].length ? _shown[side][slot] : 0;

  /// 준비 연출 중인가. 테스트가 본다.
  bool readyOf(int side, int slot) =>
      slot < _ready[side].length && _ready[side][slot] > 0;

  @override
  void update(double dt) {
    final state = session.state;
    for (var side = 0; side < 2; side++) {
      final ship = state.sides[side];
      final n = ship.crew.size;
      while (_shown[side].length < n) {
        _shown[side].add(restTurnsOf(ship, _shown[side].length));
        _press[side].add(0);
        _ready[side].add(0);
        _pending[side].add(false);
      }
      for (var slot = 0; slot < n; slot++) {
        _press[side][slot] = math.max(0, _press[side][slot] - dt);
        _ready[side][slot] = math.max(0, _ready[side][slot] - dt);
        final now = restTurnsOf(ship, slot);
        final was = _shown[side][slot];
        if (now < was && now > 0) _press[side][slot] = pressTime;
        // 1 → 0 은 그 진영 턴 끝에 일어난다: 다음 그 진영 턴 시작에 ‘준비!’.
        if (now == 0 && was > 0 && ship.canFire(slot)) {
          _pending[side][slot] = true;
        }
        if (now > 0) _pending[side][slot] = false;
        _shown[side][slot] = now;
        if (_pending[side][slot] &&
            state.activeSide == side &&
            session.playback == null) {
          _pending[side][slot] = false;
          _ready[side][slot] = readyTime;
        }
      }
    }
  }

  @override
  void render(Canvas canvas) {
    for (var side = 0; side < 2 && side < ships.length; side++) {
      final rigs = ships[side].rigs;
      for (var slot = 0; slot < rigs.length; slot++) {
        final rig = rigs[slot];
        if (rig.alpha < 0.5 || slot >= _shown[side].length) continue;
        final at =
            rig.absolutePosition - Vector2(0, Coords.pirateHeight * lift);
        final ready = _ready[side][slot];
        if (ready > 0) {
          _drawReady(canvas, at, 1 - ready / readyTime);
        } else if (_shown[side][slot] > 0) {
          final p = _press[side][slot] / pressTime;
          final scale = 1 - 0.3 * math.sin(math.pi * p);
          _drawBadge(canvas, at, texts.turnsText(_shown[side][slot]), scale);
        }
      }
    }
  }

  /// 모래시계 + 숫자 알약.
  void _drawBadge(Canvas canvas, Vector2 at, String label, double scale) {
    canvas
      ..save()
      ..translate(at.x, at.y)
      ..scale(scale);
    const r = RRect.fromLTRBXY(-13, -8, 13, 8, 8, 8);
    canvas
      ..drawRRect(r, _fill)
      ..drawRRect(r, _ring)
      ..drawPath(_hourglass, _sand);
    _number.render(canvas, label, Vector2(5, 0), anchor: Anchor.center);
    canvas.restore();
  }

  static final Path _hourglass = Path()
    ..moveTo(-9, -5)
    ..lineTo(-3, -5)
    ..lineTo(-6, 0)
    ..close()
    ..moveTo(-6, 0)
    ..lineTo(-3, 5)
    ..lineTo(-9, 5)
    ..close();

  /// ‘준비!’: 튀며 커졌다가 떠오르며 사라진다. [t] 는 0~1 진행.
  void _drawReady(Canvas canvas, Vector2 at, double t) {
    final pop = t < 0.25 ? 0.6 + 0.6 * (t / 0.25) : 1.2 - 0.2 * (t - 0.25);
    final alpha = t < 0.7 ? 1.0 : 1 - (t - 0.7) / 0.3;
    final paint = TextPaint(
      style: TextStyle(
        fontFamily: AppFonts.display,
        fontSize: 15,
        color: Color.fromRGBO(255, 225, 74, alpha),
        shadows: [
          Shadow(
            color: Color.fromRGBO(90, 26, 0, alpha),
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
    canvas
      ..save()
      ..translate(at.x, at.y - 10 * t)
      ..scale(pop);
    paint.render(
      canvas,
      texts.readyText(),
      Vector2.zero(),
      anchor: Anchor.center,
    );
    canvas.restore();
  }
}
