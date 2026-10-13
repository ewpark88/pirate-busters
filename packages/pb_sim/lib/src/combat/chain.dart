import 'package:pb_sim/src/match/match_state.dart';
import 'package:pb_sim/src/match/sim_event.dart';
import 'package:pb_sim/src/math/fx.dart';
import 'package:pb_sim/src/pirate/ammo.dart';
import 'package:pb_sim/src/pirate/crew.dart';
import 'package:pb_sim/src/pirate/pirate_spec.dart';

/// 연쇄탄 번짐 피해 비율(%) (BALANCE.md A4.8).
const int chainSpreadPercent = 50;

/// 연쇄탄이 직접 맞힐 수 있는 해적: 착탄 칸 ([cx], [cy]) 폭발 범위 안 선실에 타
/// 있는 슬롯. 착탄 전에 구한다(낙하 피해는 ‘맞힘’이 아니다).
List<int> chainStruckCandidates(
  SideState target,
  PirateSpec spec, {
  required int cx,
  required int cy,
}) {
  final r = cappedBlastRadius(spec.blastRadius);
  return [
    for (var slot = 0; slot < target.crew.size; slot++)
      if (target.crew.pirates[slot].status == PirateStatus.aboard &&
          _within(target.cabins[slot].x - cx, target.cabins[slot].y - cy, r))
        slot,
  ];
}

bool _within(int dx, int dy, int r) => dx * dx + dy * dy <= r * r;

/// 연쇄탄 (설계서 §4.8): 이번 착탄(이벤트 [from] 번째부터)에서 [candidates] 해적을
/// 맞혔으면, 같은 배의 아직 맞지 않은 배 위 해적에게 착탄 칸 ([cx], [cy]) 에서 가까운
/// 순(같으면 낮은 슬롯)으로 [PirateSpec.ammoValue] 명까지 해적 피해의 50% 를 준다.
void spreadChain(
  MatchState state,
  SideState target,
  PirateSpec spec, {
  required int cx,
  required int cy,
  required int from,
  required List<int> candidates,
}) {
  final events = state.events;
  final hit = <int>[];
  for (var i = from; i < events.length; i++) {
    final e = events[i];
    if (e.kind == SimEventKind.pirateHit &&
        e.side == target.side &&
        candidates.contains(e.slot) &&
        !hit.contains(e.slot)) {
      hit.add(e.slot);
    }
  }
  if (hit.isEmpty) return;
  final crew = target.crew;
  final next = <(int, int)>[];
  for (var slot = 0; slot < crew.size; slot++) {
    if (hit.contains(slot)) continue;
    if (crew.pirates[slot].status != PirateStatus.aboard) continue;
    final c = target.cabins[slot];
    next.add(((c.x - cx) * (c.x - cx) + (c.y - cy) * (c.y - cy), slot));
  }
  next.sort((a, b) => a.$1 != b.$1 ? a.$1 - b.$1 : a.$2 - b.$2);
  final dmg = roundDiv(spec.pirateDamage * chainSpreadPercent, 100);
  for (final (_, slot) in next.take(spec.ammoValue)) {
    events.add(SimEvent(SimEventKind.chained, side: target.side, slot: slot));
    crew.damage(slot, dmg, target.side, events);
  }
}
