import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';
import 'package:pirate_busters/ui/hud/hud_gauge.dart';
import 'package:pirate_busters/ui/hud/hud_style.dart';
import 'package:pirate_busters/ui/meta_icons.dart';

/// 한 배의 선체 내구도·침수량·생존 선원 (설계서 §13.4, A33 디자인).
///
/// 진영색 원형 배지(선체 아이콘)가 패널 바깥쪽에 겹쳐 붙고, 굵은 선체 게이지 아래에
/// 침수 숫자와 선원 칸을 둔다. 오른쪽 배는 좌우 대칭이다. 선체 값 [hull] 은 화면에
/// 보이는 값(탄이 닿은 만큼)이라 착탄 순간에 줄어든다.
class ShipStatusPanel extends StatelessWidget {
  const ShipStatusPanel({
    required this.side,
    required this.hull,
    required this.sunkPercent,
    this.calm = false,
    super.key,
  });

  final SideState side;

  /// 0~1.
  final double hull;

  /// 격침 기준(선체 %, 설계서 §2.4). 이보다 10%p 위부터 막대가 경고색이 된다.
  final int sunkPercent;

  /// 화면 흔들림 줄이기 (설계서 §13.8).
  final bool calm;

  static const double width = 184;
  static const double badge = 34;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final team = HudColors.team(side.side);
    final mirror = side.side == 1;
    final flood = NumberFormat(
      '0.0',
      Localizations.localeOf(context).toLanguageTag(),
    ).format(side.flood / 10);
    final panel = Container(
      margin: EdgeInsets.only(
        left: mirror ? 0 : badge / 2,
        right: mirror ? badge / 2 : 0,
      ),
      padding: EdgeInsets.fromLTRB(
        mirror ? 8 : badge / 2 + 4,
        5,
        mirror ? badge / 2 + 4 : 8,
        5,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.lerp(HudColors.panel, team, .28)!, HudColors.panel],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: team, width: 1.5),
      ),
      child: DefaultTextStyle.merge(
        style: const TextStyle(color: HudColors.text, fontSize: 12),
        child: Column(
          crossAxisAlignment: mirror
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            HudGauge(
              key: ValueKey('hull-${side.side}'),
              value: hull,
              color: team,
              height: 16,
              calm: calm,
              warnAt: (sunkPercent + 10) / 100,
              // 격침은 기준 '미만'이라 내려 읽어야 판정과 맞는다.
              label: l10n.hullPercent((hull * 100).floor()),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                if (mirror) ...[
                  _CrewPips(side: side),
                  const SizedBox(width: 4),
                ],
                Expanded(
                  child: Row(
                    mainAxisAlignment: mirror
                        ? MainAxisAlignment.end
                        : MainAxisAlignment.start,
                    children: [
                      MetaIcons.image(MetaIcons.flood, size: 14),
                      const SizedBox(width: 2),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            l10n.flood(flood),
                            style: const TextStyle(color: Color(0xFF9CC8F0)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!mirror) ...[
                  const SizedBox(width: 4),
                  _CrewPips(side: side),
                ],
              ],
            ),
          ],
        ),
      ),
    );
    final mark = Container(
      width: badge,
      height: badge,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [Color.lerp(team, Colors.white, .3)!, team],
        ),
        border: Border.all(color: HudColors.border, width: 2),
        boxShadow: const [BoxShadow(color: Color(0x80000000), blurRadius: 3)],
      ),
      child: MetaIcons.image(MetaIcons.hull, size: 22),
    );
    return SizedBox(
      width: width,
      child: Stack(
        alignment: mirror ? Alignment.centerRight : Alignment.centerLeft,
        children: [panel, mark],
      ),
    );
  }
}

/// 선원 한 명마다 작은 칸: 살아 있으면 진영색, 쓰러지면 빈 칸에 ×.
class _CrewPips extends StatelessWidget {
  const _CrewPips({required this.side});

  final SideState side;

  @override
  Widget build(BuildContext context) {
    final alive = side.crew.pirates
        .where((p) => p.status != PirateStatus.down)
        .length;
    return Semantics(
      label: AppLocalizations.of(context).crewAlive(alive, side.crew.size),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          MetaIcons.image(MetaIcons.crew, size: 14),
          const SizedBox(width: 2),
          for (final p in side.crew.pirates)
            Container(
              width: 6,
              height: 10,
              margin: const EdgeInsets.symmetric(horizontal: .5),
              decoration: BoxDecoration(
                color: p.status == PirateStatus.down
                    ? HudColors.panelHi
                    : p.status == PirateStatus.swimming
                    ? HudColors.warn
                    : HudColors.team(side.side),
                borderRadius: BorderRadius.circular(2),
                border: Border.all(width: .8),
              ),
              child: p.status == PirateStatus.down
                  ? const Icon(Icons.close, size: 6, color: HudColors.mute)
                  : null,
            ),
        ],
      ),
    );
  }
}
