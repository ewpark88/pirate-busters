import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pirate_busters/app/app_theme.dart';
import 'package:pirate_busters/ui/kit/kit_art.dart';
import 'package:pirate_busters/ui/kit/kit_motion.dart';
import 'package:pirate_busters/ui/kit/pb_button.dart';
import 'package:pirate_busters/ui/kit/pb_panel.dart';

/// 키트 패널 대화상자를 튕기며 띄운다 (설계서 §13 공통 화면 규칙). 기본 대화상자 대신 쓴다.
Future<T?> showPbDialog<T>(BuildContext context, WidgetBuilder builder) =>
    showGeneralDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: KitMotion.reducedOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 260),
      pageBuilder: (context, _, _) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Material(
            type: MaterialType.transparency,
            child: builder(context),
          ),
        ),
      ),
      transitionBuilder: (context, a, _, child) => FadeTransition(
        opacity: a,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.85, end: 1).animate(
            CurvedAnimation(parent: a, curve: Curves.easeOutBack),
          ),
          child: child,
        ),
      ),
    );

/// 예·아니오 확인. 확정하면 true.
Future<bool> showPbConfirm(
  BuildContext context, {
  required String message,
  required String cancel,
  required String confirm,
  PbButtonKind confirmKind = PbButtonKind.primary,
}) async {
  final ok = await showPbDialog<bool>(
    context,
    (context) => PbPanel(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 17, color: AppColors.text),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PbButton(
                label: cancel,
                kind: PbButtonKind.secondary,
                onPressed: () => Navigator.of(context).pop(false),
              ),
              const SizedBox(width: 12),
              PbButton(
                label: confirm,
                kind: confirmKind,
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
        ],
      ),
    ),
  );
  return ok ?? false;
}

/// 여러 항목 중 하나 고르기. 고르지 않고 닫으면 null.
Future<T?> showPbChoice<T>(
  BuildContext context, {
  required String title,
  required List<(T value, String label, String? icon)> items,
}) => showPbDialog<T>(
  context,
  (context) => PbPanel(
    title: title,
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (value, label, icon) in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: PbButton(
                label: label,
                icon: icon,
                kind: PbButtonKind.secondary,
                height: 44,
                fontSize: 16,
                onPressed: () => Navigator.of(context).pop(value),
              ),
            ),
        ],
      ),
    ),
  ),
);

/// 화면 위쪽에 잠깐 떴다 사라지는 알림 (SnackBar 대신).
void showPbToast(BuildContext context, String message) {
  final overlay = Overlay.of(context);
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) => Positioned(
      top: MediaQuery.paddingOf(context).top + 64,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: Center(
          child: PopIn(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                image: KitArt.nine(
                  KitArt.buttonSecondary,
                  KitArt.buttonSlice,
                  KitArt.buttonScale,
                ),
              ),
              child: OutlinedText(message, maxLines: 2),
            ),
          ),
        ),
      ),
    ),
  );
  overlay.insert(entry);
  Timer(const Duration(milliseconds: 2200), entry.remove);
}
