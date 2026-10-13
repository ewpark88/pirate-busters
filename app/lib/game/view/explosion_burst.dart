import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:pirate_busters/game/view/blast_glow.dart';
import 'package:pirate_busters/game/view/blast_sheet.dart';
import 'package:pirate_busters/game/view/explosion_fx.dart';
import 'package:pirate_busters/game/view/fx_layer.dart';

/// 폭발 한 번 (설계서 §10.4 폭발, 게임 정리 S4). 그리기만 한다.
extension ExplosionBurst on FxLayer {
  /// 폭발 (설계서 §10.4, 게임 정리 S4): 부드러운 섬광, 연속 프레임 불덩이 시트(가운데
  /// 큰 것과 둘레 작은 것), 불티, 파편, 떠오르는 연기 기둥, 잠깐 남는 잔불. [radius] 는
  /// 폭발 반경(칸), [heavy] 는 묵직한 한 방·유폭이라 큰 시트와 충격파 고리를 쓴다.
  void burst(Vector2 at, {int radius = 1, bool heavy = false}) {
    final big = heavy || radius >= 2;
    final body = 30.0 + radius * 16 + (heavy ? 14 : 0);
    // 연기는 불덩이 뒤에 깔리도록 먼저 띄운다.
    spawn(
      ExplosionFx.puffs(
        sprites,
        rnd,
        at,
        count: few(2 + radius),
        dark: true,
        size: body * .8,
      ),
    );
    ExplosionFx.rising(
      sprites,
      at - Vector2(0, body * .3),
      body * 1.1,
      delay: .35,
      count: few(big ? 4 : 3),
    ).forEach(spawn);
    spawn(GlowFlash(at, body * 1.3));
    spawn(
      SheetBlast(
        big ? BlastSheet.heavy : BlastSheet.medium,
        sprites,
        at,
        body,
        low: low,
        turn: rnd.nextDouble() * .6 - .3,
      ),
    );
    // 둘레의 작은 불덩이가 조금 늦게 터진다.
    for (var i = 0; i < few(big ? 3 : 1); i++) {
      final a = rnd.nextDouble() * math.pi * 2;
      final off = Vector2(math.cos(a), math.sin(a) * .6) * body * .55;
      spawn(
        SheetBlast(
          BlastSheet.light,
          sprites,
          at + off,
          body * .5,
          delay: .08 + i * .09,
          low: low,
          turn: a,
        ),
      );
    }
    if (heavy) spawn(ShockRing(at, body * 1.5));
    spawn(
      ExplosionFx.embers(
        sprites,
        rnd,
        at,
        count: few(big ? 22 : 12),
        reach: big ? 1.3 : 1,
      ),
    );
    spawn(ExplosionFx.debris(sprites, rnd, at, count: few(6 + radius * 3)));
    for (var i = 0; i < few(3); i++) {
      final dx = (rnd.nextDouble() - .5) * body * .8;
      spawn(
        ExplosionFx.flicker(sprites, at + Vector2(dx, 6), 14, .3 + i * .05),
      );
    }
  }
}
