import 'package:flutter/material.dart';
import 'package:pirate_busters/app/app_theme.dart';

/// 게임 UI 키트 그림 (에셋 `ui/kit/`, 설계서 §13 공통 화면 규칙). 그림은 9조각으로
/// 늘린다: 모서리는 그대로, 가운데만 늘어난다.
abstract final class KitArt {
  static const String _dir = 'assets/images/ui/kit';
  static const String buttonPrimary = '$_dir/button_primary.png';
  static const String buttonGold = '$_dir/button_gold.png';
  static const String buttonSecondary = '$_dir/button_secondary.png';
  static const String panel = '$_dir/panel.png';
  static const String tabActive = '$_dir/tab_active.png';
  static const String tabIdle = '$_dir/tab_idle.png';
  static const String chip = '$_dir/chip.png';
  static const String badge = '$_dir/badge_frame.png';

  /// 뒤로 가기 아이콘 (에셋 `ui/icons/back.png`).
  static const String back = 'assets/images/ui/icons/back.png';

  /// 버튼 536×200 의 늘어나는 가운데(그림 px). 둥근 모서리·광택 줄을 지킨다.
  static const Rect buttonSlice = Rect.fromLTRB(64, 56, 472, 140);

  /// 패널 616×384 의 늘어나는 가운데. 모서리 리벳을 지킨다.
  static const Rect panelSlice = Rect.fromLTRB(48, 48, 568, 330);

  /// 탭 308×88 의 늘어나는 가운데.
  static const Rect tabSlice = Rect.fromLTRB(24, 24, 284, 70);

  /// 그림 px 을 화면 크기로 줄이는 배율. 버튼 높이 200px → 모서리 약 14px.
  static const double buttonScale = 4;
  static const double panelScale = 3;
  static const double tabScale = 3;

  /// [path] 그림을 [slice] 기준 9조각으로 늘린 바탕.
  static DecorationImage nine(String path, Rect slice, double scale) =>
      DecorationImage(
        image: AssetImage(path),
        centerSlice: slice,
        scale: scale,
        fit: BoxFit.fill,
      );
}

/// 어두운 외곽선을 두른 글자. 그림 바탕 위에서도 읽히게 한다 (설계서 §13 공통).
class OutlinedText extends StatelessWidget {
  const OutlinedText(
    this.text, {
    this.size = 16,
    this.color = AppColors.text,
    this.font = AppFonts.round,
    this.stroke = 3,
    this.maxLines = 1,
    super.key,
  });

  final String text;
  final double size;
  final Color color;
  final String font;
  final double stroke;
  final int maxLines;

  /// 이미 아주 굵은 제목 글꼴은 외곽선이 글자 속을 메워 상자처럼 보인다(A25 점검):
  /// 글자 크기의 12% 를 넘지 않게 한다.
  double get strokeWidth =>
      font == AppFonts.display && stroke > size * 0.12 ? size * 0.12 : stroke;

  /// 제목 글꼴은 한글을 겹친 조각으로 만들어, 선 외곽선을 그리면 조각 사이 안쪽 선까지
  /// 그려져 상자처럼 보인다(A25 점검). 이 글꼴은 8방향 그림자로 외곽선을 낸다.
  bool get shadowOutline => font == AppFonts.display;

  @override
  Widget build(BuildContext context) {
    final base = TextStyle(fontFamily: font, fontSize: size);
    if (shadowOutline) {
      final w = strokeWidth / 2;
      return Text(
        text,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        style: base.copyWith(
          color: color,
          shadows: [
            for (final (dx, dy) in const [
              (-1.0, -1.0),
              (0.0, -1.0),
              (1.0, -1.0),
              (-1.0, 0.0),
              (1.0, 0.0),
              (-1.0, 1.0),
              (0.0, 1.0),
              (1.0, 1.0),
            ])
              Shadow(
                color: const Color(0xFF14161C),
                offset: Offset(dx * w, dy * w),
              ),
          ],
        ),
      );
    }
    return Stack(
      children: [
        // 외곽선 층은 RichText 라 글자 찾기·읽어 주기에는 한 번만 잡힌다.
        ExcludeSemantics(
          child: RichText(
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            textScaler: MediaQuery.textScalerOf(context),
            text: TextSpan(
              text: text,
              style: base.copyWith(
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = strokeWidth
                  ..strokeJoin = StrokeJoin.round
                  ..color = const Color(0xFF14161C),
              ),
            ),
          ),
        ),
        Text(
          text,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
          style: base.copyWith(color: color),
        ),
      ],
    );
  }
}
