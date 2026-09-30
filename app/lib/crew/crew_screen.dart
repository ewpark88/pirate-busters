import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pb_data/pb_data.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/app/providers.dart';
import 'package:pirate_busters/battle/battle_setup.dart';
import 'package:pirate_busters/crew/crew_widgets.dart';
import 'package:pirate_busters/crew/deck_eval.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';

/// 간이 선원 편성 (설계서 §13.7, 개발 계획서 M5): 해적을 선실 슬롯에 끌어다 놓는다.
/// 코스트 한도를 넘는 해적은 놓을 수 없다. 바꾸면 바로 저장한다.
class CrewScreen extends ConsumerStatefulWidget {
  const CrewScreen({super.key});

  @override
  ConsumerState<CrewScreen> createState() => _CrewScreenState();
}

class _CrewScreenState extends ConsumerState<CrewScreen> {
  late final List<String?> _slots;
  late final HullSpec _hull;

  @override
  void initState() {
    super.initState();
    final fleet = ref.read(fleetStoreProvider);
    final hull = fleet.blueprint(fleet.activeSlot)?.hull;
    _hull = hull ?? HullSpec.sloop;
    final size = _hull.cabinSlots;
    final deck = fleet.deck ?? BattleSetup.starterDeck;
    _slots = [for (var i = 0; i < size; i++) i < deck.length ? deck[i] : null];
  }

  List<String> get _deck => [for (final id in _slots) ?id];

  int _costOf(Iterable<String> ids) {
    final pirates = ref.read(gameCatalogProvider).pirates;
    return ids.fold(0, (s, id) => s + pirates.byId(id).cost);
  }

  /// [id] 를 [slot] 에 놓을 수 있는가: 놓은 뒤 코스트가 한도 안.
  bool _fits(String id, int slot) {
    final next = List.of(_slots);
    final from = next.indexOf(id);
    if (from >= 0) next[from] = next[slot];
    next[slot] = id;
    final deck = next.whereType<String>().toList();
    final catalog = ref.read(gameCatalogProvider).pirates;
    return deckProblem(_hull, catalog, deck, BattleSetup.costLimit) == null;
  }

  void _place(String id, int slot) {
    if (!_fits(id, slot)) return;
    setState(() {
      final from = _slots.indexOf(id);
      if (from >= 0) _slots[from] = _slots[slot];
      _slots[slot] = id;
    });
    unawaited(_persist());
  }

  void _remove(int slot) {
    if (_deck.length <= 1 && _slots[slot] != null) return;
    setState(() => _slots[slot] = null);
    unawaited(_persist());
  }

  void _tapPirate(String id) {
    if (_slots.contains(id)) return;
    final empty = _slots.indexOf(null);
    if (empty >= 0) _place(id, empty);
  }

  Future<void> _persist() => ref.read(fleetStoreProvider).setDeck(_deck);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final catalog = ref.watch(gameCatalogProvider);
    final used = _costOf(_deck);
    final eval = DeckEval([for (final id in _deck) catalog.pirates.byId(id)]);
    return Scaffold(
      appBar: AppBar(toolbarHeight: 40, title: Text(l10n.menuCrew)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 300,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.crewHint),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        for (var i = 0; i < _slots.length; i++)
                          CabinSlot(
                            slot: i,
                            pirate: _pirate(catalog.data, _slots[i]),
                            species: catalog.speciesOf,
                            canAccept: (id) => _fits(id, i),
                            onAccept: (id) => _place(id, i),
                            onTap: () => _remove(i),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    CostBar(used: used, limit: BattleSetup.costLimit),
                    const SizedBox(height: 8),
                    Expanded(
                      child: SingleChildScrollView(child: DeckEvalView(eval)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GridView.extent(
                  maxCrossAxisExtent: 96,
                  childAspectRatio: 0.72,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                  children: [
                    for (final def in catalog.data.pirates)
                      PirateTile(
                        def: def,
                        spec: catalog.pirates.byId(def.id),
                        inDeck: _slots.contains(def.id),
                        onTap: () => _tapPirate(def.id),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PirateDef? _pirate(GameData data, String? id) =>
      id == null ? null : data.pirate(id);
}
