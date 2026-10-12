import 'package:flutter/material.dart';
import 'package:pirate_busters/battle/battle_session.dart';
import 'package:pirate_busters/battle/playback.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';
import 'package:pirate_busters/ui/hud/hud_style.dart';

/// 상대 턴 알림 종류.
enum FoeAlertKind { aiming, incoming }

/// 상대 턴 읽기 (설계서 §2.3, §13.4, A34): 상대가 조준하는 동안 ‘상대 조준 중’, 상대
/// 탄이 막 날아오기 시작하면 짧게 ‘포탄이 날아온다!’를 띄운다. 터치를 막지 않는다.
class FoeAlert extends StatelessWidget {
  const FoeAlert({required this.session, super.key});

  final BattleSession session;

  /// 날아옴 경고를 띄우는 시간(밀리초, 발사 뒤).
  static const int incomingMs = 1400;

  /// 지금 띄울 알림. 내 턴·둘이서·판이 끝났으면 없다.
  static FoeAlertKind? kindOf(BattleSession session) {
    if (session.isOver) return null;
    if (session.opponentAim != null) return FoeAlertKind.aiming;
    final p = session.playback;
    if (p is ShotPlayback &&
        !session.humanSides.contains(p.side) &&
        !p.landed &&
        p.elapsedMs < incomingMs) {
      return FoeAlertKind.incoming;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final kind = kindOf(session);
    if (kind == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final color = kind == FoeAlertKind.aiming
        ? HudColors.warn
        : HudColors.danger;
    return IgnorePointer(
      child: HudPanel(
        key: ValueKey('foe-${kind.name}'),
        borderColor: color,
        child: Text(
          kind == FoeAlertKind.aiming ? l10n.foeAiming : l10n.shotIncoming,
          style: TextStyle(fontSize: 18, color: color),
        ),
      ),
    );
  }
}
