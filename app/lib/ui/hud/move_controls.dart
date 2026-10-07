import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/battle/battle_session.dart';
import 'package:pirate_busters/battle/playback.dart';
import 'package:pirate_busters/battle/session_views.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';
import 'package:pirate_busters/ui/hud/hud_gauge.dart';
import 'package:pirate_busters/ui/hud/hud_style.dart';
import 'package:pirate_busters/ui/meta_icons.dart';

/// 아래 왼쪽: ◀ 후퇴 · 연료 게이지 · 전진 ▶ (설계서 §2.2, §2.6, §2.7, §13.4).
///
/// 버튼을 누르고 있는 동안 배가 움직이고 그동안 턴 타이머도 흐른다 (ADR-030).
/// 앞 이동이 끝날 때마다 1/10칸짜리 `MOVE` 를 이어서 낸다. 누르고 있으면 갈 수 있는
/// 끝 지점을 전장에 점선으로 보여준다. 연료가 0 이면 버튼을 잠그고 게이지를 깜빡인다.
class MoveControls extends StatefulWidget {
  const MoveControls({
    required this.session,
    required this.side,
    this.onClick,
    super.key,
  });

  final BattleSession session;
  final int side;

  /// 버튼 누름 소리 (설계서 §10.3).
  final VoidCallback? onClick;

  @override
  State<MoveControls> createState() => _MoveControlsState();
}

class _MoveControlsState extends State<MoveControls>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  int _dir = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
  }

  BattleSession get _s => widget.session;

  SideState get _me => _s.state.sides[widget.side];

  int get _facing => facingOf(widget.side);

  bool get _enabled =>
      !_s.isOver &&
      _s.isHumanTurn &&
      _s.state.activeSide == widget.side &&
      _me.fuel > 0 &&
      !_me.moveLocked &&
      _s.playback is! ShotPlayback;

  void _press(int dir) {
    if (!_enabled) return;
    widget.onClick?.call();
    _dir = dir;
    _s.moveHeld = true;
    unawaited(_ticker.start());
  }

  void _onTick(Duration elapsed) {
    if (_dir == 0) return;
    // 갈 수 있는 끝 지점(연료·한계선·남은 시간).
    _s.setMovePreview(_s.reach(_dir * 1000) ~/ moveStep);
    if (_s.playback == null) _s.move(_dir);
    if (!_enabled || _s.reach(_dir) == 0) _release();
  }

  void _release() {
    if (_dir == 0) return;
    _ticker.stop();
    _dir = 0;
    _s
      ..moveHeld = false
      ..setMovePreview(0);
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // 상한은 연료통 모듈까지 더한 pb_sim 의 탱크다 (설계서 §2.7, 절대 규칙 3).
    final tank = _me.tank;
    final empty = _me.fuel <= 0;
    final team = HudColors.team(widget.side);
    final ratio = tank == 0 ? 0.0 : (_me.fuel / tank).clamp(0.0, 1.0);
    // 누르고 있으면 갈 수 있는 끝까지 갔을 때 남을 연료를 미리 보인다 (A33).
    final preview = _dir == 0 || tank == 0
        ? null
        : ((_me.fuel - fuelFor(_me, _s.reach(_dir * 1000))) / tank).clamp(
            0.0,
            1.0,
          );
    return HudPanel(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 왼쪽 버튼은 화면 왼쪽으로 간다: 왼쪽 배는 후퇴, 오른쪽 배는 전진.
          _HoldButton(
            label: _facing > 0 ? l10n.retreat : l10n.advance,
            icon: MetaIcons.moveBack,
            color: team,
            enabled: _enabled,
            held: _dir == -_facing,
            onDown: () => _press(-_facing),
            onUp: _release,
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 모비에게 끌려와 묶인 턴이면 연료 대신 ‘묶임’ (설계서 §4.8).
              Text(
                _me.moveLocked ? l10n.moveLocked : l10n.fuel,
                style: TextStyle(
                  fontSize: 12,
                  color: _me.moveLocked ? HudColors.danger : null,
                ),
              ),
              const SizedBox(height: 3),
              SizedBox(
                width: 96,
                child: _Blink(
                  on: empty,
                  child: Opacity(
                    opacity: _me.moveLocked ? .45 : 1,
                    child: HudGauge(
                      key: ValueKey('fuel-${widget.side}'),
                      value: ratio,
                      color: HudColors.warn,
                      preview: preview,
                      warnAt: lowFuel,
                      jolts: false,
                      label: l10n.fuelPercent((ratio * 100).round()),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          _HoldButton(
            label: _facing > 0 ? l10n.advance : l10n.retreat,
            icon: MetaIcons.moveForward,
            color: team,
            enabled: _enabled,
            held: _dir == _facing,
            onDown: () => _press(_facing),
            onUp: _release,
          ),
        ],
      ),
    );
  }

  /// 이 비율 이하면 연료 게이지가 경고색이 된다 (A33).
  static const double lowFuel = .2;
}

/// 누르고 있는 동안 움직이는 둥근 버튼 (A33): 진영색 테, 누르면 작아지며 안쪽이
/// 밝게 빛난다. 잠기면 흐려진다.
class _HoldButton extends StatelessWidget {
  const _HoldButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.enabled,
    required this.held,
    required this.onDown,
    required this.onUp,
  });

  final String label;

  /// 화면 방향 화살표 그림 (`MetaIcons.moveBack` ← · `moveForward` →).
  final String icon;
  final Color color;
  final bool enabled;

  /// 지금 누르고 있다.
  final bool held;
  final VoidCallback onDown;
  final VoidCallback onUp;

  static const double size = 50;

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: (_) => onDown(),
    onPointerUp: (_) => onUp(),
    onPointerCancel: (_) => onUp(),
    child: Opacity(
      opacity: enabled ? 1 : 0.4,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedScale(
            scale: held ? .9 : 1,
            duration: const Duration(milliseconds: 80),
            child: Container(
              width: size,
              height: size,
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: const Alignment(0, -.35),
                  colors: held
                      ? [Color.lerp(color, Colors.white, .45)!, color]
                      : [HudColors.panelHi, const Color(0xFF101217)],
                ),
                border: Border.all(color: color, width: 2.5),
                boxShadow: [
                  if (held)
                    BoxShadow(
                      color: color.withValues(alpha: .7),
                      blurRadius: 10,
                    )
                  else
                    const BoxShadow(
                      color: Color(0x99000000),
                      offset: Offset(0, 2),
                      blurRadius: 2,
                    ),
                ],
              ),
              child: MetaIcons.image(icon, size: 30),
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    ),
  );
}

/// 켜져 있으면 깜빡인다.
class _Blink extends StatefulWidget {
  const _Blink({required this.on, required this.child});

  final bool on;
  final Widget child;

  @override
  State<_Blink> createState() => _BlinkState();
}

class _BlinkState extends State<_Blink> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );

  @override
  void initState() {
    super.initState();
    if (widget.on) unawaited(_c.repeat(reverse: true));
  }

  @override
  void didUpdateWidget(_Blink old) {
    super.didUpdateWidget(old);
    if (widget.on && !_c.isAnimating) {
      unawaited(_c.repeat(reverse: true));
    } else if (!widget.on && _c.isAnimating) {
      _c
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: Tween<double>(begin: 1, end: 0.2).animate(_c),
    child: widget.child,
  );
}
