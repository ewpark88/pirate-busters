import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/ui/cards/card_motion.dart';
import 'package:pirate_busters/ui/cards/card_mythic.dart';

/// 등급 카드 프레임 (설계서 §10.5): 배경 · 해적 · 앞면 세 겹과 등급별 움직임.
/// 해적보감·선원·상점·보물·HUD 카드가 함께 쓴다. 글자는 그림에 없고 [children]
/// 으로 앱이 얹는다. 좌표는 에셋 `cards.json` 의 카드 캔버스(252×358)다.
class RarityCard extends StatelessWidget {
  const RarityCard({
    required this.rarity,
    required this.species,
    this.team = 'blue',
    this.children = const [],
    super.key,
  });

  final Rarity rarity;

  /// 아트 에셋 키 (설계서 §4.3).
  final String species;
  final String team;

  /// 카드 캔버스 좌표로 얹는 것(글자·칩·아이콘). `Positioned` 를 쓴다.
  final List<Widget> children;

  /// 카드 캔버스 크기. 카드 몸통은 (6, 12) 에서 240×340 이다.
  static const Size canvas = Size(252, 358);
  static const Offset bodyOrigin = Offset(6, 12);
  static const Rect body = Rect.fromLTWH(6, 12, 240, 340);

  /// 해적을 잘라 보여주는 창(카드 캔버스 좌표).
  static const Rect artWindow = Rect.fromLTWH(18, 24, 216, 238);

  /// 에셋 키: 신화는 `mythic` 이다(pb_sim 은 `myth`).
  static String keyOf(Rarity rarity) =>
      rarity == Rarity.myth ? 'mythic' : rarity.name;

  static const String _dir = 'assets/images/ui/cards';

  @override
  Widget build(BuildContext context) {
    final key = keyOf(rarity);
    final clock = CardMotion.of(context);
    return AspectRatio(
      aspectRatio: canvas.width / canvas.height,
      child: FittedBox(
        child: SizedBox.fromSize(
          size: canvas,
          child: Stack(
            children: [
              Positioned.fill(child: Image.asset('$_dir/card_${key}_back.png')),
              if (rarity == Rarity.legend) _Rays(clock),
              if (rarity == Rarity.myth) MythicMotion(clock),
              // 해적: 발이 몸통 (120, 247) 에 오도록 0.74배로 놓고 창으로 자른다.
              Positioned.fromRect(
                rect: artWindow,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: Stack(
                    children: [
                      Positioned(
                        left: 19.2,
                        top: 1.9,
                        width: 240 * .74,
                        height: 324 * .74,
                        child: Image.asset(
                          'assets/images/characters/$species/'
                          '${species}_${team}_card.png',
                          fit: BoxFit.fill,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned.fill(
                child: Image.asset('$_dir/card_${key}_front.png'),
              ),
              if (rarity != Rarity.common) _Sparkle(rarity, clock),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

/// 전설: 빛살이 30초에 한 바퀴 돈다. 회전 중심은 몸통 (120, 160).
class _Rays extends StatelessWidget {
  const _Rays(this.clock);

  final ValueListenable<double>? clock;

  @override
  Widget build(BuildContext context) {
    final rays = Image.asset('${RarityCard._dir}/card_legend_rays.png');
    final clock = this.clock;
    return Positioned.fill(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: clock == null
            ? rays
            : AnimatedBuilder(
                animation: clock,
                child: rays,
                builder: (context, child) => Transform.rotate(
                  angle: clock.value / 30 * 2 * math.pi,
                  alignment: const Alignment(0, 172 / 179 - 1),
                  child: child,
                ),
              ),
      ),
    );
  }
}

/// 등급별 움직임: 희귀는 거품이 떠오르고, 영웅은 별빛이 반짝이고, 전설·신화는
/// 반짝임에 광택 띠가 훑고 지나간다(신화는 무지개색).
class _Sparkle extends StatelessWidget {
  const _Sparkle(this.rarity, this.clock);

  final Rarity rarity;
  final ValueListenable<double>? clock;

  /// [x, y, 반지름] (몸통 좌표, `cards.json` motion).
  static const _bubbles = [
    [32.0, 200.0, 5.0],
    [40.0, 150.0, 3.0],
    [205.0, 180.0, 6.0],
    [198.0, 120.0, 3.5],
    [58.0, 90.0, 2.5],
    [185.0, 60.0, 4.0],
  ];
  static const _stars = [
    [80.0, 40.0, 5.0],
    [140.0, 28.0, 3.5],
    [210.0, 110.0, 4.5],
    [30.0, 150.0, 3.5],
    [205.0, 200.0, 3.0],
    [100.0, 70.0, 2.5],
  ];

  Widget _layer(double t) {
    const dir = RarityCard._dir;
    const o = RarityCard.bodyOrigin;
    final items = <Widget>[];
    if (rarity == Rarity.rare) {
      for (final (i, b) in _bubbles.indexed) {
        // 4초마다 위로 30 떠오르고 되풀이한다.
        final u = (t / 4 + i * .17) % 1;
        items.add(
          Positioned(
            left: o.dx + b[0] - b[2],
            top: o.dy + b[1] - b[2] - 30 * u,
            child: Opacity(
              opacity: 1 - u * .8,
              child: Image.asset('$dir/card_bubble.png', width: b[2] * 2),
            ),
          ),
        );
      }
    } else {
      for (final (i, s) in _stars.indexed) {
        // 2.4초 주기로 크기 0.5→1.1, 투명도 0.15→1. 저마다 시차가 다르다.
        final u = .5 + .5 * math.sin((t / 2.4 + i * .19) * 2 * math.pi);
        final r = s[2] * 2.4 * (.5 + .6 * u);
        items.add(
          Positioned(
            left: o.dx + s[0] - r,
            top: o.dy + s[1] - r,
            child: Opacity(
              opacity: .15 + .85 * u,
              child: Image.asset('$dir/card_sparkle.png', width: r * 2),
            ),
          ),
        );
      }
    }
    if (rarity == Rarity.legend || rarity == Rarity.myth) {
      // 광택 띠: 3.6초 주기의 뒤 45% 동안 왼쪽 밖에서 오른쪽 밖으로 지나간다.
      final u = ((t % 3.6) / 3.6 - .55) / .45;
      if (u > 0) {
        final shine = Image.asset(
          '$dir/card_shine.png',
          width: 90,
          height: 380,
        );
        items.add(
          Positioned(
            left: o.dx - 120 + 440 * u,
            top: o.dy - 20,
            child: Transform(
              transform: Matrix4.skewX(-18 * math.pi / 180),
              child: rarity == Rarity.myth
                  ? ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        HSLColor.fromAHSL(1, t * 90 % 360, .9, .75).toColor(),
                        BlendMode.modulate,
                      ),
                      child: shine,
                    )
                  : shine,
            ),
          ),
        );
      }
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(children: items),
    );
  }

  @override
  Widget build(BuildContext context) {
    final clock = this.clock;
    return Positioned.fill(
      child: IgnorePointer(
        child: clock == null
            ? _layer(0)
            : ValueListenableBuilder<double>(
                valueListenable: clock,
                builder: (context, t, _) => _layer(t),
              ),
      ),
    );
  }
}
