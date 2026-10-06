import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pirate_busters/app/app_theme.dart';
import 'package:pirate_busters/app/providers.dart';
import 'package:pirate_busters/campaign/battle_prep_screen.dart';
import 'package:pirate_busters/campaign/stage_node.dart';
import 'package:pirate_busters/campaign/stage_spec.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';
import 'package:pirate_busters/l10n/data_text.dart';
import 'package:pirate_busters/meta/progress.dart';
import 'package:pirate_busters/story/cutscene_screen.dart';
import 'package:pirate_busters/story/story_data.dart';
import 'package:pirate_busters/ui/kit/kit_motion.dart';
import 'package:pirate_busters/ui/kit/pb_button.dart';
import 'package:pirate_busters/ui/kit/pb_dialog.dart';
import 'package:pirate_busters/ui/kit/pb_panel.dart';
import 'package:pirate_busters/ui/kit/pb_scaffold.dart';
import 'package:pirate_busters/ui/meta_icons.dart';

/// 캠페인 지도 (설계서 §13.3, §13 공통). MVP 는 해역 1 일반 모드만: 해역 그림 위
/// 섬 노드·점선 항로·별·보스 깃발, 본 이야기 다시 보기(§15.4). 모드 탭·해역 넘기기는 R3.
class CampaignMapScreen extends ConsumerStatefulWidget {
  const CampaignMapScreen({super.key, this.sea = 1});

  final int sea;

  /// 튜토리얼을 마치고 해역을 처음 열면 해역 인트로 (설계서 §13.3, §15.4). 한 번만.
  /// 지도와 항구 ‘다음 목표’ 카드가 함께 쓴다(카드로 바로 들어가도 인트로를 본다).
  static Future<void> seaIntro(BuildContext context, WidgetRef ref) async {
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
    if (context.mounted) await CutsceneScreen.show(context, cuts);
  }

  /// 앞 스테이지를 깼을 때만 연다. 첫 스테이지는 항상 열려 있다.
  static bool unlocked(List<StageSpec> stages, int index, PlayerProgress p) =>
      index == 0 || p.hasCleared(stages[index - 1].id);

  /// 본 이야기 목록. 순서는 이야기 순 (설계서 §15.4). 프롤로그는 따로 기록된다.
  static List<String> seenStories(PlayerProgress p) => [
    for (final id in [
      StoryData.prologue,
      StoryData.sea1Intro,
      StoryData.bossBefore('1-5'),
      StoryData.bossAfter('1-5'),
      StoryData.bossBefore('1-12'),
      StoryData.bossAfter('1-12'),
    ])
      if (StoryData.of(id) != null &&
          (p.hasSeen(id) || (id == StoryData.prologue && p.prologueSeen)))
        id,
  ];

  static String storyTitle(AppLocalizations l10n, String id) => switch (id) {
    StoryData.prologue => l10n.storyTitlePrologue,
    StoryData.sea1Intro => l10n.storyTitleSea1Intro,
    's1_5_before' => l10n.storyTitleMidBossBefore,
    's1_5_after' => l10n.storyTitleMidBossAfter,
    's1_12_before' => l10n.storyTitleBossBefore,
    's1_12_after' => l10n.storyTitleBossAfter,
    _ => id,
  };

  @override
  ConsumerState<CampaignMapScreen> createState() => _CampaignMapScreenState();
}

class _CampaignMapScreenState extends ConsumerState<CampaignMapScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_intro()));
  }

  Future<void> _intro() async {
    if (widget.sea == 1) await CampaignMapScreen.seaIntro(context, ref);
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
    var current = 0;
    for (var i = 0; i < stages.length; i++) {
      if (open(i)) current = i;
    }
    return PbScaffold(
      title:
          '${l10n.campaignTitle} · ${dataText(l10n, 'sea_${widget.sea}_name')}',
      region: seaRegion(widget.sea),
      dim: 0.1,
      actions: [
        PbIconButton(
          icon: MetaIcons.replay,
          tooltip: l10n.storyReplay,
          onPressed: () => unawaited(_replayStories(progress)),
        ),
      ],
      body: LayoutBuilder(
        builder: (context, box) {
          // 노드는 물결 모양으로 놓고 점선 항로로 잇는다 (설계서 §13.3).
          const gap = 150.0;
          final width = math.max(box.maxWidth, 120 + gap * stages.length);
          final mid = box.maxHeight * 0.52;
          final wave = math.min(box.maxHeight * 0.16, 60).toDouble();
          final left = (width - gap * (stages.length - 1)) / 2;
          final centers = [
            for (var i = 0; i < stages.length; i++)
              Offset(left + gap * i, mid + (i.isEven ? wave : -wave) * 0.6),
          ];
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: width,
              height: box.maxHeight,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(painter: RoutePainter(centers, current)),
                  ),
                  for (var i = 0; i < stages.length; i++)
                    Positioned(
                      left: centers[i].dx - 70,
                      width: 140,
                      top: centers[i].dy - StageNode.sizeOf(stages[i]) / 2 - 38,
                      child: PopIn(
                        order: i,
                        child: StageNode(
                          stage: stages[i],
                          stars: progress.starsOf(stages[i].id),
                          locked: !open(i),
                          current: i == current,
                          onTap: () => _open(stages[i], locked: !open(i)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// 본 이야기를 골라 다시 본다 (설계서 §13.3, §15.4).
  Future<void> _replayStories(PlayerProgress progress) async {
    final l10n = AppLocalizations.of(context);
    final seen = CampaignMapScreen.seenStories(progress);
    final picked = seen.isEmpty
        ? await showPbDialog<String>(
            context,
            (context) => PbPanel(
              title: l10n.storyReplay,
              child: Text(
                l10n.storyReplayEmpty,
                style: const TextStyle(fontSize: 16, color: AppColors.text),
              ),
            ),
          )
        : await showPbChoice<String>(
            context,
            title: l10n.storyReplay,
            items: [
              for (final id in seen)
                (id, CampaignMapScreen.storyTitle(l10n, id), MetaIcons.replay),
            ],
          );
    final cuts = picked == null ? null : StoryData.of(picked);
    if (cuts != null && mounted) await CutsceneScreen.show(context, cuts);
  }

  void _open(StageSpec stage, {required bool locked}) {
    if (locked) {
      showPbToast(context, AppLocalizations.of(context).stageLocked);
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
