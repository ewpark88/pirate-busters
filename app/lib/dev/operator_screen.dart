import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pirate_busters/app/app_theme.dart';
import 'package:pirate_busters/app/providers.dart';
import 'package:pirate_busters/campaign/battle_prep_screen.dart';
import 'package:pirate_busters/campaign/stage_node.dart';
import 'package:pirate_busters/dev/motion_viewer_screen.dart';
import 'package:pirate_busters/dev/operator_actions.dart';
import 'package:pirate_busters/dev/operator_entry.dart';
import 'package:pirate_busters/dev/test_battle_screen.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';
import 'package:pirate_busters/meta/progress.dart';
import 'package:pirate_busters/ui/kit/pb_button.dart';
import 'package:pirate_busters/ui/kit/pb_dialog.dart';
import 'package:pirate_busters/ui/kit/pb_panel.dart';
import 'package:pirate_busters/ui/kit/pb_scaffold.dart';

/// 운영자 화면 (ADR-099): 단계와 상관없이 모든 스테이지·해적·배를 바로 시험한다.
/// 항구 위쪽 운영자 버튼에서 연다. 진행 조작 버튼만 저장을 바꾼다.
class OperatorScreen extends ConsumerWidget {
  const OperatorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final sea = ref.watch(campaignProvider).sea(1);
    void open(Widget screen) => unawaited(
      Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => screen)),
    );
    Future<void> change(PlayerProgress Function(PlayerProgress) f) async {
      await ref.read(progressProvider.notifier).update(f);
      if (context.mounted) showPbToast(context, l10n.operatorDone);
    }

    return PbScaffold(
      title: l10n.operatorMode,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Section(
                  title: l10n.operatorStages,
                  children: [
                    for (final stage in [...sea.tutorial, ...sea.campaign])
                      PbButton.small(
                        key: ValueKey('operator_stage_${stage.id}'),
                        label: stageName(l10n, stage),
                        kind: stage.isBoss
                            ? PbButtonKind.gold
                            : PbButtonKind.secondary,
                        onPressed: () => open(BattlePrepScreen(stage: stage)),
                      ),
                  ],
                ),
                _Section(
                  title: l10n.operatorPirates,
                  children: [
                    PbButton.small(
                      key: const ValueKey('operator_motions'),
                      label: l10n.operatorMotions,
                      kind: PbButtonKind.primary,
                      onPressed: () => open(const MotionViewerScreen()),
                    ),
                    PbButton.small(
                      label: l10n.devTestBattle,
                      onPressed: () => open(const TestBattleScreen()),
                    ),
                  ],
                ),
                _Section(
                  title: l10n.operatorShip,
                  children: [
                    PbButton.small(
                      key: const ValueKey('operator_ship_max'),
                      label: l10n.operatorShipMax,
                      onPressed: () => change(OperatorActions.maxShip),
                    ),
                  ],
                ),
                _Section(
                  title: l10n.operatorProgress,
                  children: [
                    PbButton.small(
                      key: const ValueKey('operator_gold'),
                      label: l10n.operatorGold(
                        NumberFormat.decimalPattern(
                          Localizations.localeOf(context).toString(),
                        ).format(OperatorActions.gold),
                      ),
                      kind: PbButtonKind.gold,
                      onPressed: () => change(OperatorActions.addGold),
                    ),
                    PbButton.small(
                      key: const ValueKey('operator_level'),
                      label: l10n.operatorLevelMax,
                      onPressed: () => change(OperatorActions.maxLevel),
                    ),
                    PbButton.small(
                      key: const ValueKey('operator_pirates'),
                      label: l10n.operatorAllPirates,
                      onPressed: () => change(
                        (p) => OperatorActions.allPirates(p, [
                          for (final d
                              in ref.read(gameCatalogProvider).data.pirates)
                            d.id,
                        ]),
                      ),
                    ),
                    PbButton.small(
                      key: const ValueKey('operator_reset'),
                      label: l10n.operatorReset,
                      onPressed: () async {
                        final ok = await showPbConfirm(
                          context,
                          message: l10n.operatorResetAsk,
                          cancel: l10n.cancel,
                          confirm: l10n.ok,
                        );
                        if (ok) await change(OperatorActions.reset);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Center(
                  child: PbButton(
                    key: const ValueKey('operator_screen_exit'),
                    label: l10n.operatorExit,
                    kind: PbButtonKind.secondary,
                    onPressed: () async {
                      await exitOperator(context, ref);
                      if (context.mounted) Navigator.of(context).pop();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 제목과 버튼 묶음 한 칸.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: PbPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, color: AppColors.text),
          ),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: children),
        ],
      ),
    ),
  );
}
