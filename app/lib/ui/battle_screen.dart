import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:pirate_busters/battle/battle_session.dart';
import 'package:pirate_busters/battle/battle_setup.dart';
import 'package:pirate_busters/battle/dummy_controller.dart';
import 'package:pirate_busters/ui/hud/battle_hud.dart';

/// 전투 화면: 전장(Flame) 위에 HUD(Flutter 위젯)를 겹친다 (설계서 §13.4).
class BattleScreen extends StatefulWidget {
  const BattleScreen({super.key, this.seed = 20260930, this.hotseat = false});

  final int seed;

  /// 한 기기에서 두 사람이 번갈아 둔다(개발용, ADR-029).
  final bool hotseat;

  @override
  State<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends State<BattleScreen>
    with SingleTickerProviderStateMixin {
  late BattleSession _session;
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  bool _paused = false;

  @override
  void initState() {
    super.initState();
    _session = _newSession(widget.seed, hotseat: widget.hotseat);
    _ticker = createTicker(_onTick);
    unawaited(_ticker.start());
  }

  static BattleSession _newSession(int seed, {required bool hotseat}) =>
      BattleSession(
        BattleSetup.newMatch(seed),
        humanSides: hotseat ? const {0, 1} : const {0},
        opponent: hotseat ? null : const DummyController(),
      );

  void _onTick(Duration now) {
    final dt = (now - _last).inMilliseconds;
    _last = now;
    // 일시정지는 사람과 허수아비 판에서만 (설계서 §13.4).
    if (dt > 0 && !_paused) _session.update(dt > 100 ? 100 : dt);
  }

  void _restart({bool? hotseat}) {
    setState(() {
      _session.dispose();
      _session = _newSession(
        _session.state.seed + 1,
        hotseat: hotseat ?? _session.humanSides.length == 2,
      );
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    _session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF7EC8E3),
    body: BattleHud(
      session: _session,
      paused: _paused,
      onPause: (p) => setState(() => _paused = p),
      onRestart: _restart,
    ),
  );
}
