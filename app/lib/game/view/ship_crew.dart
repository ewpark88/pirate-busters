import 'dart:math' as math;

import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/game/view/ship_view.dart';

/// 배 위 해적의 동작 (설계서 §10.1, §10.4). 그리기만 한다.
extension ShipCrew on ShipView {
  /// 해적 [slot] 의 공격 동작: 탄이 떠나는 순간(`spawn`)에 손을 뿌리도록 그 직전부터
  /// 재생한다 (설계서 §10.4 발사, A32).
  void playAttack(int slot) {
    final id = session.speciesOf(
      session.state.sides[side].crew.pirates[slot].spec.id,
    );
    final clip = anims.attacks[id];
    if (clip == null || slot >= rigs.length) return;
    final spawn = clip.events.where((e) => e.type == 'spawn').firstOrNull;
    rigs[slot].play(
      clip,
      glint: true,
      from: math.max(0, (spawn?.t ?? 0) - .12),
    );
  }

  /// 피격: 동작·번쩍임과 함께 [push](월드, +1 = 오른쪽) 쪽으로 밀린다 (A32).
  void playHit(int slot, int push) {
    if (slot < 0 || slot >= rigs.length) return;
    rigs[slot].play(anims.hit, expr: 'hit');
    reactions.hit(rigs[slot].home, push * facingOf(side));
  }
}
