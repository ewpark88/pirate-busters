import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/app/app_theme.dart';
import 'package:pirate_busters/app/providers.dart';
import 'package:pirate_busters/dev/dev_flags.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';
import 'package:pirate_busters/meta/my_ship.dart';
import 'package:pirate_busters/meta/progress.dart';
import 'package:pirate_busters/meta/ship_shop.dart';
import 'package:pirate_busters/meta/ship_upgrades.dart';
import 'package:pirate_busters/shipyard/shipyard_model.dart';
import 'package:pirate_busters/ui/kit/kit_motion.dart';
import 'package:pirate_busters/ui/kit/pb_button.dart';
import 'package:pirate_busters/ui/kit/pb_dialog.dart';
import 'package:pirate_busters/ui/kit/pb_panel.dart';
import 'package:pirate_busters/ui/labels.dart';

/// 확장 단계 [stage] 의 이름 (설계서 §3.1).
String shipStageName(AppLocalizations l10n, int stage) => switch (stage) {
  1 => l10n.shipStage1,
  2 => l10n.shipStage2,
  3 => l10n.shipStage3,
  _ => l10n.shipStage4,
};

/// 배 업그레이드 창 (설계서 §3.1 확장 단계, §3.3 돛대 레벨, §13.6 선형 레벨).
/// 모두 골드를 쓴다. 개발 도구가 켜져 있으면 골드 없이 사고 단계를 마음대로 고른다.
Future<void> showShipUpgrades(BuildContext context) =>
    showPbDialog<void>(context, (context) => const _UpgradeSheet());

/// 배가 커졌다는 알림 (설계서 §3.1).
Future<void> showShipGrown(BuildContext context, HullSpec hull) {
  final l10n = AppLocalizations.of(context);
  return showPbDialog<void>(
    context,
    (context) => PbPanel(
      padding: const EdgeInsets.fromLTRB(28, 22, 28, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PopIn(
            child: Text(
              l10n.shipGrown,
              style: const TextStyle(fontSize: 28, color: AppColors.gold),
            ),
          ),
          const SizedBox(height: 8),
          PopIn(
            order: 2,
            child: Text(
              '${shipStageName(l10n, hull.stage)} · '
              '${l10n.shipGrownBody(hull.width, hull.height, hull.cabinSlots)}',
              style: const TextStyle(fontSize: 16, color: AppColors.text),
            ),
          ),
          const SizedBox(height: 16),
          PbButton(
            label: l10n.ok,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    ),
  );
}

/// 잠긴 재질·모듈·돛대를 골드로 연다 (설계서 §13.6). 열었으면 true.
Future<bool> unlockTool(
  BuildContext context,
  WidgetRef ref,
  ShipTool tool,
  int gold,
) async {
  final l10n = AppLocalizations.of(context);
  final dev = ref.read(devToolsProvider);
  final name = switch (tool) {
    MaterialTool(:final material) => Labels.material(l10n, material),
    ModuleTool(:final kind) => Labels.module(l10n, kind),
    _ => '',
  };
  final ok = await showPbConfirm(
    context,
    message: l10n.buyAsk(name, dev ? 0 : gold),
    cancel: l10n.cancel,
    confirm: l10n.buy,
    confirmKind: PbButtonKind.gold,
  );
  if (!ok || !context.mounted) return false;
  final p = ref.read(progressProvider);
  final next = switch (tool) {
    MaterialTool(:final material) => ShipShop.unlockMaterial(
      p,
      material,
      free: dev,
    ),
    ModuleTool(:final kind) => ShipShop.unlockModule(p, kind, free: dev),
    _ => null,
  };
  if (next == null) {
    showPbToast(context, l10n.notEnoughGold);
    return false;
  }
  await ref.read(progressProvider.notifier).update((_) => next);
  return true;
}

class _UpgradeSheet extends ConsumerWidget {
  const _UpgradeSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final p = ref.watch(progressProvider);
    final dev = ref.watch(devToolsProvider);
    final campaign = ref.watch(campaignProvider);
    final opened = openedStageOf(p, campaign);
    final ship = p.ship;

    Future<void> buy(PlayerProgress? next) async {
      if (next == null) {
        showPbToast(context, l10n.notEnoughGold);
        return;
      }
      final grew = next.ship.stage > ship.stage;
      await ref.read(progressProvider.notifier).update((_) => next);
      if (grew && context.mounted) {
        unawaited(showShipGrown(context, next.ship.hull));
      }
    }

    int price(int gold) => dev ? 0 : gold;
    final stage = ShipShop.nextStage(ship);
    final masts = [
      for (final k in ModuleKind.values)
        if (k.isMast && ship.hasModule(k)) k,
    ];
    return PbPanel(
      title: l10n.shipUpgrades,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _row(
              '${l10n.shipGrowRow}: ${shipStageName(l10n, ship.stage)}',
              stage == null
                  ? _note(l10n.shipMaxed)
                  : !dev && stage.$1 > opened
                  ? _note(l10n.shipGrowNeed(stageClearFor(stage.$1, campaign)))
                  : _gold(
                      l10n,
                      price(stage.$2),
                      () => buy(
                        ShipShop.buildStage(p, opened: opened, free: dev),
                      ),
                    ),
            ),
            _row(
              l10n.hullLevelRow(ship.hullLevel),
              ship.hullLevel >= HullSpec.maxLevel
                  ? _note(l10n.shipMaxed)
                  : _gold(
                      l10n,
                      price(ShipUpgrades.hullLevelGold(ship.hullLevel + 1)),
                      () => buy(ShipShop.levelHull(p, free: dev)),
                    ),
            ),
            for (final k in masts)
              _row(
                l10n.mastLevelRow(Labels.module(l10n, k), ship.mastLevel(k)),
                ship.mastLevel(k) >= BlockMaterial.maxRigLevel
                    ? _note(l10n.shipMaxed)
                    : _gold(
                        l10n,
                        price(
                          ShipUpgrades.mastLevelGold[ship.mastLevel(k) + 1]!,
                        ),
                        () => buy(ShipShop.levelMast(p, k, free: dev)),
                      ),
              ),
            if (dev) ...[
              const SizedBox(height: 8),
              Text(
                l10n.devStagePick,
                style: const TextStyle(color: AppColors.mute),
              ),
              const SizedBox(height: 4),
              FittedBox(
                child: PbTabs(
                  labels: [
                    for (var s = 1; s <= HullSpec.maxStage; s++)
                      shipStageName(l10n, s),
                  ],
                  selected: ship.stage - 1,
                  onSelect: (i) => unawaited(
                    buy(p.copyWith(ship: ship.copyWith(stage: i + 1))),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(String label, Widget trailing) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 16, color: AppColors.text),
          ),
        ),
        trailing,
      ],
    ),
  );

  Widget _note(String text) => Text(
    text,
    style: const TextStyle(fontSize: 14, color: AppColors.mute),
  );

  Widget _gold(AppLocalizations l10n, int gold, VoidCallback onPressed) =>
      PbButton(
        label: l10n.goldCost(gold),
        kind: PbButtonKind.gold,
        height: 38,
        minWidth: 110,
        fontSize: 15,
        onPressed: onPressed,
      );
}
