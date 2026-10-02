import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pirate_busters/game/view/backdrop.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';
import 'package:pirate_busters/l10n/data_text.dart';
import 'package:pirate_busters/story/backdrop_picture.dart';
import 'package:pirate_busters/story/rig_portrait.dart';
import 'package:pirate_busters/story/story_data.dart';
import 'package:pirate_busters/ui/hud/hud_style.dart';
import 'package:pirate_busters/ui/kit/pb_button.dart';

/// 전체 화면 컷신 (설계서 §15.4): 해역 배경 위에 해적 파츠 그림과 말풍선·자막.
/// 탭하면 다음 컷, 건너뛰기는 항상 있다. 컷 전환은 0.3초 페이드다. 새 일러스트는
/// 만들지 않는다(0원 원칙). 형식은 에셋 v0.23 `story/cutscenes.json`(위아래 띠 56,
/// 자막)을 따른다.
class CutsceneScreen extends StatefulWidget {
  const CutsceneScreen({required this.cuts, super.key});

  final List<StoryCut> cuts;

  /// 컷 전환 페이드 (설계서 §15.4).
  static const Duration fade = Duration(milliseconds: 300);

  /// 배경 데이터와 등장 해적의 자세를 미리 읽는다(첫 컷이 바로 보이게).
  static Future<void> preload(List<StoryCut> cuts) => Future.wait([
    BackdropPicture.data(),
    for (final cut in cuts)
      for (final c in cut.cast)
        RigPortrait.pose(c.species, c.enemy ? 'red' : 'blue', c.expr),
  ]);

  /// 컷신을 띄우고 끝날 때까지 기다린다. 건너뛰어도 끝난 것으로 본다.
  static Future<void> show(BuildContext context, List<StoryCut> cuts) {
    unawaited(preload(cuts));
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => CutsceneScreen(cuts: cuts),
      ),
    );
  }

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
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _next,
        child: LayoutBuilder(
          builder: (context, box) {
            // 위아래 띠: 640 높이 화면에서 56 (에셋 형식 `letterbox`).
            final band = box.maxHeight * 56 / 640;
            return Stack(
              children: [
                Positioned.fill(
                  top: band,
                  bottom: band,
                  child: AnimatedSwitcher(
                    duration: CutsceneScreen.fade,
                    child: _Scene(
                      key: ValueKey(_index),
                      cut: widget.cuts[_index],
                      text: dataText(l10n, widget.cuts[_index].textKey),
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 8,
                  height: band,
                  child: Center(
                    child: PbButton.small(
                      label: l10n.storySkip,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 12,
                  height: band,
                  child: Center(
                    child: Text(
                      '${_index + 1} / ${widget.cuts.length}',
                      style: const TextStyle(color: HudColors.text),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// 컷 한 장: 배경, 해적(우리는 왼쪽·적은 오른쪽), 말풍선 또는 자막.
class _Scene extends StatelessWidget {
  const _Scene({required this.cut, required this.text, super.key});

  final StoryCut cut;
  final String text;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final h = box.maxHeight * 0.5;
      final speaker = cut.speaker;
      // 어두운 모드에서는 해적에도 모드 색 행렬을 씌운다(에셋 README v0.23).
      Widget toned(Widget child) {
        final data = BackdropPicture.loaded;
        if (data == null || cut.mode == SeaMode.normal) return child;
        return ColorFiltered(
          colorFilter: data.modeFilter(cut.mode),
          child: child,
        );
      }

      Widget group({required bool enemy}) => Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final c in cut.cast)
            if (c.enemy == enemy)
              toned(
                RigPortrait(
                  species: c.species,
                  team: enemy ? 'red' : 'blue',
                  expr: c.expr,
                  flip: enemy,
                  silhouette: c.silhouette,
                  height: h,
                ),
              ),
        ],
      );
      final bubbleWidth = (box.maxWidth * 0.46).clamp(200.0, 480.0);
      return Stack(
        children: [
          Positioned.fill(
            child: BackdropPicture(region: cut.region, mode: cut.mode),
          ),
          Positioned(left: 24, bottom: 8, child: group(enemy: false)),
          Positioned(right: 24, bottom: 8, child: group(enemy: true)),
          if (speaker != null)
            Positioned(
              left: speaker.enemy ? null : 24,
              right: speaker.enemy ? 24 : null,
              bottom: h + 4,
              width: bubbleWidth,
              child: _Bubble(text: text, right: speaker.enemy),
            )
          else
            // 자막은 해적을 가리지 않게 위 가운데에 둔다(에셋 형식은 아래 가운데, 계획서 A12·ADR-063).
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: box.maxWidth * 0.64),
                  child: HudPanel(
                    padding: const EdgeInsets.all(12),
                    child: Text(text, style: const TextStyle(fontSize: 17)),
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );
}

/// 말풍선 (에셋 `ui/story/bubble_{left,right}`, 480×130, 꼬리는 말하는 해적 쪽).
/// 모서리·꼬리는 그대로 두고 몸통만 글자 높이에 맞춰 늘인다.
class _Bubble extends StatelessWidget {
  const _Bubble({required this.text, required this.right});

  final String text;
  final bool right;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final k = box.maxWidth / 480;
      return Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/ui/story/bubble_${right ? 'right' : 'left'}.png',
              // 그림은 @2x(960×260). 화면 폭에 맞춘 배율로 9칸 늘이기를 한다.
              scale: 2 / k,
              centerSlice: const Rect.fromLTRB(80, 60, 880, 150),
              fit: BoxFit.fill,
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(32 * k, 18 * k, 26 * k, 44 * k),
            child: Text(
              text,
              style: const TextStyle(fontSize: 16, color: Color(0xFF14161C)),
            ),
          ),
        ],
      );
    },
  );
}
