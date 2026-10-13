import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:pirate_busters/app/app_theme.dart';
import 'package:pirate_busters/battle/battle_session.dart';
import 'package:pirate_busters/game/finale_director.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';
import 'package:pirate_busters/ui/hud/foe_alert.dart';
import 'package:pirate_busters/ui/hud/hud_style.dart';
import 'package:pirate_busters/ui/kit/kit_art.dart';
import 'package:pirate_busters/ui/kit/kit_motion.dart';

/// 전장 배너 (설계서 §10.4 격침·마무리, §13.4 상대 턴·턴 전환, A54).
///
/// - 턴이 바뀌면 ‘내 턴!’ / ‘상대 턴’, 폭풍 타임이 시작되면 ‘폭풍 타임!’과 잠깐
///   어두워지는 화면을 [turnShown] 동안 띄운다.
/// - 상대 턴 동안에는 ‘상대 턴’ 패널과 상대 턴 읽기(A34)를 시간 판정 띠 아래에 둔다.
/// - 판이 끝나면 결과 화면 전에 ‘격침!’·‘전멸!’·‘시간 판정’(양쪽 침수 비교)을 띄운다.
///
/// 터치를 막지 않고, 판정과 무관하다.
class BattleBanners extends StatefulWidget {
  const BattleBanners({
    required this.session,
    required this.banner,
    required this.myTurn,
    super.key,
  });

  final BattleSession session;
  final ValueListenable<BattleBanner?> banner;
  final bool myTurn;

  /// 상대 턴 패널 자리. 위쪽 패널·거리 막대·시간 판정 띠보다 아래다 (A43 점검 버그 6).
  static const Alignment foeTurnAlignment = Alignment(0, -0.25);

  /// 턴 전환 배너를 보여 두는 시간.
  static const Duration turnShown = Duration(milliseconds: 1100);

  @override
  State<BattleBanners> createState() => _BattleBannersState();
}

class _BattleBannersState extends State<BattleBanners> {
  BattleBanner? _turn;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    widget.banner.addListener(_changed);
  }

  @override
  void didUpdateWidget(BattleBanners old) {
    super.didUpdateWidget(old);
    if (old.banner != widget.banner) {
      old.banner.removeListener(_changed);
      widget.banner.addListener(_changed);
    }
  }

  void _changed() {
    final b = widget.banner.value;
    if (b == null || b.isEnd) {
      setState(() {});
      return;
    }
    _timer?.cancel();
    setState(() => _turn = b);
    _timer = Timer(BattleBanners.turnShown, () {
      if (mounted) setState(() => _turn = null);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    widget.banner.removeListener(_changed);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final end = widget.banner.value;
    final turn = _turn;
    final over = widget.session.isOver;
    return IgnorePointer(
      child: Stack(
        children: [
          if (turn?.kind == BattleBannerKind.storm && !over)
            // 폭풍 타임: 화면이 잠깐 어두워진다.
            const Positioned.fill(
              child: ColoredBox(color: Color(0x55000814)),
            ),
          if (!widget.myTurn && !over)
            Align(
              alignment: BattleBanners.foeTurnAlignment,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PopIn(
                    key: ValueKey('enemy-turn-${widget.session.state.turn}'),
                    child: HudPanel(
                      key: const ValueKey('enemy-turn'),
                      borderColor: HudColors.red,
                      child: Text(
                        l10n.enemyTurn,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  FoeAlert(session: widget.session),
                ],
              ),
            ),
          if (turn != null && !over && turn.kind != BattleBannerKind.foeTurn)
            Align(
              alignment: const Alignment(0, -0.05),
              child: PopIn(
                key: ValueKey('turn-banner-${turn.serial}'),
                child: OutlinedText(
                  turn.kind == BattleBannerKind.storm
                      ? l10n.bannerStorm
                      : l10n.bannerMyTurn,
                  size: 46,
                  color: turn.kind == BattleBannerKind.storm
                      ? HudColors.danger
                      : HudColors.warn,
                  font: AppFonts.display,
                  stroke: 6,
                ),
              ),
            ),
          if (end != null && end.isEnd && over) _end(context, l10n, end),
        ],
      ),
    );
  }

  Widget _end(BuildContext context, AppLocalizations l10n, BattleBanner b) {
    final sides = widget.session.state.sides;
    final format = NumberFormat(
      '0.0',
      Localizations.localeOf(context).toLanguageTag(),
    );
    String flood(int side) => format.format(sides[side].flood / 10);
    final title = switch (b.kind) {
      BattleBannerKind.sunk => l10n.sunkBanner,
      BattleBannerKind.annihilation => l10n.bannerAnnihilation,
      BattleBannerKind.draw => l10n.resultDraw,
      _ => l10n.outcomeTimeDecision,
    };
    final compare =
        b.kind == BattleBannerKind.timeDecision ||
        b.kind == BattleBannerKind.draw;
    return Align(
      alignment: const Alignment(0, -0.1),
      child: PopIn(
        key: ValueKey('end-banner-${b.serial}'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedText(
              title,
              size: 56,
              color: HudColors.warn,
              font: AppFonts.display,
              stroke: 7,
            ),
            if (compare) ...[
              const SizedBox(height: 6),
              HudPanel(
                key: const ValueKey('flood-compare'),
                child: Text(
                  l10n.bannerFloodCompare(flood(0), flood(1)),
                  style: const TextStyle(
                    fontSize: 22,
                    color: Color(0xFF9CC8F0),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
