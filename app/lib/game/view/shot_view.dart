import 'dart:ui';

import 'package:flame/components.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/battle/battle_session.dart';
import 'package:pirate_busters/battle/playback.dart';
import 'package:pirate_busters/battle/session_views.dart';
import 'package:pirate_busters/game/anim/rarity_fx.dart';
import 'package:pirate_busters/game/coords.dart';
import 'package:pirate_busters/game/sprites.dart';
import 'package:pirate_busters/game/view/aim_painter.dart';
import 'package:pirate_busters/game/view/trail_painter.dart';
import 'package:pirate_busters/game/weapon_styles.dart';
import 'package:pirate_busters/input/pull_aim.dart';

/// 날아가는 탄, 조준 궤적(앞 30% 점선), 이동 끝 지점 점선, 이동 한계 부표.
/// 모두 시뮬레이션 값으로 그린다 (개발 계획서 M4).
class ShotView extends Component {
  ShotView({
    required this.session,
    required this.sprites,
    this.weapons,
    this.rarity = const RarityFx({}),
    super.priority,
  });

  final BattleSession session;
  final BattleSprites sprites;

  /// 등급별 연출 값: 조준 점선 색, 발사체 꼬리 (설계서 §10.5).
  final RarityFx rarity;

  /// 해적별 투사체 그림. 없으면 모두 공용 포탄(테스트).
  final WeaponStyles? weapons;

  /// 지금 날고 있는 탄들의 월드 위치.
  List<Vector2> get projectiles {
    final p = session.playback;
    if (p is! ShotPlayback) return const [];
    final t = p.tick;
    return [
      for (final trace in p.traces)
        if (t >= trace.startTick && t < trace.endTick) _at(trace, t),
    ];
  }

  /// 카메라가 따라갈 탄: 날고 있는 탄 중 가장 앞선(표적 쪽으로 가장 멀리 간) 탄.
  /// 없으면 null (설계서 §2.1).
  Vector2? get projectile {
    final p = session.playback;
    final all = projectiles;
    if (p is! ShotPlayback || all.isEmpty) return null;
    final facing = facingOf(p.side).toDouble();
    return all.reduce((a, b) => a.x * facing >= b.x * facing ? a : b);
  }

  /// 강습 해적의 몸 그림. 강습탄은 해적 자신이 날아가 착지한다 (설계서 §10.4).
  final Map<String, Sprite> _bodies = {};

  @override
  Future<void> onLoad() async {
    final images = findGame()!.images;
    for (final side in session.state.sides) {
      for (final pirate in side.crew.pirates) {
        if (pirate.spec.ammo != AmmoType.assault) continue;
        final id = session.speciesOf(pirate.spec.id);
        final team = side.side == 0 ? 'blue' : 'red';
        _bodies['${side.side}/$id'] = Sprite(
          await images.load('characters/$id/${id}_${team}_battle.png'),
        );
      }
    }
  }

  /// 날고 있는 탄마다 그 해적의 무기 그림(분열 조각·소형 폭탄은 따로)을 그린다.
  void _renderShots(Canvas canvas) {
    final p = session.playback;
    if (p is! ShotPlayback) return;
    final t = p.tick;
    final spec = session.state.sides[p.side].crew.pirates[p.slot].spec;
    final own = weapons?.of(session.speciesOf(spec.id));
    final tier = rarity.of(spec.rarity);
    final sec = t / simTickHz;
    for (final (i, trace) in p.traces.indexed) {
      if (t < trace.startTick || t >= trace.endTick) continue;
      final pos = _at(trace, t);
      final style = i == 0
          ? own
          : switch (spec.ammo) {
              AmmoType.split => WeaponStyles.splitShard,
              AmmoType.flock => WeaponStyles.bomblet,
              _ => own,
            };
      // 고유 꼬리 위에 등급 꼬리를 겹친다 (설계서 §10.1, §10.5). 물속은 등급색 거품.
      final tail = _tail(trace, t);
      TrailPainter.base(
        canvas,
        tail,
        style == null ? 'smoke' : style.trail,
        sec,
        color: style?.trailColor,
      );
      TrailPainter.tier(canvas, tail, tier, sec, water: pos.y > 0);
      final body = _bodies['${p.side}/${session.speciesOf(spec.id)}'];
      if (body != null) {
        canvas
          ..save()
          ..translate(pos.x, pos.y)
          ..scale(facingOf(p.side).toDouble(), 1);
        body.render(
          canvas,
          size: Vector2(240, 324) * Coords.pirateScale,
          anchor: Anchor.center,
        );
        canvas.restore();
        continue;
      }
      final w = weapons;
      if (style == null || w == null) {
        sprites
            .get('fx/cannonball.png')
            .render(
              canvas,
              position: pos,
              size: Vector2.all(18),
              anchor: Anchor.center,
            );
        continue;
      }
      final ahead = _at(trace, t + 0.5) - pos;
      final seconds = (t - trace.startTick) / simTickHz;
      canvas
        ..save()
        ..translate(pos.x, pos.y)
        ..rotate(style.angle(seconds, ahead.x, ahead.y));
      w
          .sprite(style)
          .render(canvas, size: Vector2(32, 24), anchor: Anchor.center);
      canvas.restore();
    }
  }

  /// 꼬리 점 수와 점 사이 간격(틱). 지나온 약 0.16초를 오래된 것부터 담는다.
  static const int tailPoints = 12;
  static const double tailStep = 0.4;

  static List<Offset> _tail(ShotTrace trace, double tick) => [
    for (var k = tailPoints; k >= 0; k--)
      if (tick - k * tailStep >= trace.startTick)
        _at(trace, tick - k * tailStep).toOffset(),
  ];

  static Vector2 _at(ShotTrace trace, double tick) {
    final last = trace.xs.length - 1;
    final t = (tick - trace.startTick).clamp(0, last.toDouble());
    final i = t.floor();
    final j = i + 1 > last ? i : i + 1;
    final f = t - i;
    return Vector2(
      Coords.x(trace.xs[i] + (trace.xs[j] - trace.xs[i]) * f),
      Coords.y(trace.ys[i] + (trace.ys[j] - trace.ys[i]) * f),
    );
  }

  static final Paint _limitPaint = Paint()..color = const Color(0xFFE8C9A0);
  static final Paint _movePaint = Paint()
    ..color = const Color(0xCCFFFFFF)
    ..strokeWidth = 2;

  @override
  void render(Canvas canvas) {
    _renderLimits(canvas);
    _renderMovePreview(canvas);
    _renderAim(canvas);
    _renderShots(canvas);
  }

  void _renderAim(Canvas canvas) {
    final aim = session.aim;
    if (aim == null || !session.isHumanTurn) return;
    // 놓아도 쏘지 않을 만큼 약하면 궤적을 숨긴다(취소 표시는 HUD).
    if (aim.shot.power < PullAim.minPower) return;
    // 상대 턴 재생에는 궤적을 그리지 않는다 (설계서 §13.4).
    final path = session
        .previewShot(aim.slot, aim.shot.angle, aim.shot.power)
        .head(30);
    _renderRangeEnd(canvas, aim.slot, path.xs.first);
    // 점선은 멀어질수록 흐려지고 색은 등급을 따른다 (설계서 §10.4, §10.5).
    final side = session.state.activeSide;
    final spec = session.state.sides[side].crew.pirates[aim.slot].spec;
    final color = rarity.of(spec.rarity).aim;
    final pts = [
      for (var i = 0; i <= path.lastTick; i += 2)
        Coords.point(path.xs[i], path.ys[i]).toOffset(),
    ];
    // 첫 점은 발사 지점(해적 몸)이라 고무줄·호·링이 대신한다.
    AimPainter.trajectory(canvas, pts.sublist(1), color);
    AimPainter.sling(
      canvas,
      pts.first,
      facing: facingOf(side),
      angleMdeg: aim.shot.angle,
      stretch: aim.stretch,
      power: aim.shot.power / maxFirePower,
      color: color,
    );
  }

  static final Paint _rangePaint = Paint()
    ..color = const Color(0xCCFFC24A)
    ..strokeWidth = 2;

  /// 사거리 끝: 발사 지점에서 사거리(칸)만큼 앞 물 위의 점선과 부표 (설계서 §2.8).
  void _renderRangeEnd(Canvas canvas, int slot, int launchX) {
    final state = session.state;
    final side = state.activeSide;
    final range = state.sides[side].crew.pirates[slot].spec.range;
    final x = Coords.x(launchX + facingOf(side) * range.cells * cellUnit);
    for (var y = -36.0; y < 8; y += 8) {
      canvas.drawLine(Offset(x, y), Offset(x, y + 4), _rangePaint);
    }
    canvas.drawCircle(Offset(x, -40), 4, _rangePaint);
  }

  void _renderMovePreview(Canvas canvas) {
    final dx = session.movePreviewDx;
    if (dx == 0) return;
    final side = session.state.sides[session.state.activeSide];
    final x = Coords.x(side.bowX + dx * moveStep);
    for (var y = -40.0; y < 12; y += 8) {
      canvas.drawLine(Offset(x, y), Offset(x, y + 4), _movePaint);
    }
  }

  static final Paint _reef = Paint()..color = const Color(0xFF3A2E3F);
  static final Paint _rope = Paint()
    ..color = const Color(0xFFE8C9A0)
    ..strokeWidth = 1.5;
  static final Paint _buoyRed = Paint()..color = const Color(0xFFB3302B);

  /// 한계선 (설계서 §2.6): 전진 한계는 암초와 부표 줄, 후퇴 한계는 부표.
  void _renderLimits(Canvas canvas) {
    final state = session.state;
    final (lo, hi) = moveLimits(state.rules, state.turn);
    for (final side in state.sides) {
      final facing = facingOf(side.side);
      final start = startBowX(side.side);
      _renderReef(canvas, Coords.x(start + facing * hi), facing);
      _renderBuoy(canvas, Coords.x(start + facing * lo));
    }
  }

  /// 전진 한계: 물 위로 솟은 암초 두 덩이와 그 사이 부표 줄.
  void _renderReef(Canvas canvas, double x, int facing) {
    final ahead = facing * 20.0;
    canvas
      ..drawPath(
        Path()
          ..moveTo(x + ahead - 16, 6)
          ..lineTo(x + ahead - 8, -14)
          ..lineTo(x + ahead + 2, -8)
          ..lineTo(x + ahead + 12, -20)
          ..lineTo(x + ahead + 20, 6)
          ..close(),
        _reef,
      )
      ..drawLine(Offset(x - 40, -3), Offset(x + 40, -3), _rope);
    for (var d = -40.0; d <= 40; d += 20) {
      canvas.drawCircle(Offset(x + d, -3), 3.5, _limitPaint);
    }
  }

  /// 후퇴 한계: 줄무늬 부표 하나.
  void _renderBuoy(Canvas canvas, double x) {
    canvas
      ..drawRect(Rect.fromLTWH(x - 1.5, -30, 3, 26), _limitPaint)
      ..drawOval(
        Rect.fromCenter(center: Offset(x, -6), width: 16, height: 12),
        _buoyRed,
      )
      ..drawRect(Rect.fromLTWH(x - 8, -8, 16, 3), _limitPaint);
  }
}
