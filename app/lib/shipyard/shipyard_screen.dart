import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/app/providers.dart';
import 'package:pirate_busters/battle/battle_setup.dart';
import 'package:pirate_busters/data/fleet_store.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';
import 'package:pirate_busters/l10n/data_text.dart';
import 'package:pirate_busters/meta/ship_upgrades.dart';
import 'package:pirate_busters/platform/analytics.dart';
import 'package:pirate_busters/shipyard/ship_grid_editor.dart';
import 'package:pirate_busters/shipyard/ship_upgrade_sheet.dart';
import 'package:pirate_busters/shipyard/shipyard_actions.dart';
import 'package:pirate_busters/shipyard/shipyard_model.dart';
import 'package:pirate_busters/shipyard/shipyard_stats.dart';
import 'package:pirate_busters/shipyard/tool_palette.dart';
import 'package:pirate_busters/ui/kit/pb_button.dart';
import 'package:pirate_busters/ui/kit/pb_dialog.dart';
import 'package:pirate_busters/ui/kit/pb_panel.dart';
import 'package:pirate_busters/ui/kit/pb_scaffold.dart';
import 'package:pirate_busters/ui/meta_icons.dart';

/// 간이 조선소 (설계서 §13.6 건조 탭, 개발 계획서 M5): 격자에 재질·선실·모듈을 놓고
/// 수치를 바로 보며, 규칙에 맞으면 설계도 3칸 중 하나에 저장한다.
class ShipyardScreen extends ConsumerStatefulWidget {
  const ShipyardScreen({super.key});

  @override
  ConsumerState<ShipyardScreen> createState() => _ShipyardScreenState();
}

class _ShipyardScreenState extends ConsumerState<ShipyardScreen> {
  late ShipyardModel _model;
  int _slot = 0;

  FleetStore get _fleet => ref.read(fleetStoreProvider);

  ShipUpgrades get _ship => ref.read(progressProvider).ship;

  @override
  void initState() {
    super.initState();
    _slot = _fleet.activeSlot;
    _model = ShipyardModel(hull: _ship.hull);
    _loadSlot(_slot);
  }

  /// 확장 단계·선형 레벨이 바뀌면 그 격자로 다시 연다 (설계서 §3.1, §13.6).
  void _syncHull(HullSpec hull) {
    if (_model.hull.stage == hull.stage && _model.hull.level == hull.level) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _model.dispose();
        _model = ShipyardModel(hull: hull);
        _loadSlot(_slot);
      });
    });
  }

  /// 칸이 비었으면 지금 단계의 추천 설계도 ‘밸런스’로 시작한다. 작은 단계에서 키운
  /// 설계도는 새 칸이 빈 채로 이어 고친다 (설계서 §3.1).
  void _loadSlot(int slot) {
    final catalog = ref.read(gameCatalogProvider);
    final draft = _fleet.draft(slot, _ship.stage);
    if (draft != null && _model.loadJson(draft)) return;
    _model.load(
      _ship.unlockedOnly(
        catalog.preset(BattleSetup.defaultPreset, stage: _ship.stage).blueprint,
      ),
    );
  }

  Future<void> _save(AppLocalizations l10n) async {
    final b = _model.toBlueprint();
    if (b == null) return;
    await _fleet.saveBlueprint(_slot, b);
    ref.read(analyticsProvider).log(Events.shipyardSave, {'slot': _slot});
    if (!mounted) return;
    showPbToast(context, l10n.saved);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final progress = ref.watch(progressProvider);
    final ship = progress.ship;
    _syncHull(ship.hull);
    return PbScaffold(
      title: l10n.menuShipyard,
      actions: [
        PbButton.small(
          label: l10n.shipUpgrades,
          icon: MetaIcons.gold,
          onPressed: () => unawaited(showShipUpgrades(context)),
        ),
        PbButton.small(
          label: l10n.loadPreset,
          icon: MetaIcons.blueprint,
          onPressed: () => unawaited(_pickPreset(l10n)),
        ),
      ],
      body: Padding(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
        child: Column(
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 3, child: _gridPanel()),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: PbPanel(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
                      child: ToolPalette(
                        model: _model,
                        ship: ship,
                        gold: progress.gold,
                        onLocked: (tool, gold) => unawaited(
                          unlockTool(context, ref, tool, gold).then((ok) {
                            if (ok) _model.selectTool(tool);
                          }),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            ListenableBuilder(
              listenable: _model,
              builder: (context, _) => ShipyardActions(
                model: _model,
                slot: _slot,
                active: _fleet.activeSlot == _slot,
                saved: _fleet.blueprint(_slot) != null,
                onSlot: (i) => setState(() {
                  _slot = i;
                  _loadSlot(_slot);
                }),
                onSave: () => unawaited(_save(l10n)),
                onSail: () async {
                  await _fleet.setActiveSlot(_slot);
                  setState(() {});
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 격자 패널: 위 저장 조건, 가운데 바다 바탕 격자, 아래 참고 수치 (설계서 §13.6).
  Widget _gridPanel() => PbPanel(
    padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListenableBuilder(
          listenable: _model,
          builder: (context, _) => ShipyardGauges(model: _model),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x332E5A86), Color(0x14000000)],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: ShipGridEditor(model: _model),
            ),
          ),
        ),
        const SizedBox(height: 4),
        ListenableBuilder(
          listenable: _model,
          builder: (context, _) => ShipyardStatLine(model: _model),
        ),
      ],
    ),
  );

  /// 추천 설계도 불러오기 (설계서 §3.4).
  Future<void> _pickPreset(AppLocalizations l10n) async {
    final presets = ref.read(gameCatalogProvider).presetsAt(_ship.stage);
    final i = await showPbChoice<int>(
      context,
      title: l10n.loadPreset,
      items: [
        for (var i = 0; i < presets.length; i++)
          (i, dataText(l10n, presets[i].nameKey), null),
      ],
    );
    if (i != null) _model.load(_ship.unlockedOnly(presets[i].blueprint));
  }
}
