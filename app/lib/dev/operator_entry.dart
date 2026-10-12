import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pirate_busters/app/app_theme.dart';
import 'package:pirate_busters/dev/dev_flags.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';
import 'package:pirate_busters/ui/kit/pb_button.dart';
import 'package:pirate_busters/ui/kit/pb_dialog.dart';
import 'package:pirate_busters/ui/kit/pb_panel.dart';

/// 설정 화면 맨 아래 운영자 모드 줄 (ADR-099). 숨은 스위치로 드러나기 전이고
/// 운영자 모드도 꺼져 있으면 아무것도 그리지 않는다.
class OperatorEntry extends ConsumerWidget {
  const OperatorEntry({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final on = ref.watch(devToolsProvider);
    if (!on && !ref.watch(operatorRevealProvider)) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: on
          ? PbButton(
              key: const ValueKey('operator_exit'),
              label: l10n.operatorExit,
              kind: PbButtonKind.secondary,
              onPressed: () => exitOperator(context, ref),
            )
          : PbButton(
              key: const ValueKey('operator_enter'),
              label: l10n.operatorEnter,
              kind: PbButtonKind.gold,
              onPressed: () => _enter(context, ref),
            ),
    );
  }

  Future<void> _enter(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final password = await showPbDialog<String>(
      context,
      (_) => const _PasswordDialog(),
    );
    if (password == null || !context.mounted) return;
    final ok = await ref.read(devToolsProvider.notifier).enter(password);
    if (!context.mounted) return;
    showPbToast(context, ok ? l10n.operatorOn : l10n.operatorWrongPassword);
  }
}

/// 운영자 모드를 끄고 알린다. 설정 화면과 운영자 화면이 같이 쓴다.
Future<void> exitOperator(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context);
  await ref.read(devToolsProvider.notifier).exit();
  if (context.mounted) showPbToast(context, l10n.operatorOff);
}

/// 가린 비밀번호 입력 창. 확인하면 입력값, 닫으면 null.
class _PasswordDialog extends StatefulWidget {
  const _PasswordDialog();

  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _submit() => Navigator.of(context).pop(_text.text);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PbPanel(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.operatorMode,
            style: const TextStyle(fontSize: 18, color: AppColors.text),
          ),
          const SizedBox(height: 14),
          TextField(
            key: const ValueKey('operator_password'),
            controller: _text,
            autofocus: true,
            obscureText: true,
            autocorrect: false,
            enableSuggestions: false,
            style: const TextStyle(color: AppColors.text),
            decoration: InputDecoration(labelText: l10n.operatorPassword),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PbButton(
                label: l10n.cancel,
                kind: PbButtonKind.secondary,
                onPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(width: 12),
              PbButton(
                key: const ValueKey('operator_ok'),
                label: l10n.ok,
                onPressed: _submit,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
