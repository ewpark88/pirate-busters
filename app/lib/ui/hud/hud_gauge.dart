import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:pirate_busters/ui/hud/hud_gauge_painter.dart';
import 'package:pirate_busters/ui/hud/hud_style.dart';

/// HUD 공용 게이지 (설계서 §13.4, A33): 선체 내구도·연료.
///
/// 둥근 홈 안에 세로 그라데이션 막대, 10% 눈금, 가운데 글자. 값이 줄면 앞 막대가
/// 곧바로 줄고 **잔상 막대**(흰빛 → 빨강)가 잠깐 머문 뒤 따라 내려와 얼마나
/// 깎였는지 읽힌다. 값이 늘면 초록 잔상이 먼저 차고 앞 막대가 따라 오른다.
/// [preview] 는 앞으로 줄어들 자리(연료 이동 미리보기)를 옅게 보여 준다.
/// [warnAt] 이하면 경고색으로 천천히 맥박친다.
class HudGauge extends StatefulWidget {
  const HudGauge({
    required this.value,
    required this.color,
    this.height = 14,
    this.label,
    this.preview,
    this.warnAt = 0,
    this.calm = false,
    this.jolts = true,
    this.gainLabel,
    super.key,
  });

  /// 0~1.
  final double value;
  final Color color;
  final double height;

  /// 막대 위 글자(퍼센트 등). 화면이 l10n 으로 만든다 (설계서 §14).
  final String? label;

  /// 0~1. [value] 보다 작으면 그 사이를 줄어들 몫으로 옅게 그린다.
  final double? preview;

  /// 이 값 이하면 경고.
  final double warnAt;

  /// 화면 흔들림 줄이기 (설계서 §13.8): 흔들림·번쩍임을 뺀다.
  final bool calm;

  /// 깎일 때 흔들리고 번쩍이는가(선체). 연료처럼 조금씩 계속 주는 값은 끈다.
  final bool jolts;

  /// 값이 1%p 이상 오르면 막대 위에 잠깐 띄울 글자(수리 ‘+n%’, A57). null 이면 없다.
  final String Function(int percent)? gainLabel;

  /// 오른 몫 글자가 떠 있는 시간(초).
  static const double gainSec = 1.4;

  /// 잔상 막대가 머무는 시간과 따라가는 빠르기(1/초).
  static const double holdSec = .45;
  static const double frontRate = 18;
  static const double trailRate = 6;

  @override
  State<HudGauge> createState() => HudGaugeState();
}

/// 그리는 값을 테스트에서 읽는다.
class HudGaugeState extends State<HudGauge>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _last = Duration.zero;

  /// 앞 막대와 잔상 막대.
  late double front = widget.value;
  late double trail = widget.value;
  double _hold = 0;
  double _hit = 0;

  /// 마지막 변화가 찬 쪽이다(잔상이 초록).
  bool rising = false;
  double _pulse = 0;

  /// 마지막으로 오른 몫(%p)과 그 글자가 남은 시간.
  int gain = 0;
  double gainLeft = 0;

  double get _target => widget.value.clamp(0.0, 1.0);

  bool get _warn => widget.warnAt > 0 && _target <= widget.warnAt;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick);
    if (_warn) _start();
  }

  @override
  void didUpdateWidget(HudGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    final old = oldWidget;
    final to = _target;
    if ((to - front).abs() < 1e-4 && (to - trail).abs() < 1e-4) {
      if (_warn) _start();
      return;
    }
    if (to < old.value.clamp(0.0, 1.0)) {
      // 깎였다: 잔상은 지금 자리에 머문다.
      trail = math.max(trail, front);
      _hold = HudGauge.holdSec;
      rising = false;
      if (widget.jolts && !widget.calm) _hit = 1;
    } else if (to > old.value.clamp(0.0, 1.0)) {
      // 찼다: 초록 잔상이 먼저 찬다.
      trail = to;
      _hold = .15;
      rising = true;
      final up = ((to - old.value.clamp(0.0, 1.0)) * 100).round();
      if (widget.gainLabel != null && up >= 1) {
        gain = up;
        gainLeft = HudGauge.gainSec;
      }
    }
    _start();
  }

  void _start() {
    if (_ticker.isActive) return;
    _last = Duration.zero;
    unawaited(_ticker.start());
  }

  void _tick(Duration now) {
    final dt = _last == Duration.zero
        ? 0.0
        : (now - _last).inMicroseconds / 1e6;
    _last = now;
    setState(() => step(dt));
    final settled =
        (front - _target).abs() < 1e-3 &&
        (trail - _target).abs() < 1e-3 &&
        _hit <= 0 &&
        gainLeft <= 0;
    if (settled && !_warn) {
      front = trail = _target;
      _ticker.stop();
    }
  }

  /// [dt] 초만큼 진행한다.
  void step(double dt) {
    final to = _target;
    _hit = math.max(0, _hit - dt * 3);
    _pulse += dt;
    gainLeft = math.max(0, gainLeft - dt);
    _hold = math.max(0, _hold - dt);
    if (to < front || _hold <= 0) {
      // 줄 때는 곧바로, 찰 때는 잔상이 머문 뒤 따라 오른다.
      final rate = to < front ? HudGauge.frontRate : HudGauge.trailRate;
      front += (to - front) * (1 - math.exp(-rate * dt));
    }
    if (_hold <= 0) {
      trail += (to - trail) * (1 - math.exp(-HudGauge.trailRate * dt));
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shake = widget.calm ? 0.0 : math.sin(_hit * 40) * _hit * 2.5;
    final glow = _warn ? (math.sin(_pulse * 5) + 1) / 2 : 0.0;
    final gauge = Transform.translate(
      offset: Offset(shake, 0),
      child: SizedBox(
        height: widget.height,
        child: CustomPaint(
          painter: GaugePainter(
            front: front,
            trail: trail,
            preview: widget.preview,
            color: _warn
                ? Color.lerp(HudColors.danger, HudColors.warn, glow * .4)!
                : widget.color,
            hit: _hit,
            rising: rising,
          ),
          child: widget.label == null
              ? null
              : Center(
                  child: Text(
                    widget.label!,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: widget.height * .72,
                      height: 1,
                      fontWeight: FontWeight.w800,
                      color: HudColors.text,
                      shadows: const [
                        Shadow(blurRadius: 2),
                        Shadow(offset: Offset(0, 1)),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
    if (gainLeft <= 0 || widget.gainLabel == null) return gauge;
    // 오른 몫: 막대 위로 떠오르며 흐려진다.
    final age = HudGauge.gainSec - gainLeft;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        gauge,
        Positioned(
          right: 6,
          bottom: widget.height * .6 + age * 10,
          child: Opacity(
            opacity: math.min(1, gainLeft / .4),
            child: Text(
              widget.gainLabel!(gain),
              key: const ValueKey('gauge-gain'),
              style: TextStyle(
                fontSize: widget.height * .9,
                fontWeight: FontWeight.w900,
                color: HudColors.good,
                shadows: const [Shadow(blurRadius: 3)],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
