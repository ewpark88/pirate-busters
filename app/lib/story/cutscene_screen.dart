import 'package:flutter/material.dart';
import 'package:pirate_busters/game/view/sea_theme.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';
import 'package:pirate_busters/l10n/data_text.dart';
import 'package:pirate_busters/story/story_data.dart';
import 'package:pirate_busters/ui/hud/hud_style.dart';

/// 전체 화면 컷신 (설계서 §15.4): 해역 배경 위에 해적 초상과 말풍선. 탭하면 다음 컷,
/// 건너뛰기는 항상 있다. 새 일러스트는 만들지 않는다(0원 원칙).
class CutsceneScreen extends StatefulWidget {
  const CutsceneScreen({required this.cuts, super.key});

  final List<StoryCut> cuts;

  /// 컷신을 띄우고 끝날 때까지 기다린다. 건너뛰어도 끝난 것으로 본다.
  static Future<void> show(BuildContext context, List<StoryCut> cuts) =>
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => CutsceneScreen(cuts: cuts),
        ),
      );

  @override
  State<CutsceneScreen> createState() => _CutsceneScreenState();
}

class _CutsceneScreenState extends State<CutsceneScreen> {
  int _index = 0;

  void _next() {
    if (_index + 1 >= widget.cuts.length) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _index++);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cut = widget.cuts[_index];
    const theme = SeaTheme.tropicalDay;
    final species = cut.species;
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _next,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF3E8ED8), Color(0xFFBFE3F4), Color(0xFF1E6FB8)],
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                if (species != null)
                  Align(
                    alignment: cut.enemy
                        ? Alignment.bottomRight
                        : Alignment.bottomLeft,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 90),
                      child: Image.asset(
                        'assets/images/ui/portraits/${species}_${cut.enemy ? 'red' : 'blue'}.png',
                        height: 150,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: HudPanel(
                      padding: const EdgeInsets.all(14),
                      borderColor: cut.enemy ? HudColors.red : theme.sun,
                      child: SizedBox(
                        width: double.infinity,
                        child: Text(
                          dataText(l10n, cut.textKey),
                          style: const TextStyle(fontSize: 17),
                        ),
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.topRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.storySkip),
                  ),
                ),
                Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text(
                      '${_index + 1} / ${widget.cuts.length}',
                      style: const TextStyle(color: HudColors.text),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
