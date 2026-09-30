import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pirate_busters/app/providers.dart';
import 'package:pirate_busters/campaign/battle_prep_screen.dart';
import 'package:pirate_busters/campaign/stage_spec.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';
import 'package:pirate_busters/l10n/data_text.dart';
import 'package:pirate_busters/meta/progress.dart';
import 'package:pirate_busters/story/cutscene_screen.dart';
import 'package:pirate_busters/story/story_data.dart';
import 'package:pirate_busters/ui/hud/hud_style.dart';

/// 캠페인 지도 (설계서 §13.3). MVP 는 해역 1 일반 모드만: 스테이지 노드·별·보스 노드.
/// 모드 탭·해역 넘기기·인트로 다시 보기는 R3.
class CampaignMapScreen extends ConsumerStatefulWidget {
  const CampaignMapScreen({super.key, this.sea = 1});

  final int sea;

  /// 앞 스테이지를 깼을 때만 연다. 첫 스테이지는 항상 열려 있다.
  static bool unlocked(List<StageSpec> stages, int index, PlayerProgress p) =>
      index == 0 || p.hasCleared(stages[index - 1].id);

  @override
  ConsumerState<CampaignMapScreen> createState() => _CampaignMapScreenState();
}

class _CampaignMapScreenState extends ConsumerState<CampaignMapScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_intro()));
  }

  /// 튜토리얼을 마치고 해역을 처음 열면 해역 인트로 (설계서 §13.3, §15.4). 한 번만.
  Future<void> _intro() async {
    if (widget.sea != 1) return;
    final progress = ref.read(progressProvider);
    final cuts = StoryData.of(StoryData.sea1Intro);
    if (!progress.tutorialFinished ||
        progress.hasSeen(StoryData.sea1Intro) ||
        cuts == null) {
      return;
    }
    await ref
        .read(progressProvider.notifier)
        .update((p) => p.seeStory(StoryData.sea1Intro));
    if (mounted) await CutsceneScreen.show(context, cuts);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sea = ref.watch(campaignProvider).sea(widget.sea);
    final progress = ref.watch(progressProvider);
    // 튜토리얼 3판을 마치기 전에는 튜토리얼 노드만 연다 (설계서 §13.1).
    final tutorial = !progress.tutorialFinished;
    final stages = tutorial ? sea.tutorial : sea.campaign;
    bool open(int i) => tutorial
        ? i <= progress.tutorialDone
        : CampaignMapScreen.unlocked(stages, i, progress);
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 40,
        title: Text(
          '${l10n.campaignTitle} · ${dataText(l10n, 'sea_${widget.sea}_name')}',
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                for (var i = 0; i < stages.length; i++) ...[
                  if (i > 0)
                    Container(
                      width: 28,
                      height: 4,
                      color: open(i) ? HudColors.border : HudColors.mute,
                    ),
                  StageNode(
                    stage: stages[i],
                    stars: progress.starsOf(stages[i].id),
                    locked: !open(i),
                    onTap: () => _open(stages[i], locked: !open(i)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _open(StageSpec stage, {required bool locked}) {
    if (locked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).stageLocked)),
      );
      return;
    }
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => BattlePrepScreen(stage: stage),
        ),
      ),
    );
  }
}

/// 스테이지 노드: 번호, 별 3개, 보스는 크게 (설계서 §13.3).
class StageNode extends StatelessWidget {
  const StageNode({
    required this.stage,
    required this.stars,
    required this.locked,
    required this.onTap,
    super.key,
  });

  final StageSpec stage;
  final int stars;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final size = switch (stage.kind) {
      StageKind.boss => 96.0,
      StageKind.midBoss => 80.0,
      _ => 64.0,
    };
    final kindLabel = switch (stage.kind) {
      StageKind.boss => l10n.stageKindBoss,
      StageKind.midBoss => l10n.stageKindMidBoss,
      _ => null,
    };
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(size / 2),
      child: Opacity(
        opacity: locked ? 0.45 : 1,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: size,
              height: size,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: stage.isBoss ? HudColors.red : HudColors.blue,
                border: Border.all(color: HudColors.border, width: 2),
              ),
              child: locked
                  ? const Icon(Icons.lock, color: HudColors.text)
                  : Text(
                      stage.id,
                      style: TextStyle(
                        color: HudColors.text,
                        fontSize: stage.isBoss ? 22 : 18,
                      ),
                    ),
            ),
            if (kindLabel != null)
              Text(kindLabel, style: const TextStyle(fontSize: 12)),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var s = 1; s <= 3; s++)
                  Icon(
                    s <= stars ? Icons.star : Icons.star_border,
                    size: 16,
                    color: HudColors.warn,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
