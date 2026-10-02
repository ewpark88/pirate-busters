import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pirate_busters/app/providers.dart';
import 'package:pirate_busters/data/fleet_store.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';
import 'package:pirate_busters/l10n/data_text.dart';
import 'package:pirate_busters/platform/analytics.dart';
import 'package:pirate_busters/shipyard/ship_grid_editor.dart';
import 'package:pirate_busters/shipyard/shipyard_model.dart';
import 'package:pirate_busters/shipyard/tool_palette.dart';
import 'package:pirate_busters/ui/kit/kit_art.dart';
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
  final ShipyardModel _model = ShipyardModel();
  int _slot = 0;

  FleetStore get _fleet => ref.read(fleetStoreProvider);

  @override
  void initState() {
    super.initState();
    _slot = _fleet.activeSlot;
    _loadSlot(_slot);
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  /// 칸이 비었으면 추천 설계도 ‘밸런스’로 시작한다.
  void _loadSlot(int slot) {
    final catalog = ref.read(gameCatalogProvider);
    _model.load(_fleet.blueprint(slot) ?? catalog.presets.first.blueprint);
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
    return PbScaffold(
      title: l10n.menuShipyard,
      actions: [
        PbIconButton(
          icon: MetaIcons.blueprint,
          tooltip: l10n.loadPreset,
          onPressed: () => unawaited(_pickPreset(l10n)),
        ),
      ],
      body: Padding(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
        child: Column(
          children: [
            ListenableBuilder(
              listenable: _model,
              builder: (context, _) => _stats(context, l10n),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 3,
                    child: PbPanel(
                      padding: const EdgeInsets.all(8),
                      child: ShipGridEditor(model: _model),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: PbPanel(
                      padding: const EdgeInsets.all(8),
                      child: ToolPalette(model: _model),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            ListenableBuilder(
              listenable: _model,
              builder: (context, _) => _actions(l10n),
            ),
          ],
        ),
      ),
    );
  }

  /// 추천 설계도 불러오기 (설계서 §3.4).
  Future<void> _pickPreset(AppLocalizations l10n) async {
    final presets = ref.read(gameCatalogProvider).presets;
    final i = await showPbChoice<int>(
      context,
      title: l10n.loadPreset,
      items: [
        for (var i = 0; i < presets.length; i++)
          (i, dataText(l10n, presets[i].nameKey), null),
      ],
    );
    if (i != null) _model.load(presets[i].blueprint);
  }

  /// 수치 줄: 넘친 값은 빨간색 (설계서 §13.6 “수치가 바로 바뀐다”).
  Widget _stats(BuildContext context, AppLocalizations l10n) {
    final hull = _model.hull;
    final s = _model.stats;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final one = NumberFormat('0.0', locale);
    final two = NumberFormat('0.00', locale);
    final cabins = _model.cabins.length;
    Widget chip(String text, {bool bad = false}) => Padding(
      padding: const EdgeInsets.only(right: 4),
      child: PbChip(label: text, warn: bad),
    );
    // 한 줄로 두고 넘치면 옆으로 민다(작은 폰 높이 360dp 에서 격자 자리를 지킨다).
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          chip(
            l10n.statPoints(s.cost, hull.buildPoints),
            bad: s.cost > hull.buildPoints,
          ),
          chip(l10n.statWaterline(one.format(s.waterline / 1000))),
          chip(l10n.statSpeed(one.format(hull.moveSpeed / 1000))),
          chip(
            l10n.statFuelPerCell(
              two.format(hull.fuelPerCell * s.fuelPermille / 1000),
            ),
          ),
          chip(l10n.statTank(s.tank)),
          chip(
            l10n.statCabins(cabins, hull.cabinSlots),
            bad: cabins != hull.cabinSlots,
          ),
          chip(
            l10n.statModules(s.modulesCounted, hull.moduleLimit),
            bad: s.modulesCounted > hull.moduleLimit,
          ),
          chip(l10n.statCaptain(s.captains), bad: s.captains != 1),
          if (!_model.canSave) chip(l10n.cannotSave, bad: true),
        ],
      ),
    );
  }

  Widget _actions(AppLocalizations l10n) {
    final active = _fleet.activeSlot == _slot;
    final saved = _fleet.blueprint(_slot) != null;
    return Row(
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: FittedBox(
              child: PbTabs(
                labels: [
                  for (var i = 0; i < FleetStore.slots; i++)
                    l10n.planSlot(i + 1),
                ],
                selected: _slot,
                onSelect: (i) => setState(() {
                  _slot = i;
                  _loadSlot(_slot);
                }),
              ),
            ),
          ),
        ),
        PbIconButton(
          icon: KitArt.back,
          tooltip: l10n.undo,
          onPressed: _model.canUndo ? _model.undo : null,
        ),
        const SizedBox(width: 6),
        PbButton(
          label: l10n.save,
          kind: PbButtonKind.gold,
          height: 42,
          minWidth: 90,
          fontSize: 17,
          onPressed: _model.canSave ? () => _save(l10n) : null,
        ),
        const SizedBox(width: 6),
        PbButton(
          label: active ? l10n.sailing : l10n.sailWithThis,
          kind: PbButtonKind.secondary,
          height: 42,
          minWidth: 90,
          fontSize: 16,
          onPressed: saved && !active
              ? () async {
                  await _fleet.setActiveSlot(_slot);
                  setState(() {});
                }
              : null,
        ),
      ],
    );
  }
}
