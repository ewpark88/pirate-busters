import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pirate_busters/app/app_theme.dart';
import 'package:pirate_busters/app/providers.dart';
import 'package:pirate_busters/audio/sound_service.dart';
import 'package:pirate_busters/ui/kit/kit_art.dart';
import 'package:pirate_busters/ui/kit/kit_motion.dart';

/// 결과 화면 축하 연출 (설계서 §13.5 “별이 하나씩 찍히며”, §10.5 등급 연출,
/// §13.8 카드 넘김, A55). 움직임 끄기(저사양)면 끝난 모습만 보인다.

/// 결과 연출 소리 (설계서 §10.3 별 찍힘·레벨업). 효과음 설정을 따른다.
abstract final class ResultSfx {
  static const Sfx star = Sfx.star;
  static const Sfx levelUp = Sfx.levelUp;
  static const Sfx reveal = Sfx.clang;

  static void play(WidgetRef ref, Sfx sfx) {
    if (ref.read(soundOnProvider)) ref.read(soundServiceProvider).play(sfx);
  }
}

/// [order] 칸만큼 늦게(PopIn 과 같은 박자) 시작해 [duration] 동안 0→1 로 가는 시계.
mixin DelayedClock<T extends ConsumerStatefulWidget>
    on ConsumerState<T>, TickerProvider {
  late final AnimationController clock = AnimationController(
    vsync: this,
    duration: duration,
  );
  Timer? _timer;
  bool _started = false;

  Duration get duration;
  int get order;

  /// 시계가 끝까지 갔을 때(한 번).
  void landed() {}

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (KitMotion.reducedOf(context)) {
      clock.value = 1;
      return;
    }
    clock.addStatusListener((s) {
      if (s == AnimationStatus.completed) landed();
    });
    _timer = Timer(PopIn.step * order, () {
      if (mounted) unawaited(clock.forward());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    clock.dispose();
    super.dispose();
  }
}

/// 별 도장: 크게 떨어져 내려 쿵 찍히고, 켜진 별은 빛살이 퍼진다. 찍히는 순간
/// [onLand] 를 부른다(소리).
class StarStamp extends ConsumerStatefulWidget {
  const StarStamp({
    required this.child,
    required this.on,
    required this.order,
    this.onLand,
    super.key,
  });

  final Widget child;
  final bool on;
  final int order;
  final VoidCallback? onLand;

  static const Duration duration = Duration(milliseconds: 420);

  @override
  ConsumerState<StarStamp> createState() => _StarStampState();
}

class _StarStampState extends ConsumerState<StarStamp>
    with SingleTickerProviderStateMixin, DelayedClock<StarStamp> {
  @override
  Duration get duration => StarStamp.duration;
  @override
  int get order => widget.order;

  @override
  void landed() {
    if (widget.on) ResultSfx.play(ref, ResultSfx.star);
    widget.onLand?.call();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: clock,
    child: widget.child,
    builder: (context, child) {
      final t = clock.value;
      // 앞 60% 동안 2.2배에서 1배로 떨어지고, 뒤 40% 동안 살짝 눌렸다 돌아온다.
      final drop = Curves.easeIn.transform((t / .6).clamp(0, 1));
      final squash = t < .6 ? 0.0 : math.sin((t - .6) / .4 * math.pi) * .12;
      return Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          if (widget.on && t > .6)
            Positioned.fill(
              child: CustomPaint(painter: _RaysPainter((t - .6) / .4)),
            ),
          Opacity(
            opacity: (t / .25).clamp(0, 1),
            child: Transform.scale(
              scale: 2.2 - 1.2 * drop - squash,
              child: child,
            ),
          ),
        ],
      );
    },
  );
}

class _RaysPainter extends CustomPainter {
  _RaysPainter(this.t);

  final double t;
  static final Paint _ray = Paint()
    ..strokeWidth = 3
    ..strokeCap = StrokeCap.round;

  @override
  void paint(Canvas canvas, Size size) {
    if (t >= 1) return;
    final c = size.center(Offset.zero);
    final r0 = size.shortestSide * (.45 + t * .4);
    final r1 = r0 + size.shortestSide * .25 * (1 - t);
    _ray.color = const Color(0xFFFFE27A).withValues(alpha: 1 - t);
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4 + math.pi / 8;
      final d = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(c + d * r0, c + d * r1, _ray);
    }
  }

  @override
  bool shouldRepaint(_RaysPainter old) => old.t != t;
}

/// 레벨업 빛 배너: 금빛 알약이 튀어 나오고 빛줄기가 한 번 지나간다.
class LevelUpBanner extends ConsumerStatefulWidget {
  const LevelUpBanner({
    required this.text,
    required this.order,
    this.onLand,
    super.key,
  });

  final String text;
  final int order;
  final VoidCallback? onLand;

  @override
  ConsumerState<LevelUpBanner> createState() => _LevelUpBannerState();
}

class _LevelUpBannerState extends ConsumerState<LevelUpBanner>
    with SingleTickerProviderStateMixin, DelayedClock<LevelUpBanner> {
  @override
  Duration get duration => const Duration(milliseconds: 900);
  @override
  int get order => widget.order;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!KitMotion.reducedOf(context)) {
      // 튀어 나오는 순간 소리 (시계 시작과 같은 때).
      Timer(PopIn.step * widget.order, () {
        if (!mounted) return;
        ResultSfx.play(ref, ResultSfx.levelUp);
        widget.onLand?.call();
      });
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: clock,
    builder: (context, _) {
      final t = clock.value;
      final pop = Curves.elasticOut.transform((t / .5).clamp(0, 1));
      final shine = ((t - .35) / .65).clamp(0.0, 1.0);
      return Opacity(
        opacity: (t / .15).clamp(0, 1),
        child: Transform.scale(
          scale: .6 + .4 * pop,
          child: Container(
            key: const ValueKey('level-up-banner'),
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: const [
                  Color(0xFF8A5A10),
                  Color(0xFFFFD45A),
                  Color(0xFFFFF4C2),
                  Color(0xFFFFD45A),
                  Color(0xFF8A5A10),
                ],
                stops: [0, shine * .8, shine * .8 + .1, shine * .8 + .2, 1],
              ),
              boxShadow: const [
                BoxShadow(color: Color(0x88FFC24A), blurRadius: 14),
              ],
            ),
            child: OutlinedText(
              widget.text,
              size: 18,
              font: AppFonts.display,
            ),
          ),
        ),
      );
    },
  );
}
