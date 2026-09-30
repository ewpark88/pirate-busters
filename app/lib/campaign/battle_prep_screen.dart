import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pb_ai/pb_ai.dart';
import 'package:pirate_busters/app/providers.dart';
import 'package:pirate_busters/campaign/stage_flow.dart';
import 'package:pirate_busters/campaign/stage_spec.dart';
import 'package:pirate_busters/crew/crew_screen.dart';
import 'package:pirate_busters/data/fleet_store.dart';
import 'package:pirate_busters/data/game_catalog.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';
import 'package:pirate_busters/l10n/data_text.dart';
import 'package:pirate_busters/ui/hud/hud_style.dart';

/// 전투 준비 (설계서 §13.3): 왼쪽 설계도 선택, 가운데 상대 정보와 대사, 오른쪽 출전 해적
/// 요약, 아래 덱 수정·출항. 세트 표시는 A3.
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
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 40,
        title: Text('${l10n.prepTitle} · ${stage.id}'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _blueprints(l10n, fleet)),
                    const SizedBox(width: 8),
                    Expanded(flex: 2, child: _enemy(l10n)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _deck(
                        l10n,
                        deck,
                        used,
                        progress.costLimit,
                        catalog,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => _editDeck(context),
                    child: Text(l10n.prepEditDeck),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: () => StageFlow.play(context, ref, stage),
                    icon: const Icon(Icons.sailing),
                    label: Text(l10n.prepSail),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editDeck(BuildContext context) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const CrewScreen()));
    if (mounted) setState(() {});
  }

  Widget _blueprints(AppLocalizations l10n, FleetStore fleet) => HudPanel(
    child: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var slot = 0; slot < FleetStore.slots; slot++)
            InkWell(
              onTap: () async {
                await fleet.setActiveSlot(slot);
                if (mounted) setState(() {});
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Icon(
                      slot == fleet.activeSlot
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        fleet.blueprint(slot) == null
                            ? '${l10n.prepBlueprintSlot(slot + 1)} · ${l10n.prepBlueprintEmpty}'
                            : l10n.prepBlueprintSlot(slot + 1),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    ),
  );

  Widget _enemy(AppLocalizations l10n) {
    final keys = stage.dialogueKeys;
    final gimmick = stage.gimmick;
    return HudPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.prepEnemy, style: const TextStyle(color: HudColors.mute)),
          Text(
            '${personalityLabel(l10n, stage.personality)} · '
            '${l10n.prepEnemyCount(stage.enemyDeck.length)}',
          ),
          Text(l10n.prepWeather(stage.waveLevel, stage.maxWind)),
          if (gimmick != null)
            Text(
              dataText(l10n, 'gimmick_$gimmick'),
              style: const TextStyle(color: HudColors.warn),
            ),
          const Divider(color: HudColors.mute),
          // 스테이지 전 대사: 상대 선장 → 우리 선원, 탭하면 넘긴다 (설계서 §15.4).
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _line = (_line + 1) % keys.length),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(
                        keys.isEmpty ? '' : dataText(l10n, keys[_line]),
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                  ),
                  Text(
                    l10n.dialogueTap,
                    style: const TextStyle(color: HudColors.mute, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _deck(
    AppLocalizations l10n,
    List<String> deck,
    int used,
    int limit,
    GameCatalog catalog,
  ) => HudPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.prepDeck, style: const TextStyle(color: HudColors.mute)),
        Expanded(
          child: ListView(
            children: [
              for (final id in deck)
                Text(
                  dataText(l10n, catalog.def(id).nameKey),
                  style: const TextStyle(fontSize: 13),
                ),
            ],
          ),
        ),
        Text(l10n.prepCost(used, limit), style: const TextStyle(fontSize: 13)),
      ],
    ),
  );
}
