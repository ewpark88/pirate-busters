import 'package:flame/components.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/game/battle_cues.dart';
import 'package:pirate_busters/game/coords.dart';
import 'package:pirate_busters/game/view/fx_text.dart';
import 'package:pirate_busters/game/view/hit_weight.dart';

/// 큰 강조 문구 (설계서 §10.4 감정 연출). 글자는 화면이 l10n 으로 만든다 (§14.2).
/// 돛대 부러짐은 A30 에서 더한다.
enum Emphasis {
  /// 큰 피해(묵직한 한 방).
  boom,

  /// 같은 턴 두 발 명중.
  doubleHit,

  /// 선실 직격.
  cabin,
}

/// 감정 연출 판단 (설계서 §10.4, A32): 한 턴에 강조 문구는 하나만 띄운다. 선실 직격이
/// 가장 앞이고, 그다음 큰 피해, 같은 턴 두 번째 명중 순이다. 화면용이라 판정과 무관하고
/// 같은 이벤트 순서면 같은 결과다.
class EmotionTracker {
  int _turn = -1;
  int _hits = 0;
  bool _shown = false;

  /// 새 턴이 시작됐다.
  void turnStart(int turn) {
    _turn = turn;
    _hits = 0;
    _shown = false;
  }

  /// 착탄 묶음 하나: [weight] 는 한 방 크기, [cabinHit] 는 선실 칸을 직접 맞혔는가.
  /// 띄울 문구가 있으면 돌려준다.
  Emphasis? onBatch(HitWeight weight, {required bool cabinHit}) {
    if (weight.score == 0) return null;
    _hits++;
    if (_shown) return null;
    final pick = cabinHit
        ? Emphasis.cabin
        : weight.isHeavy
        ? Emphasis.boom
        : _hits >= 2
        ? Emphasis.doubleHit
        : null;
    if (pick != null) _shown = true;
    return pick;
  }

  int get turn => _turn;
}

/// 감정 연출 (설계서 §10.4): 선실 직격 슬로모션과 강조 문구.
extension EmotionCues on BattleCues {
  /// 슬로모션 길이(초). 저사양은 절반.
  static const double slowSec = 0.6;

  /// [cues] 한 묶음의 감정 연출. [weight] 는 그 묶음의 한 방 크기.
  void emote(List<SimEvent> cues, HitWeight weight) {
    SimEvent? hit;
    for (final e in cues) {
      if (e.kind == SimEventKind.turnStart) emotion.turnStart(e.value);
      if (e.kind == SimEventKind.impact && hit == null) hit = e;
    }
    if (hit == null) return;
    final side = session.state.sides[hit.side];
    final w = side.grid.width;
    final cabinHit = side.cabins.any((c) => c.y * w + c.x == hit!.cell);
    final fewer = fx.few(2) == 1;
    if (cabinHit) stop.slow(fewer ? slowSec / 2 : slowSec);
    final pick = emotion.onBatch(weight, cabinHit: cabinHit);
    if (pick == null) return;
    fx.emphasis(
      Coords.point(hit.x, hit.y) - Vector2(0, 70),
      emphasisText(pick),
      fewer: fewer,
    );
  }
}
