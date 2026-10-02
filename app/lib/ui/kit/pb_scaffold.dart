import 'package:flutter/material.dart';
import 'package:pirate_busters/app/app_theme.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';
import 'package:pirate_busters/story/backdrop_picture.dart';
import 'package:pirate_busters/ui/kit/kit_art.dart';
import 'package:pirate_busters/ui/kit/pb_button.dart';

/// 메타 화면 틀 (설계서 §13 공통 화면 규칙): 해역 그림 바탕 + 위 제목 줄 + 본문.
/// 검은 단색 바탕과 시스템 상단 바를 쓰지 않는다.
class PbScaffold extends StatelessWidget {
  const PbScaffold({
    required this.body,
    this.title,
    this.actions = const [],
    this.region = 'tropic',
    this.dim = 0.35,
    this.onBack,
    super.key,
  });

  /// 제목. null 이면 제목 줄 없이 본문만 둔다(결과 화면).
  final String? title;
  final Widget body;

  /// 제목 줄 오른쪽 단추들.
  final List<Widget> actions;

  /// 바탕 해역 (에셋 `regions.json` 키).
  final String region;

  /// 바탕 위에 덮는 어둠(0~1). 패널 글자가 읽히게 한다.
  final double dim;

  /// 뒤로 가기. null 이면 화면을 닫는다.
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    body: Stack(
      fit: StackFit.expand,
      children: [
        BackdropPicture(region: region),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: dim * 0.6),
                Colors.black.withValues(alpha: dim),
              ],
            ),
          ),
        ),
        SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (title != null)
                PbTopBar(title: title!, actions: actions, onBack: onBack),
              Expanded(child: body),
            ],
          ),
        ),
      ],
    ),
  );
}

/// 제목 줄: 뒤로 가기 단추, 외곽선 제목, 오른쪽 단추.
class PbTopBar extends StatelessWidget {
  const PbTopBar({
    required this.title,
    this.actions = const [],
    this.onBack,
    super.key,
  });

  final String title;
  final List<Widget> actions;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
      child: Row(
        children: [
          if (canPop || onBack != null) ...[
            PbIconButton(
              size: 40,
              icon: KitArt.back,
              tooltip: AppLocalizations.of(context).navBack,
              onPressed: onBack ?? () => Navigator.of(context).maybePop(),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: OutlinedText(
              title,
              size: 22,
              font: AppFonts.display,
              stroke: 4,
            ),
          ),
          for (final a in actions) ...[const SizedBox(width: 8), a],
        ],
      ),
    );
  }
}
