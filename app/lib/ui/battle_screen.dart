import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pirate_busters/app/providers.dart';
import 'package:pirate_busters/battle/battle_session.dart';
import 'package:pirate_busters/battle/battle_setup.dart';
import 'package:pirate_busters/battle/dummy_controller.dart';
import 'package:pirate_busters/game/battle_game.dart';
import 'package:pirate_busters/ui/hud/battle_hud.dart';

/// 전투 화면: 전장(Flame) 위에 HUD(Flutter 위젯)를 겹친다 (설계서 §13.4).
/// 전장의 게임 루프가 매 프레임 [BattleSession] 을 진행한다.
class BattleScreen extends ConsumerStatefulWidget {
  const BattleScreen({super.key, this.seed = 20260930, this.hotseat = false});

  final int seed;

  /// 한 기기에서 두 사람이 번갈아 둔다(개발용, ADR-029).
  final bool hotseat;

  @override
  ConsumerState<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends ConsumerState<BattleScreen> {
  late BattleSession _session;
  late BattleGame _game;
  bool _paused = false;

  @override
  void initState() {
    super.initState();
    _start(widget.seed, hotseat: widget.hotseat);
  }

  void _start(int seed, {required bool hotseat}) {
    _session = BattleSession(
      BattleSetup.newMatch(seed),
      humanSides: hotseat ? const {0, 1} : const {0},
      opponent: hotseat ? null : const DummyController(),
    );
    _game = BattleGame(_session);
  }

  void _restart({bool? hotseat}) {
    final old = _session;
    setState(() {
      _paused = false;
      _start(
        old.state.seed + 1,
        hotseat: hotseat ?? old.humanSides.length == 2,
      );
    });
    old.dispose();
  }

  void _pause(bool paused) {
    // 일시정지는 사람과 허수아비 판에서만 쓴다 (설계서 §13.4).
    setState(() => _paused = paused);
    _game.paused = paused;
  }

  @override
  void dispose() {
    _session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 저사양 모드는 설정에서 바로 전장에 반영한다.
    _game.lowEnd.value = ref.watch(lowEndProvider);
    return _scaffold();
  }

  Widget _scaffold() => Scaffold(
    backgroundColor: Colors.black,
    body: Stack(
      children: [
        Positioned.fill(
          child: GameWidget(key: ObjectKey(_game), game: _game),
        ),
        Positioned.fill(
          child: BattleHud(
            session: _session,
            overview: _game.overview,
            paused: _paused,
            onPause: _pause,
            onRestart: _restart,
          ),
        ),
      ],
    ),
  );
}
