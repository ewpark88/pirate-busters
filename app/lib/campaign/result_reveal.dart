import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/campaign/result_celebrate.dart';
import 'package:pirate_busters/ui/cards/rarity_card.dart';
import 'package:pirate_busters/ui/kit/kit_art.dart';

/// 새 해적: 뒷면 카드가 뒤집히며 등급 카드가 나타나고 등급색 빛이 퍼진다.
class NewPirateReveal extends ConsumerStatefulWidget {
  const NewPirateReveal({
    required this.rarity,
    required this.species,
    required this.order,
    this.height = 96,
    this.onLand,
    super.key,
  });

  final Rarity rarity;
  final String species;
  final int order;
  final double height;
  final VoidCallback? onLand;

  /// 등급색 빛 (설계서 §10.5).
  static Color glowOf(Rarity r) => switch (r) {
    Rarity.common => const Color(0xFFB8C0CC),
    Rarity.rare => const Color(0xFF4FA3FF),
    Rarity.hero => const Color(0xFFB36BFF),
    Rarity.legend => const Color(0xFFFFC24A),
    Rarity.myth => const Color(0xFFFF6FD8),
  };

  @override
  ConsumerState<NewPirateReveal> createState() => _NewPirateRevealState();
}

class _NewPirateRevealState extends ConsumerState<NewPirateReveal>
    with SingleTickerProviderStateMixin, DelayedClock<NewPirateReveal> {
  @override
  Duration get duration => const Duration(milliseconds: 700);
  @override
  int get order => widget.order;

  @override
  void landed() {
    ResultSfx.play(ref, ResultSfx.reveal);
    widget.onLand?.call();
  }

  @override
  Widget build(BuildContext context) {
    final glow = NewPirateReveal.glowOf(widget.rarity);
    final width = widget.height * RarityCard.canvas.aspectRatio;
    return AnimatedBuilder(
      animation: clock,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(clock.value);
        final angle = math.pi * (1 - t);
        final front = angle < math.pi / 2;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, .002)
            ..rotateY(front ? angle : angle - math.pi),
          child: Container(
            key: ValueKey('new-pirate-${front ? 'front' : 'back'}'),
            width: width,
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                if (front)
                  BoxShadow(
                    color: glow.withValues(alpha: .8 * t),
                    blurRadius: 18 * t,
                    spreadRadius: 2 * t,
                  ),
              ],
            ),
            child: front
                ? RarityCard(rarity: widget.rarity, species: widget.species)
                : DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B1F2A),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: glow, width: 2),
                    ),
                    child: const Center(
                      child: OutlinedText('?', size: 30),
                    ),
                  ),
          ),
        );
      },
    );
  }
}
