import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pb_ai/pb_ai.dart';
import 'package:pirate_busters/app/app_theme.dart';
import 'package:pirate_busters/app/providers.dart';
import 'package:pirate_busters/battle/battle_setup.dart';
import 'package:pirate_busters/campaign/prep_cabins.dart';
import 'package:pirate_busters/campaign/prep_enemy_ship.dart';
import 'package:pirate_busters/campaign/stage_flow.dart';
import 'package:pirate_busters/campaign/stage_node.dart';
import 'package:pirate_busters/campaign/stage_spec.dart';
import 'package:pirate_busters/crew/crew_screen.dart';
import 'package:pirate_busters/data/fleet_store.dart';
import 'package:pirate_busters/data/game_catalog.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';
import 'package:pirate_busters/l10n/data_text.dart';
import 'package:pirate_busters/meta/my_ship.dart';
import 'package:pirate_busters/shipyard/blueprint_preview.dart';
import 'package:pirate_busters/story/cutscene_screen.dart';
import 'package:pirate_busters/story/story_data.dart';
import 'package:pirate_busters/ui/kit/kit_art.dart';
import 'package:pirate_busters/ui/kit/kit_motion.dart';
import 'package:pirate_busters/ui/kit/pb_button.dart';
import 'package:pirate_busters/ui/kit/pb_panel.dart';
import 'package:pirate_busters/ui/kit/pb_scaffold.dart';
import 'package:pirate_busters/ui/meta_icons.dart';

/// 전투 준비 (설계서 §13.3, §13 공통): 왼쪽 내 배 미리보기와 설계도 선택, 가운데 상대 정보(성격
/// 아이콘·날씨·기믹)와 대사, 오른쪽 선실 배치와 코스트, 아래 덱 수정·출항. 세트 표시는 A3.
class BattlePrepScreen extends ConsumerStatefulWidget {
  const BattlePrepScreen({required this.stage, super.key});

  final StageSpec stage;

  @override
  ConsumerState<BattlePrepScreen> createState() => _BattlePrepScreenState();
}

class _BattlePrepScreenState extends ConsumerState<BattlePrepScreen> {
  int _line = 0;

  StageSpec get stage => widget.stage;

  static String personalityLabel(AppLocalizations l10n, Personality p) =>
      dataText(l10n, 'personality_${p.name}');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final catalog = ref.watch(gameCatalogProvider);
    final fleet = ref.watch(fleetStoreProvider);
    final progress = ref.watch(progressProvider);
    final deck = fleet.deck ?? const ['p01_octo', 'p36_tok'];
    final used = deck.fold(
      0,
      (a, id) => a + catalog.pirates.byId(id).rarity.cost,
    );
    return PbScaffold(
      title: '${l10n.prepTitle} · ${stageName(l10n, stage)}',
      region: seaRegion(stage.sea),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(10, 2, 10, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 4,
              child: PopIn(child: _blueprints(l10n, fleet, catalog)),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 5,
              child: PopIn(order: 1, child: _enemy(l10n)),
            ),
            const SizedBox(width: 8),
            // 선실 배치 아래에 덱 수정·출항 (작은 폰 높이 360dp 에 맞춘다).
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: PopIn(
                      order: 2,
                      child: PrepCabins(
                        deck: deck,
                        used: used,
                        limit: progress.costLimit,
                        cabins: progress.ship.hull.cabinSlots,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  PbButton(
                    label: l10n.prepEditDeck,
                    kind: PbButtonKind.secondary,
                    height: 40,
                    fontSize: 16,
                    onPressed: () => _editDeck(context),
                  ),
                  const SizedBox(height: 4),
                  PbButton(
                    label: l10n.prepSail,
                    height: 54,
                    fontSize: 22,
                    onPressed: () => unawaited(_sail()),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 보스전이면 앞 컷신을 한 번 보여준 뒤 출항 (설계서 §15.4).
  Future<void> _sail() async {
    final before = StoryData.bossBefore(stage.id);
    final cuts = StoryData.of(before);
    if (stage.isBoss &&
        cuts != null &&
        !ref.read(progressProvider).hasSeen(before)) {
      await ref
          .read(progressProvider.notifier)
          .update((p) => p.seeStory(before));
      if (!mounted) return;
      await CutsceneScreen.show(context, cuts);
      if (!mounted) return;
    }
    await StageFlow.play(context, ref, stage);
  }

  Future<void> _editDeck(BuildContext context) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const CrewScreen()));
    if (mounted) setState(() {});
  }

  /// 내 배: 출전 설계도 미리보기와 설계도 탭 (설계서 §13.3). 빈 칸이면 실제로 타고
  /// 나갈 추천 설계도를 보여준다.
  Widget _blueprints(
    AppLocalizations l10n,
    FleetStore fleet,
    GameCatalog catalog,
  ) {
    final ship = ref.read(progressProvider).ship;
    final mine = fleet.blueprint(fleet.activeSlot, stage: ship.stage);
    return PbPanel(
      title: l10n.prepMyShip,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: BlueprintPreview(
              blueprint: myBlueprint(fleet, catalog, ship),
            ),
          ),
          if (mine == null)
            Text(
              l10n.prepBlueprintEmpty,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.mute, fontSize: 13),
            ),
          const SizedBox(height: 8),
          Center(
            child: FittedBox(
              child: PbTabs(
                labels: [
                  for (var slot = 0; slot < FleetStore.slots; slot++)
                    l10n.prepBlueprintSlot(slot + 1),
                ],
                selected: fleet.activeSlot,
                onSelect: (slot) async {
                  await fleet.setActiveSlot(slot);
                  if (mounted) setState(() {});
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _enemy(AppLocalizations l10n) {
    final keys = stage.dialogueKeys;
    final gimmick = stage.gimmick;
    return PbPanel(
      title: l10n.prepEnemy,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 세력이 먼저, 그다음 AI 성격 (화면 시안 stage33_prep).
          Row(
            children: [
              MetaIcons.image(MetaIcons.factionOfSea(stage.sea), size: 30),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedText(
                  dataText(l10n, 'sea_${stage.sea}_faction'),
                  size: 17,
                  font: AppFonts.display,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              PbChip(
                icon: MetaIcons.personality(stage.personality),
                label:
                    '${personalityLabel(l10n, stage.personality)} · '
                    '${l10n.prepEnemyCount(stage.enemyDeck.length)}',
              ),
              PbChip(label: l10n.prepWeather(stage.waveLevel, stage.maxWind)),
              if (gimmick != null)
                PbChip(label: dataText(l10n, 'gimmick_$gimmick'), warn: true),
            ],
          ),
          const SizedBox(height: 6),
          // 상대 배 미리보기와 스테이지 전 대사(상대 선장 → 우리 선원), 누르면 넘긴다
          // (설계서 §13.3, §15.4).
          Expanded(
            child: PrepEnemyShip(
              blueprint: BattleSetup(
                ref.read(gameCatalogProvider),
              ).enemyBlueprintOf(stage),
              line: keys.isEmpty ? '' : dataText(l10n, keys[_line]),
              tapHint: l10n.dialogueTap,
              onTap: () => setState(() => _line = (_line + 1) % keys.length),
            ),
          ),
        ],
      ),
    );
  }
}
