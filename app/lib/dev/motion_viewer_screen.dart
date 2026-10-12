import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pirate_busters/app/app_theme.dart';
import 'package:pirate_busters/app/providers.dart';
import 'package:pirate_busters/dev/motion_preview_game.dart';
import 'package:pirate_busters/dev/practice_bar.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';
import 'package:pirate_busters/l10n/data_text.dart';
import 'package:pirate_busters/ui/kit/pb_panel.dart';
import 'package:pirate_busters/ui/kit/pb_scaffold.dart';
import 'package:pirate_busters/ui/labels.dart';

/// 해적 모션 보기 (ADR-099): 위쪽 줄에서 해적 전원 중 하나를 고르고, 아래에서
/// 동작·팀 색을 바꿔 전장과 같은 부위 동작을 크게 본다.
class MotionViewerScreen extends ConsumerStatefulWidget {
  const MotionViewerScreen({this.game, super.key});

  /// 미리 만든 게임(테스트). null 이면 새로 만든다.
  final MotionPreviewGame? game;

  @override
  ConsumerState<MotionViewerScreen> createState() => _MotionViewerState();
}

class _MotionViewerState extends ConsumerState<MotionViewerScreen> {
  late final MotionPreviewGame _game = widget.game ?? MotionPreviewGame();
  late String _id = ref.read(gameCatalogProvider).data.pirates.first.id;
  bool _red = false;

  @override
  void initState() {
    super.initState();
    _show();
  }

  void _show() {
    final catalog = ref.read(gameCatalogProvider);
    final def = catalog.data.pirates.firstWhere((d) => d.id == _id);
    unawaited(
      _game.show(catalog.speciesOf(_id), def.rarity, _red ? 'red' : 'blue'),
    );
  }

  void _pick(String id) {
    setState(() => _id = id);
    _show();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final def = ref
        .watch(gameCatalogProvider)
        .data
        .pirates
        .firstWhere((d) => d.id == _id);
    final names = {
      Motion.idle: l10n.motionIdle,
      Motion.attack: l10n.motionAttack,
      Motion.hit: l10n.motionHit,
      Motion.aim: l10n.motionAim,
      Motion.fall: l10n.motionFall,
      Motion.swim: l10n.motionSwim,
      Motion.win: l10n.motionWin,
      Motion.lose: l10n.motionLose,
    };
    return PbScaffold(
      title: l10n.operatorMotions,
      body: Stack(
        fit: StackFit.expand,
        children: [
          GameWidget(game: _game),
          PracticeBar(deck: [_id], onPick: _pick),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${dataText(l10n, def.nameKey)} · '
                    '${Labels.rarity(l10n, def.rarity)}',
                    style: const TextStyle(fontSize: 16, color: AppColors.text),
                  ),
                  const SizedBox(height: 6),
                  FittedBox(
                    child: PbTabs(
                      key: const ValueKey('motion_tabs'),
                      labels: [for (final m in Motion.values) names[m]!],
                      selected: _game.motion.index,
                      onSelect: (i) =>
                          setState(() => _game.play(Motion.values[i])),
                    ),
                  ),
                  const SizedBox(height: 6),
                  PbTabs(
                    key: const ValueKey('motion_team'),
                    labels: [l10n.motionTeamBlue, l10n.motionTeamRed],
                    selected: _red ? 1 : 0,
                    onSelect: (i) {
                      setState(() => _red = i == 1);
                      _show();
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
