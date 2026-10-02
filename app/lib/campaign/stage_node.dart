import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:pirate_busters/app/app_theme.dart';
import 'package:pirate_busters/campaign/stage_spec.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';
import 'package:pirate_busters/port/port_widgets.dart';
import 'package:pirate_busters/ui/kit/kit_art.dart';
import 'package:pirate_busters/ui/kit/kit_motion.dart';
import 'package:pirate_busters/ui/meta_icons.dart';

/// 지도에 보이는 스테이지 이름 (설계서 §13 공통: 내부 id 를 숨긴다).
/// 캠페인은 `1-5`, 튜토리얼은 ‘튜토리얼 1’.
String stageName(AppLocalizations l10n, StageSpec stage) =>
    stage.kind == StageKind.tutorial
    ? l10n.stageTutorialName(stage.number)
    : l10n.stageNumberName(stage.sea, stage.number);

/// 해역 번호의 배경 그림 키 (에셋 `regions.json`, 설계서 §10.2).
String seaRegion(int sea) => const [
  'tropic',
  'fog',
  'storm',
  'glacier',
  'abyss',
  'gold',
][(sea - 1).clamp(0, 5)];

/// 스테이지 섬 노드: 이름, 별 3개, 보스는 크고 세력 깃발 (설계서 §13.3).
/// [current] 면 노드 위에 내 배가 떠 있다.
class StageNode extends StatelessWidget {
  const StageNode({
    required this.stage,
    required this.stars,
    required this.locked,
    required this.onTap,
    this.current = false,
    super.key,
  });

  final StageSpec stage;
  final int stars;
  final bool locked;
  final bool current;
  final VoidCallback onTap;

  /// 노드 원 지름.
  static double sizeOf(StageSpec stage) => switch (stage.kind) {
    StageKind.boss => 92,
    StageKind.midBoss => 78,
    _ => 64,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final size = sizeOf(stage);
    final kindLabel = switch (stage.kind) {
      StageKind.boss => l10n.stageKindBoss,
      StageKind.midBoss => l10n.stageKindMidBoss,
      _ => null,
    };
    final ring = stage.isBoss ? const Color(0xFFE06A5A) : AppColors.gold;
    return Semantics(
      button: true,
      label: stageName(l10n, stage),
      child: Pressable(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 34,
              child: current && !locked
                  ? const _Bob(
                      child: Image(
                        image: AssetImage(PortIcons.ship),
                        width: 34,
                      ),
                    )
                  : null,
            ),
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  width: size,
                  height: size,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: const Alignment(-0.3, -0.4),
                      colors: locked
                          ? const [Color(0xFF4A5060), Color(0xFF262A33)]
                          : stage.isBoss
                          ? const [Color(0xFFF0A07A), Color(0xFF9E3226)]
                          : const [Color(0xFFF3DFA2), Color(0xFF3C9C8C)],
                    ),
                    border: Border.all(
                      color: locked ? AppColors.mute : ring,
                      width: 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: current
                            ? ring.withValues(alpha: 0.7)
                            : const Color(0x88000000),
                        blurRadius: current ? 18 : 6,
                        offset: current ? Offset.zero : const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: locked
                      ? Image.asset(PortIcons.lock, width: size * 0.42)
                      : OutlinedText(
                          stageName(l10n, stage),
                          size: stage.kind == StageKind.tutorial
                              ? 13
                              : stage.isBoss
                              ? 24
                              : 20,
                          font: AppFonts.display,
                        ),
                ),
                if (stage.isBoss && !locked)
                  Positioned(
                    top: -14,
                    right: -10,
                    child: MetaIcons.image(
                      MetaIcons.factionOfSea(stage.sea),
                      size: 34,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            if (kindLabel != null)
              OutlinedText(kindLabel, size: 13, color: const Color(0xFFFFD27A)),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var s = 1; s <= 3; s++)
                  MetaIcons.image(
                    s <= stars ? MetaIcons.starOn : MetaIcons.starOff,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 위아래로 천천히 떠 있는 움직임 (현재 노드의 배).
class _Bob extends StatefulWidget {
  const _Bob({required this.child});

  final Widget child;

  @override
  State<_Bob> createState() => _BobState();
}

class _BobState extends State<_Bob> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (KitMotion.reducedOf(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      unawaited(_c.repeat());
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    child: widget.child,
    builder: (context, child) => Transform.translate(
      offset: Offset(0, 3 * math.sin(_c.value * 2 * math.pi)),
      child: child,
    ),
  );
}

/// 노드 사이 점선 항로. 열린 길은 금색, 잠긴 길은 흐린 색.
class RoutePainter extends CustomPainter {
  RoutePainter(this.points, this.openUntil);

  /// 노드 가운데 좌표.
  final List<Offset> points;

  /// 이 번호까지의 노드로 가는 길이 열려 있다.
  final int openUntil;

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 1; i < points.length; i++) {
      final a = points[i - 1];
      final b = points[i];
      final mid = Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2 - 26);
      final path = Path()
        ..moveTo(a.dx, a.dy)
        ..quadraticBezierTo(mid.dx, mid.dy, b.dx, b.dy);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..color = i <= openUntil
            ? const Color(0xFFFFE2A0)
            : const Color(0x88A0A8B8);
      for (final metric in path.computeMetrics()) {
        for (var d = 0.0; d < metric.length; d += 16) {
          canvas.drawPath(
            metric.extractPath(d, math.min(d + 8, metric.length)),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(RoutePainter old) =>
      old.openUntil != openUntil || old.points.length != points.length;
}
