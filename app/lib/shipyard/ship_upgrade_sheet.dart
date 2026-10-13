import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pirate_busters/app/providers.dart';
import 'package:pirate_busters/dev/dev_flags.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';
import 'package:pirate_busters/meta/ship_shop.dart';
import 'package:pirate_busters/shipyard/shipyard_model.dart';
import 'package:pirate_busters/ui/kit/pb_button.dart';
import 'package:pirate_busters/ui/kit/pb_dialog.dart';
import 'package:pirate_busters/ui/labels.dart';

/// 잠긴 재질을 골드로 연다 (설계서 §13.6). 열었으면 true.
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
    _ => null,
  };
  if (next == null) {
    showPbToast(context, l10n.notEnoughGold);
    return false;
  }
  await ref.read(progressProvider.notifier).update((_) => next);
  return true;
}
