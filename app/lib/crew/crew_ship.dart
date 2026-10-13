import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:pb_data/pb_data.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/app/app_theme.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';
import 'package:pirate_busters/l10n/data_text.dart';
import 'package:pirate_busters/shipyard/ship_grid_view.dart';
import 'package:pirate_busters/shipyard/shipyard_model.dart';
import 'package:pirate_busters/ui/kit/kit_art.dart';
import 'package:pirate_busters/ui/kit/kit_motion.dart';
import 'package:pirate_busters/ui/kit/kit_sound.dart';

/// 선원 화면 왼쪽의 내 배 (설계서 §13.7, A63): 지은 배 옆모습 위 선실 칸과 망대마다 탄
/// 해적 얼굴과 자리 번호를 겹쳐 그린다. 덱 순서가 곧 자리 순서다(선실 다음이 망대,
/// [seatsOf]).
/// 배지에 해적을 끌어다 놓으면 타고, 이미 있던 해적과는 자리가 바뀐다. 찬 배지는
/// 끌어서 다른 선실로 옮기고, 누르면 [onTapSlot] 으로 상세를 연다.
class CrewShip extends StatelessWidget {
  const CrewShip({
    required this.blueprint,
    required this.slots,
    required this.pirateOf,
    required this.canAccept,
    required this.onAccept,
    required this.onTapSlot,
    super.key,
  });

  final Blueprint blueprint;

  /// 선실 순서의 해적 id (빈 선실은 null).
  final List<String?> slots;
  final PirateDef Function(String id) pirateOf;
  final bool Function(String id, int slot) canAccept;
  final void Function(String id, int slot) onAccept;
  final void Function(int slot) onTapSlot;

  /// 배지 크기: 선실 칸보다 조금 크게, 손가락으로 누를 수 있게 최소 40. 다만 이웃
  /// 선실과 겹치면 누른 자리가 엉뚱한 선실로 가므로 이웃 선실까지 거리(칸)를 넘지 않는다.
  static double badgeSize(double cell, {double gap = double.infinity}) =>
      math.min(math.max(cell * 1.15, 40), gap * cell - 2);

  /// 해적이 타는 자리 칸: 선실 순서, 끝에 망대 (설계서 §3.3, 전투와 같은 순서).
  static List<(int, int)> seatsOf(Blueprint b) => [
    for (final c in b.cabins) (c.x, c.y),
    ...mastSeats(b.hull, b.modules),
  ];

  /// 자리끼리 가장 가까운 거리(칸, 가로·세로 중 큰 쪽).
  static double cabinGap(List<(int, int)> seats) {
    var gap = double.infinity;
    for (var i = 0; i < seats.length; i++) {
      for (var j = i + 1; j < seats.length; j++) {
        final d = math.max(
          (seats[i].$1 - seats[j].$1).abs(),
          (seats[i].$2 - seats[j].$2).abs(),
        );
        gap = math.min(gap, d.toDouble());
      }
    }
    return gap;
  }

  @override
  Widget build(BuildContext context) {
    final model = ShipyardModel(hull: blueprint.hull)..load(blueprint);
    final cabins = seatsOf(blueprint);
    return LayoutBuilder(
      builder: (context, box) {
        final cell = math.min(
          box.maxWidth / model.width,
          box.maxHeight / model.height,
        );
        final b = badgeSize(cell, gap: cabinGap(cabins));
        return Center(
          child: SizedBox(
            width: cell * model.width,
            height: cell * model.height,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                ShipGridView(model: model, cell: cell, bare: true),
                for (var i = 0; i < cabins.length && i < slots.length; i++)
                  Positioned.fromRect(
                    rect: Rect.fromCenter(
                      center: ShipGridView.cellRect(
                        model.height,
                        cell,
                        cabins[i].$1,
                        cabins[i].$2,
                      ).center,
                      width: b,
                      height: b,
                    ),
                    child: _CabinBadge(
                      key: ValueKey('crew-cabin-$i'),
                      slot: i,
                      pirate: switch (slots[i]) {
                        final id? => pirateOf(id),
                        null => null,
                      },
                      canAccept: (id) => canAccept(id, i),
                      onAccept: (id) => onAccept(id, i),
                      onTap: () => onTapSlot(i),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 배 그림 아래 한 줄 범례: '1 문어 · 2 거북' (배지에 이름을 붙이면 겹친다).
class CrewShipLegend extends StatelessWidget {
  const CrewShipLegend({
    required this.slots,
    required this.pirateOf,
    super.key,
  });

  final List<String?> slots;
  final PirateDef Function(String id) pirateOf;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Wrap(
      spacing: 10,
      runSpacing: 2,
      children: [
        for (var i = 0; i < slots.length; i++)
          if (slots[i] case final id?)
            Text(
              '${i + 1} ${dataText(l10n, pirateOf(id).nameKey)}',
              style: const TextStyle(color: AppColors.text, fontSize: 13),
            ),
      ],
    );
  }
}

class _CabinBadge extends StatelessWidget {
  const _CabinBadge({
    required this.slot,
    required this.pirate,
    required this.canAccept,
    required this.onAccept,
    required this.onTap,
    super.key,
  });

  final int slot;
  final PirateDef? pirate;
  final bool Function(String id) canAccept;
  final void Function(String id) onAccept;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => DragTarget<String>(
    onWillAcceptWithDetails: (d) => canAccept(d.data),
    onAcceptWithDetails: (d) {
      // 놓는 순간 누름 소리, 얼굴은 튀어 나온다 (§13.7, A55).
      KitSound.clickOf(context);
      onAccept(d.data);
    },
    builder: (context, candidates, rejected) {
      final p = pirate;
      final ring = rejected.isNotEmpty
          ? AppColors.danger
          : candidates.isNotEmpty
          ? const Color(0xFFFFC24A)
          : p == null
          ? const Color(0x99FFFFFF)
          : AppColors.gold;
      final face = PopIn(
        key: ValueKey(p?.id),
        child: _Face(pirate: p, ring: ring, slot: slot),
      );
      return Pressable(
        onTap: onTap,
        child: p == null
            ? face
            : Draggable<String>(
                data: p.id,
                feedback: SizedBox.square(
                  dimension: 56,
                  child: _Face(pirate: p, ring: AppColors.gold, slot: slot),
                ),
                childWhenDragging: Opacity(opacity: 0.35, child: face),
                child: face,
              ),
      );
    },
  );
}

/// 둥근 얼굴(카드 그림 위쪽)과 왼쪽 위 선실 번호. 빈 선실은 번호만.
class _Face extends StatelessWidget {
  const _Face({required this.pirate, required this.ring, required this.slot});

  final PirateDef? pirate;
  final Color ring;
  final int slot;

  @override
  Widget build(BuildContext context) {
    final p = pirate;
    return LayoutBuilder(
      builder: (context, box) {
        final d = box.biggest.shortestSide;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: p == null
                      ? const Color(0x661E2129)
                      : const Color(0xFF1E2129),
                  border: p == null
                      ? null
                      : Border.all(color: ring, width: math.max(2, d * .06)),
                  boxShadow: const [
                    BoxShadow(color: Color(0x88000000), blurRadius: 4),
                  ],
                ),
                child: p == null
                    // 빈 선실: 점선 고리와 ‘+’ (§13.7, A55).
                    ? CustomPaint(
                        painter: _DashedRing(ring, math.max(2, d * .05)),
                        child: Center(
                          child: OutlinedText('+', size: d * .5, color: ring),
                        ),
                      )
                    : ClipOval(
                        child: Image.asset(
                          'assets/images/characters/${p.species}/'
                          '${p.species}_blue_card.png',
                          fit: BoxFit.cover,
                          alignment: const Alignment(0, -0.75),
                        ),
                      ),
              ),
            ),
            Positioned(
              left: -d * .08,
              top: -d * .08,
              child: OutlinedText(
                '${slot + 1}',
                size: d * .3,
                color: p == null ? AppColors.mute : AppColors.text,
                font: AppFonts.display,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// 빈 선실의 점선 고리.
class _DashedRing extends CustomPainter {
  _DashedRing(this.color, this.width);

  final Color color;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;
    final r = Rect.fromLTWH(0, 0, size.width, size.height).deflate(width / 2);
    const dashes = 12;
    for (var i = 0; i < dashes; i++) {
      canvas.drawArc(
        r,
        i * 2 * math.pi / dashes,
        math.pi / dashes,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashedRing old) =>
      old.color != color || old.width != width;
}
