import 'package:flutter/material.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';
import 'package:pirate_busters/ui/hud/hud_style.dart';

/// 위 가는 막대: 두 배의 위치와 지금 간격(칸), 오른쪽 끝 ‘전체 보기’ (설계서 §2.1, §13.4).
class GapBar extends StatelessWidget {
  const GapBar({required this.state, required this.overview, super.key});

  final MatchState state;
  final ValueNotifier<bool> overview;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final a = state.sides[0].bowX;
    final b = state.sides[1].bowX;
    final gap = (b - a).abs() ~/ cellUnit;
    // 막대 범위: 두 배의 가장 먼 후퇴 한계 사이.
    const span = startGap + 2 * moveRange;
    double at(int x) => ((x + span / 2) / span).clamp(0, 1).toDouble();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 220,
          height: 14,
          child: LayoutBuilder(
            builder: (context, box) => Stack(
              children: [
                const Positioned.fill(
                  top: 6,
                  bottom: 6,
                  child: ColoredBox(color: HudColors.panelHi),
                ),
                for (final (x, side) in [(a, 0), (b, 1)])
                  Positioned(
                    left: at(x) * (box.maxWidth - 10),
                    top: 2,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: HudColors.team(side),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(l10n.gapCells(gap), style: const TextStyle(color: HudColors.text)),
        const SizedBox(width: 8),
        ValueListenableBuilder<bool>(
          valueListenable: overview,
          builder: (context, on, _) => FilterChip(
            label: Text(l10n.overview),
            selected: on,
            onSelected: (v) => overview.value = v,
            visualDensity: VisualDensity.compact,
          ),
        ),
      ],
    );
  }
}
