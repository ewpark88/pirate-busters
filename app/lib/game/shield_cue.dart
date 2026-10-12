import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/audio/sound_service.dart';
import 'package:pirate_busters/game/battle_cues.dart';
import 'package:pirate_busters/game/hit_tag.dart';
import 'package:pirate_busters/game/view/fx_text.dart';

/// 보스 뱃머리 방패가 한 묶음 동안 어땠는지 (설계서 §5.4, A43 점검 제안 3, A57).
/// 판정은 시뮬레이션이 끝냈다. 진영 상태는 묶음이 끝난 뒤 값이다.
class ShieldCue {
  const ShieldCue({required this.stood, required this.broke, this.lastCell});

  /// 묶음 [cues] 로 [side] 의 방패를 읽는다. 지금 남은 방패 칸과 이 묶음에서 부서진
  /// 방패 칸을 합쳐 ‘시작할 때 서 있었다’를 되짚는다. 방패가 없거나 이 묶음에
  /// 블록 피해가 없으면 둘 다 거짓이다.
  factory ShieldCue.of(SideState side, List<SimEvent> cues) {
    final shield = side.shieldCells;
    final hit = cues.any(
      (e) => e.kind == SimEventKind.blockHit && e.side == side.side,
    );
    if (shield.isEmpty || !hit) return none;
    final upNow = shield.any(side.grid.hasBlockAt);
    int? last;
    for (final e in cues) {
      final gone =
          e.kind == SimEventKind.blockDestroyed ||
          e.kind == SimEventKind.blockCollapsed;
      if (gone && e.side == side.side && shield.contains(e.cell)) {
        last = e.cell;
      }
    }
    final stood = upNow || last != null;
    return ShieldCue(stood: stood, broke: stood && !upNow, lastCell: last);
  }

  /// 방패가 없거나 이 묶음에 블록 피해가 없었다.
  static const ShieldCue none = ShieldCue(stood: false, broke: false);

  /// 이 묶음이 시작될 때 방패가 하나라도 서 있었다(블록 피해 절반).
  final bool stood;

  /// 이 묶음에서 마지막 방패 칸이 부서졌다.
  final bool broke;

  /// 이 묶음에서 마지막으로 부서진 방패 칸. ‘방패 깨짐!’ 자리.
  final int? lastCell;
}

/// 방패 연출 (A57). [BattleCues.dispatch] 가 부른다.
extension ShieldCues on BattleCues {
  /// 두 진영의 방패 상태.
  List<ShieldCue> shieldsOf(List<SimEvent> cues) => [
    for (final s in session.state.sides) ShieldCue.of(s, cues),
  ];

  /// 마지막 방패 칸이 깨진 진영에 ‘방패 깨짐!’ 이름표와 철판 소리.
  void shieldBroken(List<ShieldCue> shields) {
    for (final (side, s) in shields.indexed) {
      final cell = s.lastCell;
      if (!s.broke || cell == null) continue;
      fx.tag(cellWorld(side, cell), tagText(HitTag.shieldBroken));
      playSfx(Sfx.clang);
    }
  }
}
