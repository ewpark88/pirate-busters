import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/battle/battle_session.dart';
import 'package:pirate_busters/battle/playback.dart';
import 'package:pirate_busters/battle/session_views.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';
import 'package:pirate_busters/ui/hud/hud_style.dart';

/// 아래 왼쪽: ◀ 후퇴 · 연료 게이지 · 전진 ▶ (설계서 §2.2, §2.6, §2.7, §13.4).
///
/// 버튼을 누르고 있는 동안 배가 움직이고 그동안 턴 타이머도 흐른다 (ADR-030).
/// 앞 이동이 끝날 때마다 1/10칸짜리 `MOVE` 를 이어서 낸다. 누르고 있으면 갈 수 있는
/// 끝 지점을 전장에 점선으로 보여준다. 연료가 0 이면 버튼을 잠그고 게이지를 깜빡인다.
class MoveControls extends StatefulWidget {
  const MoveControls({required this.session, required this.side, super.key});

  final BattleSession session;
  final int side;

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
      _s.playback is! ShotPlayback;

  void _press(int dir) {
    if (!_enabled) return;
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
    final tank = _me.grid.hull.fuelTank * SideState.fuelUnit;
    final empty = _me.fuel <= 0;
    return HudPanel(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 왼쪽 버튼은 화면 왼쪽으로 간다: 왼쪽 배는 후퇴, 오른쪽 배는 전진.
          _HoldButton(
            label: _facing > 0 ? l10n.retreat : l10n.advance,
            icon: Icons.chevron_left,
            enabled: _enabled,
            onDown: () => _press(-_facing),
            onUp: _release,
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.fuel, style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 2),
              SizedBox(
                width: 70,
                child: _Blink(
                  on: empty,
                  child: LinearProgressIndicator(
                    value: _me.fuel / tank,
                    minHeight: 8,
                    color: HudColors.warn,
                    backgroundColor: HudColors.panelHi,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          _HoldButton(
            label: _facing > 0 ? l10n.advance : l10n.retreat,
            icon: Icons.chevron_right,
            enabled: _enabled,
            onDown: () => _press(_facing),
            onUp: _release,
          ),
        ],
      ),
    );
  }
}

class _HoldButton extends StatelessWidget {
  const _HoldButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onDown,
    required this.onUp,
  });

  final String label;
  final IconData icon;
  final bool enabled;
  final VoidCallback onDown;
  final VoidCallback onUp;

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
          Icon(icon, color: HudColors.text, size: 30),
          Text(label, style: const TextStyle(fontSize: 12)),
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
