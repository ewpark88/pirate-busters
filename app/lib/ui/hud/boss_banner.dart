import 'package:flutter/material.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';
import 'package:pirate_busters/ui/kit/kit_art.dart';
import 'package:pirate_busters/ui/kit/kit_motion.dart';

/// 보스전 시작 배너 (설계서 §5.4·§13.4): 위쪽 가운데에 “보스!”를 띄웠다가 몇 초 뒤
/// 사라진다. 누르면 바로 닫는다. 보스 기믹은 없다(ADR-111). 판정과 무관하다.
class BossBanner extends StatefulWidget {
  const BossBanner({this.onDone, super.key});

  /// 배너가 닫힐 때(시간이 다 되거나 눌렀을 때) 한 번 부른다.
  final VoidCallback? onDone;

  /// 보여 두는 시간.
  static const Duration shown = Duration(milliseconds: 3800);

  @override
  State<BossBanner> createState() => _BossBannerState();
}

class _BossBannerState extends State<BossBanner> {
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(BossBanner.shown, _close);
  }

  void _close() {
    if (!mounted || !_visible) return;
    setState(() => _visible = false);
    widget.onDone?.call();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return IgnorePointer(
      ignoring: !_visible,
      child: AnimatedOpacity(
        opacity: _visible ? 1 : 0,
        duration: const Duration(milliseconds: 400),
        child: GestureDetector(
          onTap: _close,
          child: Align(
            alignment: const Alignment(0, -0.45),
            child: PopIn(
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                decoration: BoxDecoration(
                  color: const Color(0xCC14161C),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE0402F), width: 2),
                ),
                child: OutlinedText(l10n.bossBanner, size: 30),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
