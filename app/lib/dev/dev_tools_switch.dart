import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pirate_busters/dev/dev_flags.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';
import 'package:pirate_busters/ui/kit/pb_dialog.dart';

/// 숨은 스위치 (ADR-073, ADR-099): [child] 에서 버튼이 아닌 곳(설정의 '언어' 글자 등)을
/// [devToolsTaps] 번 연달아 누르면 운영자 모드 버튼이 나타난다. 켜기는 비밀번호로 한다.
class DevToolsSwitch extends ConsumerStatefulWidget {
  const DevToolsSwitch({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<DevToolsSwitch> createState() => _DevToolsSwitchState();
}

class _DevToolsSwitchState extends ConsumerState<DevToolsSwitch> {
  /// 이보다 길게 쉬면 처음부터 다시 센다.
  static const Duration _gap = Duration(milliseconds: 1500);

  int _taps = 0;
  DateTime? _last;

  void _tap() {
    final now = DateTime.now();
    final last = _last;
    _taps = last != null && now.difference(last) < _gap ? _taps + 1 : 1;
    _last = now;
    if (_taps < devToolsTaps) return;
    _taps = 0;
    if (ref.read(devToolsProvider) || ref.read(operatorRevealProvider)) return;
    ref.read(operatorRevealProvider.notifier).reveal();
    showPbToast(context, AppLocalizations.of(context).operatorRevealed);
  }

  @override
  Widget build(BuildContext context) =>
      GestureDetector(onTap: _tap, child: widget.child);
}
