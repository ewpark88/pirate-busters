import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pb_data/pb_data.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/app/providers.dart';
import 'package:pirate_busters/battle/battle_setup.dart';
import 'package:pirate_busters/crew/crew_widgets.dart';
import 'package:pirate_busters/crew/deck_eval.dart';
import 'package:pirate_busters/dev/dev_flags.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';
import 'package:pirate_busters/ui/kit/kit_motion.dart';
import 'package:pirate_busters/ui/kit/pb_panel.dart';
import 'package:pirate_busters/ui/kit/pb_scaffold.dart';

/// 간이 선원 편성 (설계서 §13.7, 개발 계획서 M5): 해적을 선실 슬롯에 끌어다 놓는다.
/// 코스트 한도(플레이어 레벨, §4.5)를 넘는 해적은 놓을 수 없다. 바꾸면 바로 저장한다.
/// 보여 주는 해적은 보유 해적(시작 해적 + 보상, §4.6)뿐이고, 전원은 개발 도구가
/// 켜졌을 때만 (ADR-053, ADR-073).
class CrewScreen extends ConsumerStatefulWidget {
  const CrewScreen({super.key, this.showAll});

  /// 보유와 상관없이 해적 전원을 보여 준다 (개발용, ADR-053). null 이면 개발 도구
  /// 스위치(`devToolsProvider`)를 따른다.
  final bool? showAll;

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
    final limit = ref.read(progressProvider).costLimit;
    return deckProblem(_hull, catalog, deck, limit) == null;
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
    final progress = ref.watch(progressProvider);
    final owned = {...BattleSetup.starterDeck, ...progress.ownedPirates};
    final used = _costOf(_deck);
    final eval = DeckEval([for (final id in _deck) catalog.pirates.byId(id)]);
    return PbScaffold(
      title: l10n.menuCrew,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(10, 2, 10, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 330,
              child: PopIn(
                child: PbPanel(
                  title: l10n.crewHint,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                      CostBar(used: used, limit: progress.costLimit),
                      const SizedBox(height: 6),
                      Expanded(
                        child: SingleChildScrollView(
                          child: DeckEvalView(eval),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: PopIn(
                order: 1,
                child: PbPanel(
                  padding: const EdgeInsets.all(10),
                  child: GridView.extent(
                    maxCrossAxisExtent: 104,
                    childAspectRatio: 0.7,
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                    children: [
                      for (final def in catalog.data.pirates)
                        if ((widget.showAll ?? ref.watch(devToolsProvider)) ||
                            owned.contains(def.id))
                          PirateTile(
                            def: def,
                            spec: catalog.pirates.byId(def.id),
                            inDeck: _slots.contains(def.id),
                            onTap: () => _tapPirate(def.id),
                          ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PirateDef? _pirate(GameData data, String? id) =>
      id == null ? null : data.pirate(id);
}
