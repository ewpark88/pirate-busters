import 'package:flutter/material.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/battle/battle_session.dart';
import 'package:pirate_busters/battle/battle_setup.dart';
import 'package:pirate_busters/input/pull_aim.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';
import 'package:pirate_busters/ui/hud/hud_style.dart';

/// 아래 가운데: 선실 해적 카드 (설계서 §13.4). 카드를 누른 채 당기면 조준하고 놓으면
/// 쏜다 (설계서 §2.2). 쿨다운·잠긴 선실·쓰러진 해적은 흐리게 잠근다.
class PirateCards extends StatelessWidget {
  const PirateCards({required this.session, required this.side, super.key});

  final BattleSession session;

  /// 카드를 보여줄 진영(내 배, 핫시트면 지금 턴 진영).
  final int side;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = session.state;
    final firesLeft = state.activeSide == side
        ? state.rules.firesPerTurn - state.firesThisTurn
        : state.rules.firesPerTurn;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        HudPanel(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: Text(l10n.firesLeft(firesLeft)),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var slot = 0; slot < state.sides[side].crew.size; slot++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: _PirateCard(session: session, side: side, slot: slot),
              ),
          ],
        ),
      ],
    );
  }
}

class _PirateCard extends StatefulWidget {
  const _PirateCard({
    required this.session,
    required this.side,
    required this.slot,
  });

  final BattleSession session;
  final int side;
  final int slot;

  @override
  State<_PirateCard> createState() => _PirateCardState();
}

class _PirateCardState extends State<_PirateCard> {
  late final PullAim _aim = PullAim(facing: facingOf(widget.side));
  Offset _start = Offset.zero;

  BattleSession get _s => widget.session;

  bool get _ready =>
      _s.state.activeSide == widget.side && _s.canFire(widget.slot);

  void _onStart(DragStartDetails d) {
    if (!_ready) return;
    _start = d.localPosition;
    _aim.start();
  }

  void _onUpdate(DragUpdateDetails d) {
    if (!_aim.isActive) return;
    final delta = d.localPosition - _start;
    _aim.drag(delta.dx, delta.dy);
    _s.setAim(widget.slot, _aim.shot, _aim.stretch);
  }

  void _onEnd(DragEndDetails d) {
    final shot = _aim.release();
    if (shot == null || !_ready) {
      _s.clearAim();
      return;
    }
    _s.fire(widget.slot, shot.angle, shot.power);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final side = _s.state.sides[widget.side];
    final pirate = side.crew.pirates[widget.slot];
    final species = BattleSetup.speciesOf(pirate.spec.id);
    final team = widget.side == 0 ? 'blue' : 'red';
    final note = switch (pirate.status) {
      PirateStatus.down => l10n.pirateDown,
      PirateStatus.swimming => l10n.pirateSwimming,
      PirateStatus.aboard when side.isCabinFlooded(widget.slot) =>
        l10n.cabinFlooded,
      PirateStatus.aboard when pirate.cooldown > 0 => l10n.cooldown(
        pirate.cooldown,
      ),
      PirateStatus.aboard => null,
    };
    final aiming = _s.aim?.slot == widget.slot;
    final picked = _s.preselected == widget.slot;
    return GestureDetector(
      // 상대 턴에는 다음 턴 해적을 미리 고를 수 있다 (설계서 §13.4).
      onTap: _s.isHumanTurn ? null : () => _s.preselect(widget.slot),
      onPanStart: _onStart,
      onPanUpdate: _onUpdate,
      onPanEnd: _onEnd,
      onPanCancel: _s.clearAim,
      child: Opacity(
        opacity: _ready ? 1 : 0.45,
        child: Container(
          width: 72,
          height: 88,
          decoration: BoxDecoration(
            color: HudColors.panel,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: aiming || picked
                  ? HudColors.warn
                  : HudColors.team(widget.side),
              width: aiming || picked ? 3 : 1.5,
            ),
          ),
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Image.asset(
                    'assets/images/ui/portraits/${species}_$team.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              if (note != null)
                Container(
                  width: double.infinity,
                  color: HudColors.panel,
                  child: Text(
                    note,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: HudColors.text,
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
