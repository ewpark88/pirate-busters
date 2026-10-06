import 'dart:async';

import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/battle/battle_session.dart';
import 'package:pirate_busters/game/battle_game.dart';
import 'package:pirate_busters/input/aim_mode.dart';
import 'package:pirate_busters/input/aim_ticks.dart';
import 'package:pirate_busters/input/pull_aim.dart';

/// 전장 위 제스처 (설계서 §2.1, §2.2, ADR-033): 배 위 해적을 한 손가락으로 끌면
/// 조준하고 놓으면 쏜다. 두 손가락은 핀치 줌. 탭은 해적 고르기·선택 풀기, 비행 중이면 `TAP`.
/// mozzi lib/game/input/play_input.dart 의 라우팅(발사 전 당기기 / 비행 중 탭)을 따른다.
class FieldGestures extends StatefulWidget {
  const FieldGestures({
    required this.game,
    required this.session,
    required this.child,
    super.key,
  });

  final BattleGame game;
  final BattleSession session;
  final Widget child;

  @override
  State<FieldGestures> createState() => _FieldGesturesState();
}

class _FieldGesturesState extends State<FieldGestures> {
  PullAim? _aim;
  int _slot = 0;
  Offset _start = Offset.zero;
  bool _pinching = false;

  /// 힘 링 눈금마다 가벼운 진동, 최대 힘에서 딸깍 (설계서 §10.4 발사).
  final AimTicks _ticks = AimTicks();

  /// 당김 입력 시각(놓을 때 미끄러짐을 걸러 낸다).
  final Stopwatch _clock = Stopwatch()..start();

  BattleSession get _s => widget.session;

  void _onStart(ScaleStartDetails d) {
    if (d.pointerCount >= 2) {
      _pinching = true;
      widget.game.pinchStart();
      return;
    }
    final slot = widget.game.pirateAt(
      Vector2(d.localFocalPoint.dx, d.localFocalPoint.dy),
    );
    if (slot == null || !_s.canFire(slot)) return;
    _s.select(slot, toggle: false);
    _slot = slot;
    _start = d.localFocalPoint;
    final me = _s.state.sides[_s.state.activeSide];
    final (lo, hi) = aimRangeFor(me.crew.pirates[slot].spec);
    _aim = PullAim(
      facing: facingOf(_s.state.activeSide),
      minAngle: lo,
      maxAngle: hi,
    )..start();
    _ticks.reset();
  }

  void _onUpdate(ScaleUpdateDetails d) {
    if (d.pointerCount >= 2) {
      if (!_pinching) {
        _pinching = true;
        _cancelAim();
        widget.game.pinchStart();
      }
      widget.game.pinchUpdate(d.scale);
      return;
    }
    final aim = _aim;
    if (aim == null) return;
    final delta = d.localFocalPoint - _start;
    aim.drag(delta.dx, delta.dy, ms: _clock.elapsedMilliseconds);
    _s.setAim(_slot, aim.shot, aim.stretch, cancelling: aim.isCancelling);
    final tick = _ticks.update(
      aim.isCancelling ? 0 : aim.shot.power,
      maxFirePower,
    );
    if (tick != null && widget.game.vibrationOn.value) {
      unawaited(
        tick == AimTick.full
            ? HapticFeedback.mediumImpact()
            : HapticFeedback.selectionClick(),
      );
    }
  }

  void _onEnd(ScaleEndDetails d) {
    _pinching = false;
    final shot = _aim?.release(ms: _clock.elapsedMilliseconds);
    _aim = null;
    if (shot == null) {
      _s.clearAim();
      return;
    }
    _s.fire(_slot, shot.angle, shot.power);
  }

  /// 탭: 비행 중이면 `TAP`, 아니면 배 위 해적을 고르거나 빈 곳이면 선택을 푼다
  /// (설계서 §2.2, §13.4).
  void _onTap(TapUpDetails d) {
    if (_s.playback != null) {
      widget.game.tap(Vector2(d.localPosition.dx, d.localPosition.dy));
      return;
    }
    final slot = widget.game.pirateAt(
      Vector2(d.localPosition.dx, d.localPosition.dy),
    );
    _s.select(slot, toggle: false);
  }

  void _cancelAim() {
    _aim = null;
    _s.clearAim();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTapUp: _onTap,
    onScaleStart: _onStart,
    onScaleUpdate: _onUpdate,
    onScaleEnd: _onEnd,
    child: widget.child,
  );
}
