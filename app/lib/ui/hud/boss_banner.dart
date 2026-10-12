import 'package:flutter/material.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';
import 'package:pirate_busters/l10n/data_text.dart';
import 'package:pirate_busters/ui/kit/kit_art.dart';
import 'package:pirate_busters/ui/kit/kit_motion.dart';

/// 보스전 시작 배너 (설계서 §5.4·§13.4): 위쪽 가운데에 “보스!”와, 기믹이 있으면 기믹 한
/// 줄을 띄웠다가 몇 초 뒤 사라진다. 누르면 바로 닫는다. 판정과 무관하다.
class BossBanner extends StatefulWidget {
  const BossBanner({this.gimmick, this.onDone, super.key});

  /// 기믹 id (`bow_iron_shield` 등). 글자는 ARB `gimmick_<id>`. 기믹 없는 보스는 null.
  final String? gimmick;

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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedText(l10n.bossBanner, size: 30),
                    if (widget.gimmick case final gimmick?) ...[
                      const SizedBox(height: 4),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: Text(
                          dataText(l10n, 'gimmick_$gimmick'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Color(0xFFFFC24A),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
