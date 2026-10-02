import 'dart:ui';

import 'package:flame/components.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/battle/battle_session.dart';
import 'package:pirate_busters/battle/playback.dart';
import 'package:pirate_busters/battle/session_views.dart';
import 'package:pirate_busters/game/anim/rarity_fx.dart';
import 'package:pirate_busters/game/coords.dart';
import 'package:pirate_busters/game/sprites.dart';
import 'package:pirate_busters/game/view/aim_labels.dart';
import 'package:pirate_busters/game/view/aim_painter.dart';
import 'package:pirate_busters/game/view/guide_marks.dart';
import 'package:pirate_busters/game/view/trail_painter.dart';
import 'package:pirate_busters/game/weapon_styles.dart';
import 'package:pirate_busters/input/aim_mode.dart';
import 'package:pirate_busters/input/pull_aim.dart';

/// 날아가는 탄, 조준 궤적(앞 20% 점선), 이동 끝 지점 점선. 이동 한계 표식은
/// 배 뒤에 그리는 `LimitMarks` 가 맡는다.
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
      // 멀리 뺀 화면에서도 탄이 보이게 키우고 밝은 테두리를 두른다 (설계서 §10.4).
      final grow = visibleScale(_zoom);
      _halo(canvas, pos, 11 * grow);
      final w = weapons;
      if (style == null || w == null) {
        sprites
            .get('fx/cannonball.png')
            .render(
              canvas,
              position: pos,
              size: Vector2.all(18 * grow),
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
          .render(
            canvas,
            size: Vector2(32, 24) * grow,
            anchor: Anchor.center,
          );
      canvas.restore();
    }
  }

  /// 탄이 화면에서 차지할 최소 크기(논리 px). 공용 포탄 18 월드 px 기준.
  static const double minScreenPx = 22;

  /// 지금 카메라 줌(월드 1px 이 화면 몇 px 인가). 게임 밖(테스트)이면 1.
  double get _zoom {
    final game = findGame();
    return game == null ? 1 : game.camera.viewfinder.zoom;
  }

  /// 줌 [zoom] 에서 탄을 키울 배율. 화면에서 [minScreenPx] 보다 작아지지 않는다.
  static double visibleScale(double zoom) =>
      zoom <= 0 ? 1 : (minScreenPx / (18 * zoom)).clamp(1, 8).toDouble();

  static final Paint _haloFill = Paint()..color = const Color(0x99FFF4C2);
  static final Paint _haloRing = Paint()
    ..color = const Color(0xCC14161C)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;

  /// 탄 뒤의 밝은 원과 어두운 테두리. 바다·하늘 어디서나 구분된다.
  static void _halo(Canvas canvas, Vector2 pos, double r) {
    final c = pos.toOffset();
    canvas
      ..drawCircle(c, r, _haloFill)
      ..drawCircle(c, r, _haloRing);
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

  @override
  void render(Canvas canvas) {
    GuideMarks.movePreview(canvas, session);
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
        .head(
          trailPercentFor(
            session.state.sides[session.state.activeSide],
            aim.slot,
            base: previewPercent,
          ),
        );
    GuideMarks.rangeEnd(canvas, session, aim.slot, path.xs.first);
    // 점선은 멀어질수록 흐려지고 색은 등급을 따른다 (설계서 §10.4, §10.5).
    final side = session.state.activeSide;
    final spec = session.state.sides[side].crew.pirates[aim.slot].spec;
    final color = rarity.of(spec.rarity).aim;
    final path2 = [
      for (var i = 0; i <= path.lastTick; i++)
        Coords.point(path.xs[i], path.ys[i]).toOffset(),
    ];
    // 점은 호 길이로 고르게, 힘 링 바깥부터 찍고 발사 방향으로 흐른다. 저사양은 멈춘다.
    const step = AimPainter.dotStep;
    final phase = fewer ? 0.0 : (_flow * AimPainter.flowSpeed) % step;
    final dots = AimPainter.resample(
      path2,
      step,
      skip: AimPainter.dotSkip,
      phase: phase,
    );
    AimPainter.trajectory(
      canvas,
      dots,
      color,
      fadeIn: fewer ? 1 : phase / step,
    );
    final from = path2.first;
    final facing = facingOf(side);
    // 호·새총·각도 숫자는 실제 발사 방향(조준 각도 + 배 기울기)을 따라 점선과
    // 한 줄로 맞는다 (설계서 §2.5).
    final launch = aim.shot.angle + session.launchTilt;
    AimPainter.sling(
      canvas,
      from,
      facing: facing,
      angleMdeg: launch,
      stretch: aim.stretch,
      power: aim.shot.power / maxFirePower,
      color: color,
    );
    AimLabels.draw(
      canvas,
      from,
      angle: angleText(shownDegrees(launch)),
      power: powerText((aim.shot.power * 100 / maxFirePower).round()),
    );
  }

  /// 궤적 점선으로 보여 주는 앞부분 비율(%) (설계서 §2.2).
  static const int previewPercent = 20;

  /// 조준 숫자 글자 (설계서 §10.4). 화면이 l10n 으로 바꿔 넣는다.
  String Function(int degrees) angleText = (d) => '$d°';
  String Function(int percent) powerText = (p) => '$p%';

  /// 저사양 모드: 점선 흐름을 멈춘다 (설계서 §12).
  bool fewer = false;
  double _flow = 0;

  @override
  void update(double dt) => _flow += dt;

  /// 뱃머리가 [bowX] 일 때 고물 x(시뮬레이션 단위). 후퇴 한계 부표와 물살은
  /// 뱃머리가 한계에 닿았을 때의 고물 자리에 둔다 (설계서 §2.6).
  static int sternAt(int bowX, int facing, int widthCells) =>
      bowX - facing * widthCells * cellUnit;
}
