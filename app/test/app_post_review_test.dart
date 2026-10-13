import 'package:flutter_test/flutter_test.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/game/hit_tag.dart';
import 'package:pirate_busters/platform/remote_values.dart';

/// S2·S3·S4 앱 사후 점검 (게임 정리, ADR-111): 없어진 규칙의 흔적을 지운 것을 지킨다.
void main() {
  test('화염탄은 불이 붙지 않아 명중 이름표가 없다 (설계서 §4.8)', () {
    expect(HitTag.ofAmmo(AmmoType.fire), isNull);
    expect(HitTag.ofAmmo(AmmoType.sniper), HitTag.crit);
    expect(HitTag.ofAmmo(AmmoType.mine), HitTag.mine);
  });

  test('명중 이름표는 지금 규칙에서 나오는 것만 남았다 (보급·보스 방패·옛 능력 없음)', () {
    expect(
      HitTag.values.map((t) => t.name),
      unorderedEquals([
        'crit',
        'pierce',
        'chain',
        'mine',
        'mineBlast',
        'bite',
        'boarded',
        'repel',
        'shakenOff',
        'pull',
        'blind',
      ]),
    );
  });

  test('원격 규칙 값은 turn_ 접두사만 받는다 (사거리 range_ 는 없어졌다)', () {
    const base = MatchRules();
    expect(
      applyRemoteRules(base, MemoryRemoteValues({'range_maxTurns': 10})),
      same(base),
    );
    expect(
      applyRemoteRules(
        base,
        MemoryRemoteValues({'turn_waveZoneWidth': 6000}),
      ).waveZoneWidth,
      6000,
    );
  });
}
