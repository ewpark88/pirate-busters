import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/app/app_theme.dart';
import 'package:pirate_busters/app/providers.dart';
import 'package:pirate_busters/battle/battle_setup.dart';
import 'package:pirate_busters/crew/crew_filter.dart';
import 'package:pirate_busters/crew/crew_filter_bar.dart';
import 'package:pirate_busters/crew/crew_ship.dart';
import 'package:pirate_busters/crew/crew_widgets.dart';
import 'package:pirate_busters/crew/deck_eval.dart';
import 'package:pirate_busters/crew/pirate_detail.dart';
import 'package:pirate_busters/dev/dev_flags.dart';
import 'package:pirate_busters/dev/operator_limits.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';
import 'package:pirate_busters/meta/my_ship.dart';
import 'package:pirate_busters/ui/kit/kit_motion.dart';
import 'package:pirate_busters/ui/kit/pb_panel.dart';
import 'package:pirate_busters/ui/kit/pb_scaffold.dart';

/// 선원 편성 (설계서 §13.7, 개발 계획서 M5·A63): 왼쪽 내 배의 선실에 해적을 길게
/// 눌러 끌어다 놓는다. 누르면 상세 창(태우기·내리기). 오른쪽 목록은 등급·계열·탄종
/// 필터. 코스트 한도(플레이어 레벨, §4.5)를 넘는 해적은 놓을 수 없다. 바꾸면 바로 저장한다.
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

  /// 선원 화면이 열려 있는 동안 설계도는 바뀌지 않는다(조선소는 다른 화면).
  late final Blueprint _ship;
  CrewFilter _filter = const CrewFilter();

  @override
  void initState() {
    super.initState();
    final fleet = ref.read(fleetStoreProvider);
    final progress = ref.read(progressProvider);
    _hull = progress.ship.hull;
    _ship = myBlueprint(fleet, ref.read(gameCatalogProvider), progress.ship);
    // 자리 수는 지은 배의 선실 + 망대 (설계서 §3.3, §13.7).
    final size = _ship.seatCount;
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
    final limit = ref.read(costLimitProvider);
    return deckProblem(_hull, catalog, deck, limit) == null;
  }

  void _place(String id, int slot) {
    if (!_fits(id, slot)) return;
    setState(() {
      final from = _slots.indexOf(id);
      if (from >= 0) _slots[from] = _slots[slot];
      _slots[slot] = id;
      _compact();
    });
    unawaited(_persist());
  }

  /// 빈 선실을 뒤로 모은다. 덱은 빈자리 없이 앞에서부터 선실에 타므로(저장·전투 모두
  /// `deck[i]` → `cabins[i]`), 화면도 같은 자리를 보여 준다 (A63).
  void _compact() {
    final deck = _deck;
    for (var i = 0; i < _slots.length; i++) {
      _slots[i] = i < deck.length ? deck[i] : null;
    }
  }

  void _remove(int slot) {
    if (_deck.length <= 1 && _slots[slot] != null) return;
    setState(() {
      _slots[slot] = null;
      _compact();
    });
    unawaited(_persist());
  }

  /// 빈 선실 중 [id] 를 태울 수 있는 첫 자리.
  int _boardSlot(String id) {
    for (var i = 0; i < _slots.length; i++) {
      if (_slots[i] == null && _fits(id, i)) return i;
    }
    return -1;
  }

  /// 상세 창을 열고, 고른 일(태우기·내리기)을 한다 (설계서 §13.7, A63).
  Future<void> _detail(String id) async {
    final catalog = ref.read(gameCatalogProvider);
    final slot = _slots.indexOf(id);
    final action = await showPirateDetail(
      context,
      def: catalog.data.pirate(id),
      spec: catalog.pirates.byId(id),
      inDeck: slot >= 0,
      canBoard: slot < 0 && _boardSlot(id) >= 0,
      canUnboard: slot >= 0 && _deck.length > 1,
    );
    if (!mounted) return;
    switch (action) {
      case PirateDetailAction.board when _boardSlot(id) >= 0:
        _place(id, _boardSlot(id));
      case PirateDetailAction.unboard when _slots.contains(id):
        _remove(_slots.indexOf(id));
      case _:
    }
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
    final dev = ref.watch(devToolsProvider);
    final all = widget.showAll ?? dev;
    final listed = [
      for (final def in catalog.data.pirates)
        if (all || owned.contains(def.id)) def,
    ];
    final specs = [for (final d in listed) catalog.pirates.byId(d.id)];
    final shown = [
      for (var i = 0; i < listed.length; i++)
        if (_filter.matches(specs[i])) listed[i],
    ];
    final ship = _ship;
    return PbScaffold(
      title: l10n.menuCrew,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(10, 2, 10, 8),
        child: LayoutBuilder(
          builder: (context, box) => Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                // 배가 충분히 크게 보이게 화면의 45% (최소 330).
                width: (box.maxWidth * 0.45).clamp(330, 520).toDouble(),
                child: PopIn(
                  child: PbPanel(
                    title: l10n.crewHint,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: CrewShip(
                            blueprint: ship,
                            slots: _slots,
                            pirateOf: catalog.data.pirate,
                            canAccept: _fits,
                            onAccept: _place,
                            onTapSlot: (i) {
                              if (_slots[i] case final id?) {
                                unawaited(_detail(id));
                              }
                            },
                          ),
                        ),
                        CrewShipLegend(
                          slots: _slots,
                          pirateOf: catalog.data.pirate,
                        ),
                        // 망대 안내 (설계서 §13.7, §3.3).
                        if (ship.seatCount > ship.cabins.length)
                          Text(
                            l10n.crewNestHint(ship.seatCount),
                            key: const ValueKey('crew-nest-hint'),
                            style: const TextStyle(
                              color: AppColors.gold,
                              fontSize: 12,
                            ),
                          ),
                        const SizedBox(height: 6),
                        CostBar(
                          used: used,
                          limit: ref.watch(costLimitProvider),
                        ),
                        const SizedBox(height: 6),
                        Expanded(
                          flex: 2,
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CrewFilterBar(
                          filter: _filter,
                          onChanged: (f) => setState(() => _filter = f),
                          shown: shown.length,
                          total: listed.length,
                          specs: specs,
                        ),
                        const SizedBox(height: 6),
                        Expanded(
                          child: shown.isEmpty
                              ? Center(
                                  child: Text(
                                    l10n.crewFilterEmpty,
                                    style: const TextStyle(
                                      color: AppColors.mute,
                                    ),
                                  ),
                                )
                              : GridView.extent(
                                  maxCrossAxisExtent: 104,
                                  childAspectRatio: 0.7,
                                  mainAxisSpacing: 6,
                                  crossAxisSpacing: 6,
                                  children: [
                                    for (final def in shown)
                                      PirateTile(
                                        key: ValueKey('crew-tile-${def.id}'),
                                        def: def,
                                        spec: catalog.pirates.byId(def.id),
                                        inDeck: _slots.contains(def.id),
                                        onTap: () => unawaited(_detail(def.id)),
                                      ),
                                  ],
                                ),
                        ),
                      ],
                    ),
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
