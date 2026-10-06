import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pirate_busters/battle/battle_session.dart';
import 'package:pirate_busters/battle/speech_director.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';
import 'package:pirate_busters/l10n/data_text.dart';
import 'package:pirate_busters/ui/kit/kit_motion.dart';

/// 전투 중 말풍선 (설계서 §15.4): 내 해적 말은 아래 해적 카드 위에, 상대 선장 말은
/// 위쪽 상대 정보 아래에 2초 띄운다. 한 턴에 최대 하나(`SpeechDirector`).
class SpeechBubbles extends StatefulWidget {
  const SpeechBubbles({
    required this.session,
    required this.nameKeyOf,
    this.sea,
    super.key,
  });

  final BattleSession session;

  /// 해적 id → 이름 글자 키.
  final String Function(String pirateId) nameKeyOf;

  /// 캠페인 해역. 그 세력 선장이 도발한다. 없으면(둘이서·테스트 대전) 해적 말만.
  final int? sea;

  /// 보여 두는 시간.
  static const Duration shown = Duration(seconds: 2);

  @override
  State<SpeechBubbles> createState() => _SpeechBubblesState();
}

class _SpeechBubblesState extends State<SpeechBubbles> {
  late final SpeechDirector _director = SpeechDirector(
    me: widget.session.humanSides.isEmpty ? 0 : widget.session.humanSides.first,
    captain: widget.sea != null,
  );
  Bark? _bark;
  Timer? _hide;

  @override
  void initState() {
    super.initState();
    widget.session.addListener(_watch);
  }

  @override
  void dispose() {
    widget.session.removeListener(_watch);
    _hide?.cancel();
    super.dispose();
  }

  void _watch() {
    // 판 상태는 탄이 날기 전에 이미 결과가 반영된다: 연출이 끝난 뒤에만 견준다.
    if (widget.session.playback != null) return;
    final bark = _director.observe(widget.session.state);
    if (bark == null || !mounted) return;
    setState(() => _bark = bark);
    _hide?.cancel();
    _hide = Timer(SpeechBubbles.shown, () {
      if (mounted) setState(() => _bark = null);
    });
  }

  String _nameOf(AppLocalizations l10n, int slot) {
    final crew = widget.session.state.sides[_director.me].crew;
    return dataText(l10n, widget.nameKeyOf(crew.pirates[slot].spec.id));
  }

  @override
  Widget build(BuildContext context) {
    final bark = _bark;
    final l10n = AppLocalizations.of(context);
    return IgnorePointer(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: bark == null
            ? const SizedBox.shrink()
            : Align(
                key: ValueKey(bark),
                alignment: bark.slot < 0
                    ? const Alignment(0.62, -0.42)
                    : const Alignment(0, 0.42),
                child: PopIn(
                  child: _Bubble(
                    who: bark.slot < 0
                        ? dataText(l10n, 'sea_${widget.sea}_faction')
                        : _nameOf(l10n, bark.slot),
                    text: barkText(l10n, bark.kind, bark.line),
                    enemy: bark.slot < 0,
                  ),
                ),
              ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.who, required this.text, required this.enemy});

  final String who;
  final String text;
  final bool enemy;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(maxWidth: 300),
    padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF6E0),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: enemy ? const Color(0xFFE0402F) : const Color(0xFF3B82C4),
        width: 2,
      ),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          who,
          style: TextStyle(
            fontSize: 11,
            color: enemy ? const Color(0xFFB0302A) : const Color(0xFF2B5F8F),
          ),
        ),
        Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 15, color: Color(0xFF2A1A0E)),
        ),
      ],
    ),
  );
}

/// 말풍선 문장 (ARB `bark*`, 종류마다 4줄).
String barkText(AppLocalizations l10n, BarkKind kind, int line) {
  final all = switch (kind) {
    BarkKind.fire => [
      l10n.barkFire1,
      l10n.barkFire2,
      l10n.barkFire3,
      l10n.barkFire4,
    ],
    BarkKind.hurt => [
      l10n.barkHurt1,
      l10n.barkHurt2,
      l10n.barkHurt3,
      l10n.barkHurt4,
    ],
    BarkKind.allyDown => [
      l10n.barkAllyDown1,
      l10n.barkAllyDown2,
      l10n.barkAllyDown3,
      l10n.barkAllyDown4,
    ],
    BarkKind.tauntStart => [
      l10n.barkTauntStart1,
      l10n.barkTauntStart2,
      l10n.barkTauntStart3,
      l10n.barkTauntStart4,
    ],
    BarkKind.tauntLow => [
      l10n.barkTauntLow1,
      l10n.barkTauntLow2,
      l10n.barkTauntLow3,
      l10n.barkTauntLow4,
    ],
  };
  return all[(line - 1).clamp(0, all.length - 1)];
}
