import 'package:flame/components.dart';

/// 해적 반응 (설계서 §10.4, A32): 맞으면 맞은 반대쪽으로 밀렸다가 돌아오고, 바다로
/// 떨어지면 포물선을 그리며 날아가 수면에 닿는다. 그리기만 한다. 판정은 끝났다.
class CrewReactions {
  /// 맞았을 때 밀리는 거리(로컬 px).
  static const double knock = 10;

  /// 바다로 떨어지는 시간(초)과 포물선 꼭대기 높이(로컬 px).
  static const double fallSec = 0.7;
  static const double fallArc = 48;

  final Map<int, _Fall> _falls = {};

  /// 해적 발 위치 [home] 을 [dir] 쪽(로컬, +1 = 오른쪽)으로 민다. 발은 선실 자리로
  /// 부드럽게 돌아간다(쫓아가는 움직임이 되돌린다).
  void hit(Vector2 home, int dir) => home.x += dir * knock;

  /// 해적 [slot] 이 [from] 에서 바다로 떨어지기 시작했다. 수면에 닿으면 [onLand].
  void fall(int slot, Vector2 from, void Function() onLand) =>
      _falls[slot] = _Fall(from.clone(), onLand);

  /// 떨어지는 중인가.
  bool falling(int slot) => _falls.containsKey(slot);

  /// 이번 프레임 해적 [slot] 의 발 [home] 을 [target] 쪽으로 옮긴다. 떨어지는 중이면
  /// 포물선, 아니면 [k] 비율로 쫓아간다.
  void move(int slot, Vector2 home, Vector2 target, double k, double dt) {
    final f = _falls[slot];
    if (f == null) {
      home.add((target - home) * k);
      return;
    }
    f.t += dt;
    final u = (f.t / fallSec).clamp(0.0, 1.0);
    home
      ..setFrom(f.from + (target - f.from) * u)
      ..y -= fallArc * 4 * u * (1 - u);
    if (u >= 1) {
      _falls.remove(slot);
      f.onLand();
    }
  }
}

class _Fall {
  _Fall(this.from, this.onLand);

  final Vector2 from;
  final void Function() onLand;
  double t = 0;
}
