import 'dart:convert';
import 'dart:io';

import 'package:pb_sim/pb_sim.dart';
import 'package:test/test.dart';

import 'golden/effect_scenarios.dart';
import 'golden/golden_scenarios.dart';

/// 턴 효과·전설 능력 골든 판 (설계서 §2.3, §3.3, §4.8, §7.1). 효과가 상태 해시에
/// 들어가는지 지킨다.
Replay _replayOf(String name) {
  final json =
      jsonDecode(File('test/golden/$name.json').readAsStringSync())
          as Map<String, Object?>;
  return Replay.fromJson(json['replay']! as Map<String, Object?>);
}

Match _start(Replay r) => Match.start(
  seed: r.seed,
  rules: r.rules,
  blueprints: r.blueprints,
  decks: r.decks,
  costLimits: r.costLimits,
  pirates: goldenCatalog,
);

void main() {
  final names = [for (final g in effectGoldens) g.$1];

  test('효과 골든 판을 한 턴씩 재생하면 매 턴 해시가 저장된 턴 해시와 같다', () {
    for (final name in names) {
      final r = _replayOf(name);
      final m = _start(r);
      for (final b in r.turns) {
        m.playTurn(
          TurnBundle(turn: b.turn, side: b.side, commands: b.commands),
        );
        expect(m.turnLog.last.hash, b.hash, reason: '$name 턴 ${b.turn}');
      }
    }
  });

  test('효과 골든 판은 설치탄·강습 체류·촉수·밀림·끌림·망대 저격·돛대 붕괴를 모두 다룬다', () {
    final seen = <String>{};
    var effectsAtTurnEnd = 0;
    for (final name in names) {
      final r = _replayOf(name);
      final m = _start(r);
      for (final b in r.turns) {
        m.playTurn(b);
        if (m.state.effects.isNotEmpty) effectsAtTurnEnd++;
        for (final e in m.state.events) {
          final shooter = e.kind == SimEventKind.fire
              ? m.state.sides[e.side].crew.pirates[e.slot].spec
              : null;
          seen.addAll([
            if (e.kind == SimEventKind.mineAttached) 'mine',
            if (e.kind == SimEventKind.boarded) 'board',
            if (e.kind == SimEventKind.boardDefended) 'defend',
            if (e.kind == SimEventKind.effectFired)
              EffectKind.values[e.value].name,
            if (e.kind == SimEventKind.pushed) e.value > 0 ? 'pull' : 'push',
            if (e.kind == SimEventKind.moduleDestroyed &&
                e.value == ModuleKind.mast.index)
              'mastBroken',
            if (e.kind == SimEventKind.pirateFell) 'fell',
            if (shooter != null &&
                shooter.ammo == AmmoType.sniper &&
                m.state.sides[e.side].isOnCrowsNest(e.slot))
              'nestSniper',
          ]);
        }
      }
    }
    expect(
      seen,
      containsAll([
        'mine',
        'board',
        'defend',
        EffectKind.mineBlast.name,
        EffectKind.biteAgain.name,
        EffectKind.tentacle.name,
        'push',
        'pull',
        'mastBroken',
        'fell',
        'nestSniper',
      ]),
    );
    expect(effectsAtTurnEnd, greaterThan(0), reason: '턴 끝에 효과가 남는 판');
  });

  test('효과가 남은 턴 끝 상태에서 효과를 바꾸거나 지우면 해시가 달라진다', () {
    final r = _replayOf(names.first);
    final m = _start(r);
    for (final b in r.turns) {
      m.playTurn(b);
      if (m.state.effects.isNotEmpty) break;
    }
    final effects = m.state.effects;
    expect(effects, isNotEmpty);
    final before = hashMatchState(m.state);
    effects.first.turnsLeft += 1;
    expect(hashMatchState(m.state), isNot(before));
    effects.first.turnsLeft -= 1;
    expect(hashMatchState(m.state), before);
    final removed = effects.removeAt(0);
    expect(hashMatchState(m.state), isNot(before));
    effects.insert(0, removed);
    expect(hashMatchState(m.state), before);
  });
}
