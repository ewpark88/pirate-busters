import 'package:flutter/material.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/battle/battle_session.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';
import 'package:pirate_busters/ui/cards/rarity_card.dart';
import 'package:pirate_busters/ui/cards/rarity_stars.dart';
import 'package:pirate_busters/ui/hud/ammo_label.dart';
import 'package:pirate_busters/ui/hud/hud_style.dart';

/// 아래 가운데: 선실 해적 카드 (설계서 §13.4). 카드를 누르면 그 해적을 고르고
/// 카메라가 줌인한다(설계서 §2.2). 쿨다운·잠긴 선실·쓰러진 해적은 흐리게 보인다.
class PirateCards extends StatelessWidget {
  const PirateCards({required this.session, required this.side, super.key});

  final BattleSession session;

  /// 카드를 보여줄 진영(내 배, 핫시트면 지금 턴 진영).
  final int side;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = session.state;
    // 한 턴 한 발 (설계서 §2.3).
    final firesLeft = state.activeSide == side ? 1 - state.firesThisTurn : 1;
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
  BattleSession get _s => widget.session;

  bool get _ready =>
      _s.state.activeSide == widget.side && _s.canFire(widget.slot);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final side = _s.state.sides[widget.side];
    final pirate = side.crew.pirates[widget.slot];
    final species = _s.speciesOf(pirate.spec.id);
    final team = widget.side == 0 ? 'blue' : 'red';
    final note = switch (pirate.status) {
      PirateStatus.down => l10n.pirateDown,
      PirateStatus.boarding => l10n.pirateBoarding,
      PirateStatus.aboard when side.crew.firedThisTurn[widget.slot] =>
        l10n.firedDone,
      PirateStatus.aboard => null,
    };
    final locale = Localizations.localeOf(context).toLanguageTag();
    final aiming = _s.aim?.slot == widget.slot;
    final picked = _s.selected == widget.slot && _s.selectedSide == widget.side;
    return GestureDetector(
      // 카드는 고르기만 한다: 고르면 그 해적으로 줌인하고, 쏘기는 배 위 해적을
      // 당겨서 한다 (설계서 §2.2, §13.4, ADR-033). 상대 턴에 고르면 다음 턴까지 남는다.
      onTap: () => _s.select(widget.slot),
      child: Opacity(
        opacity: _ready ? 1 : 0.45,
        // 카드 모양은 등급 프레임을 따른다 (설계서 §10.5, §13.4). 고른 카드와
        // 팀은 바깥 테두리 색으로 알린다.
        child: Container(
          width: 72,
          height: 102,
          foregroundDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
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
                child: RarityCard(
                  rarity: pirate.spec.rarity,
                  species: species,
                  team: team,
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _strip(
                  ammoLabel(l10n, pirate.spec, locale),
                  HudColors.warn,
                  icon: ammoIconPath(pirate.spec.ammo),
                ),
              ),
              // 색을 못 구분해도 등급이 보이게 별 수 (설계서 §10.5, A37).
              Positioned(
                bottom: 16,
                child: RarityStars(rarity: pirate.spec.rarity),
              ),
              // 아래 줄: 해적 상태 (설계서 §13.4).
              if (note != null) _strip(note, HudColors.text),
            ],
          ),
        ),
      ),
    );
  }

  /// 카드 위·아래 한 줄 글자 띠.
  Widget _strip(String text, Color color, {String? icon}) => Container(
    width: double.infinity,
    color: HudColors.panel,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) Image.asset(icon, width: 12, height: 12),
        Flexible(
          child: Text(
            text,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: color, fontSize: 10),
          ),
        ),
      ],
    ),
  );
}
