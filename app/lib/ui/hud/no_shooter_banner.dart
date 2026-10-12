import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';
import 'package:pirate_busters/ui/hud/hud_style.dart';
import 'package:pirate_busters/ui/kit/kit_motion.dart';

/// 쏠 해적이 없는 턴 안내 (설계서 §2.2, ADR-102): ‘공격할 수 있는 해적이 없습니다.
/// 턴을 상대방에게 넘깁니다’. [active] 가 켜지는 순간부터 [shown] 동안 보여 턴이
/// 넘어간 뒤에도 읽을 시간을 준다. 판정과 무관하다.
class NoShooterBanner extends StatefulWidget {
  const NoShooterBanner({required this.active, super.key});

  /// 세션이 이번 턴을 쏠 해적 없는 턴으로 봤다(`AutoEndClock.noShooter`).
  final bool active;

  /// 보여 두는 시간.
  static const Duration shown = Duration(milliseconds: 2600);

  @override
  State<NoShooterBanner> createState() => _NoShooterBannerState();
}

class _NoShooterBannerState extends State<NoShooterBanner> {
  bool _visible = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.active) _show();
  }

  @override
  void didUpdateWidget(NoShooterBanner old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) _show();
  }

  void _show() {
    _visible = true;
    _timer?.cancel();
    _timer = Timer(NoShooterBanner.shown, () {
      if (mounted) setState(() => _visible = false);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();
    return Align(
      alignment: const Alignment(0, -0.15),
      child: IgnorePointer(
        child: PopIn(
          child: HudPanel(
            key: const ValueKey('noShooterBanner'),
            borderColor: HudColors.warn,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Text(
                AppLocalizations.of(context).noPirateCanFire,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, color: HudColors.warn),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
