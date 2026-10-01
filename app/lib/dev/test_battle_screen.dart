import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pb_ai/pb_ai.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/app/providers.dart';
import 'package:pirate_busters/crew/crew_widgets.dart';
import 'package:pirate_busters/dev/test_battle.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';
import 'package:pirate_busters/ui/battle_screen.dart';
import 'package:pirate_busters/ui/hud/hud_style.dart';
import 'package:pirate_busters/ui/labels.dart';

/// 개발용 테스트 대전 (ADR-053): 등급별로 묶인 해적 중 내 덱·상대 덱을 코스트 한도
/// 없이 골라 AI 와 바로 붙는다. 마지막 선택은 저장해 두고 다음에 그대로 쓴다.
class TestBattleScreen extends ConsumerStatefulWidget {
  const TestBattleScreen({super.key});

  @override
  ConsumerState<TestBattleScreen> createState() => _TestBattleScreenState();
}

class _TestBattleScreenState extends ConsumerState<TestBattleScreen> {
  late final List<List<String>> _decks;
  int _side = 0;
  AiLevel _level = AiLevel.normal;
  int _seed = 1;

  static final int _max = HullSpec.sloop.cabinSlots;

  @override
  void initState() {
    super.initState();
    final fleet = ref.read(fleetStoreProvider);
    _decks = [List.of(fleet.testDeck(0)), List.of(fleet.testDeck(1))];
  }

  void _toggle(String id) {
    final deck = _decks[_side];
    setState(() {
      if (!deck.remove(id) && deck.length < _max) deck.add(id);
    });
    unawaited(ref.read(fleetStoreProvider).setTestDeck(_side, deck));
  }

  void _start() {
    final test = TestBattle(
      deck: List.of(_decks[0]),
      enemyDeck: List.of(_decks[1]),
      level: _level,
    );
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => BattleScreen(seed: _seed++, test: test),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final catalog = ref.watch(gameCatalogProvider);
    final pirates = catalog.data.pirates;
    final deck = _decks[_side];
    return Scaffold(
      backgroundColor: HudColors.panel,
      appBar: AppBar(
        title: Text(l10n.devTestBattle),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: FilledButton(
              onPressed: _decks[0].isEmpty ? null : _start,
              child: Text(l10n.devStart),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  for (final side in const [0, 1])
                    ChoiceChip(
                      key: ValueKey('side_$side'),
                      label: Text(
                        '${side == 0 ? l10n.devMyDeck : l10n.devEnemyDeck}'
                        ' ${_decks[side].length}/$_max',
                      ),
                      selected: _side == side,
                      onSelected: (_) => setState(() => _side = side),
                    ),
                  const SizedBox(width: 16),
                  for (final level in AiLevel.values)
                    ChoiceChip(
                      label: Text(Labels.aiLevel(l10n, level)),
                      selected: _level == level,
                      onSelected: (_) => setState(() => _level = level),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  _decks[1].isEmpty ? l10n.devRandomEnemy : '',
                  style: const TextStyle(color: HudColors.mute),
                ),
              ),
              Expanded(
                // 해적이 많지 않아 한 번에 다 그린다(테스트에서 찾기 쉽게).
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final rarity in Rarity.values)
                        if (pirates.any((p) => p.rarity == rarity)) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Text(
                              Labels.rarity(l10n, rarity),
                              style: const TextStyle(
                                color: HudColors.warn,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: [
                              for (final def in pirates)
                                if (def.rarity == rarity)
                                  SizedBox(
                                    width: 96,
                                    height: 133,
                                    child: PirateTile(
                                      key: ValueKey('pick_${def.id}'),
                                      def: def,
                                      spec: catalog.pirates.byId(def.id),
                                      inDeck: deck.contains(def.id),
                                      onTap: () => _toggle(def.id),
                                    ),
                                  ),
                            ],
                          ),
                        ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
