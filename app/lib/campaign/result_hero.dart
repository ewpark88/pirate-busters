import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pirate_busters/app/app_theme.dart';
import 'package:pirate_busters/app/providers.dart';
import 'package:pirate_busters/battle/battle_setup.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';
import 'package:pirate_busters/l10n/data_text.dart';
import 'package:pirate_busters/shipyard/blueprint_preview.dart';
import 'package:pirate_busters/story/rig_portrait.dart';
import 'package:pirate_busters/ui/kit/kit_art.dart';
import 'package:pirate_busters/ui/kit/kit_motion.dart';

/// 결과 화면 주인공 (설계서 §13.5): 이기면 MVP 해적이 승리 표정으로 뛰고, 지면
/// 젖은 해적과 기운 배를 보여준다. 비기면 기본 표정이다.
class ResultHero extends ConsumerWidget {
  const ResultHero({
    required this.won,
    required this.draw,
    required this.pirate,
    super.key,
  });

  final bool won;
  final bool draw;

  /// 보여줄 해적 id (MVP, 없으면 덱 첫 해적).
  final String pirate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final catalog = ref.watch(gameCatalogProvider);
    final species = catalog.speciesOf(pirate);
    final name = dataText(l10n, catalog.def(pirate).nameKey);
    if (!won && !draw) {
      final fleet = ref.watch(fleetStoreProvider);
      final ship =
          fleet.blueprint(fleet.activeSlot) ??
          BattleSetup(catalog).defaultBlueprint;
      return LayoutBuilder(
        builder: (context, box) => Stack(
          alignment: Alignment.bottomCenter,
          children: [
            // 기운 배: 물에 반쯤 잠긴다.
            Positioned(
              left: 0,
              right: 0,
              bottom: box.maxHeight * 0.08,
              height: box.maxHeight * 0.4,
              child: Transform.rotate(
                angle: -0.2,
                child: BlueprintPreview(blueprint: ship),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: box.maxHeight * 0.22,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xCC2A8FA8), Color(0xF0145A70)],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: box.maxHeight * 0.18,
              child: Drip(
                child: ColorFiltered(
                  // 물에 젖어 푸르스름하다.
                  colorFilter: const ColorFilter.mode(
                    Color(0x553C9CD0),
                    BlendMode.srcATop,
                  ),
                  child: RigPortrait(
                    species: species,
                    expr: 'lose',
                    height: math.min(box.maxHeight * 0.5, 150),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (won)
          OutlinedText(
            l10n.resultMvp,
            size: 18,
            color: const Color(0xFFFFD45A),
            font: AppFonts.display,
          ),
        Flexible(
          child: Hop(
            enabled: won,
            child: RigPortrait(
              species: species,
              expr: won ? 'win' : 'default',
              height: 160,
            ),
          ),
        ),
        OutlinedText(name, size: 14),
      ],
    );
  }
}

/// 제자리에서 통통 뛰는 움직임 (승리 동작). 움직임이 꺼지면 멈춘다.
class Hop extends StatefulWidget {
  const Hop({required this.child, this.enabled = true, super.key});

  final Widget child;
  final bool enabled;

  @override
  State<Hop> createState() => _HopState();
}

class _HopState extends State<Hop> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!widget.enabled || KitMotion.reducedOf(context)) {
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
    builder: (context, child) {
      final t = math.sin(_c.value * math.pi);
      return Transform.translate(
        offset: Offset(0, -18 * t),
        child: Transform.scale(scaleY: 1 - 0.04 * (1 - t), child: child),
      );
    },
  );
}

/// 물방울이 떨어지는 젖은 모습 (패배). 움직임이 꺼지면 물방울만 멈춘 채 보인다.
class Drip extends StatefulWidget {
  const Drip({required this.child, super.key});

  final Widget child;

  @override
  State<Drip> createState() => _DripState();
}

class _DripState extends State<Drip> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
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
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    children: [
      widget.child,
      for (final (i, x) in const [0.25, 0.55, 0.78].indexed)
        AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final t = (_c.value + i * 0.33) % 1;
            return Positioned(
              left: 0,
              right: 0,
              top: 20 + 70 * t,
              child: FractionallySizedBox(
                alignment: Alignment(x * 2 - 1, 0),
                widthFactor: 0.06,
                child: Opacity(
                  opacity: 1 - t,
                  child: const AspectRatio(
                    aspectRatio: 0.7,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Color(0xFF8FD3F0),
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
    ],
  );
}

/// 탭하면 연출을 건너뛰는 감싸개 (설계서 §13.5). 건너뛰면 아래를 움직임 없이 다시 그린다.
class SkippableMotion extends StatefulWidget {
  const SkippableMotion({required this.child, super.key});

  final Widget child;

  @override
  State<SkippableMotion> createState() => _SkippableMotionState();
}

class _SkippableMotionState extends State<SkippableMotion> {
  bool _skipped = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.translucent,
    onTap: _skipped ? null : () => setState(() => _skipped = true),
    child: KitMotion(
      reduced: _skipped || KitMotion.reducedOf(context),
      child: KeyedSubtree(key: ValueKey(_skipped), child: widget.child),
    ),
  );
}
