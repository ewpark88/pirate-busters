import 'package:flutter/material.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';
import 'package:pirate_busters/ui/hud/hud_style.dart';
import 'package:pirate_busters/ui/meta_icons.dart';

/// 위 가는 막대: 두 배의 위치와 지금 간격(칸), 오른쪽 끝 ‘전체 보기’ (설계서 §2.1, §13.4).
/// 막대 바탕은 파도 구간 물빛이라 어디가 잔잔한지 위에서 한눈에 보인다 (§2.6).
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
    // 막대 범위: 두 배의 바다 끝 사이 (설계서 §2.5).
    final span = startGap + 2 * state.rules.backRoom;
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
                Positioned.fill(
                  top: 5,
                  bottom: 5,
                  child: CustomPaint(
                    key: const ValueKey('gap-zones'),
                    painter: ZoneStrip(state: state, span: span),
                  ),
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
            avatar: MetaIcons.image(MetaIcons.fullView, size: 16),
            showCheckmark: false,
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

/// 간격 막대 바탕: 파도 구간마다 물빛 (설계서 §2.6). 잔잔은 맑은 청록, 보통은 바다색,
/// 거침은 짙은 남색. 막대 범위는 [span](두 배 바다 끝 사이, 1/1000칸)이다.
class ZoneStrip extends CustomPainter {
  const ZoneStrip({required this.state, required this.span});

  final MatchState state;
  final int span;

  /// 세기 [level] 구간 색.
  static Color colorOf(int level) => switch (level) {
    0 => const Color(0xFF6FE3E0),
    1 => const Color(0xFF2B8FB3),
    _ => const Color(0xFF0A2747),
  };

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    const step = cellUnit ~/ 2;
    for (var x = -span ~/ 2; x < span ~/ 2; x += step) {
      final level = state.waveZones[waveZoneIndex(state, x + step ~/ 2)];
      final l = (x + span / 2) / span * size.width;
      final r = (x + step + span / 2) / span * size.width;
      canvas.drawRect(
        Rect.fromLTRB(l, 0, r + .5, size.height),
        paint..color = colorOf(level),
      );
    }
  }

  @override
  bool shouldRepaint(ZoneStrip old) => old.state != state;
}
