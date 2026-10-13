import 'dart:ui';

import 'package:flame/components.dart';
import 'package:pirate_busters/game/sprites.dart';

/// 연속 프레임 폭발 시트 한 장 (설계서 §10.4 ‘여러 장의 불덩이 그림이 차례로 바뀌며
/// 뜨거운 불꽃 → 연기’, 게임 정리 S4). 그림은 [cols] 줄로 늘어선 [frame] px 정사각
/// 프레임 [count] 장이다. 출처는 docs/ASSETS.md 「폭발·연기 (S4, CC0)」.
class BlastSheet {
  const BlastSheet(
    this.file, {
    required this.count,
    required this.life,
    this.cols = 6,
    this.frame = 160,
    this.core = .4,
  });

  final String file;

  /// 프레임 수.
  final int count;

  /// 한 번 재생하는 시간(초).
  final double life;
  final int cols;

  /// 프레임 한 장의 그림 크기(px).
  final int frame;

  /// 프레임 폭 대비 불덩이 몸통 지름 비율. 화면 크기를 몸통 기준으로 맞춘다.
  final double core;

  /// 가벼운 착탄: 작고 짧게 식는 불덩이 (Sinestesia ‘Explosion Animations 2’ 4번).
  static const BlastSheet light = BlastSheet(
    'fx/explosion/blast_light.png',
    count: 24,
    life: .7,
    core: .32,
  );

  /// 중간 착탄: 둥근 불덩이가 회색 연기로 식는다 (같은 팩 3번).
  static const BlastSheet medium = BlastSheet(
    'fx/explosion/blast_medium.png',
    count: 24,
    life: .85,
    core: .38,
  );

  /// 묵직한 착탄·유폭: 불기둥 줄기와 연기 꼬리가 길다 (같은 팩 2번).
  static const BlastSheet heavy = BlastSheet(
    'fx/explosion/blast_heavy.png',
    count: 24,
    life: 1.05,
    core: .3,
  );

  /// 포구 불꽃: 오른쪽으로 터지는 불 (Sinestesia ‘2D Explosion Animations’ 2번 앞부분).
  static const BlastSheet muzzle = BlastSheet(
    'fx/explosion/muzzle_side.png',
    count: 12,
    life: .32,
    core: .3,
  );

  static const List<BlastSheet> all = [light, medium, heavy, muzzle];

  /// [age] 초에 그릴 프레임 번호(0 ~ count-1). 끝나면 마지막 프레임.
  int frameAt(double age) {
    if (age <= 0) return 0;
    final i = (age / life * count).floor();
    return i >= count ? count - 1 : i;
  }

  /// 저사양 프레임: 두 장에 한 장만 쓴다 (설계서 §10.4 저사양).
  int lowFrameAt(double age) {
    final f = frameAt(age);
    return f - f % 2;
  }

  /// [index] 번 프레임 그림.
  Sprite sprite(BattleSprites sprites, int index) {
    final whole = sprites.get(file);
    return Sprite(
      whole.image,
      srcPosition: Vector2(
        (index % cols) * frame.toDouble(),
        (index ~/ cols) * frame.toDouble(),
      ),
      srcSize: Vector2.all(frame.toDouble()),
    );
  }

  /// 프레임 그림 전부. 그림 묶음([sprites])마다 한 번만 자른다: 착탄마다 시트 여러
  /// 장을 띄우므로 폭발마다 다시 만들지 않는다.
  List<Sprite> frames(BattleSprites sprites) =>
      (_cache[sprites] ??= {})[this] ??= List.unmodifiable([
        for (var i = 0; i < count; i++) sprite(sprites, i),
      ]);

  static final Expando<Map<BlastSheet, List<Sprite>>> _cache = Expando();
}

/// 시트 폭발 하나: 프레임을 차례로 넘기고, 식은 연기는 조금 떠오르며 퍼진다.
/// 생성자의 `body` 는 불덩이 몸통 지름(월드 px), `flipX` 는 왼쪽을 볼 때 좌우를
/// 뒤집는다.
class SheetBlast extends PositionComponent {
  SheetBlast(
    this.sheet,
    BattleSprites sprites,
    Vector2 at,
    double body, {
    this.delay = 0,
    this.low = false,
    bool flipX = false,
    double turn = 0,
  }) : _frames = sheet.frames(sprites),
       _size = body / sheet.core,
       super(position: at.clone(), anchor: Anchor.center, angle: turn) {
    if (flipX) scale.x = -1;
  }

  final BlastSheet sheet;
  final List<Sprite> _frames;
  final double _size;
  final double delay;

  /// 저사양: 프레임 수를 반으로 (설계서 §10.4 저사양).
  final bool low;
  double _age = 0;
  final Paint _paint = Paint();
  final Vector2 _drawSize = Vector2.zero();

  /// [t] (0~1, 재생 비율)의 크기 배율: 뒤로 갈수록 연기가 조금 퍼진다.
  static double spreadAt(double t) => 1 + .18 * t.clamp(0, 1);

  /// [t] 의 불투명도: 마지막 25% 동안 사라진다.
  static double alphaAt(double t) =>
      t < .75 ? 1 : ((1 - t) / .25).clamp(0, 1).toDouble();

  @override
  void update(double dt) {
    _age += dt;
    final t = (_age - delay) / sheet.life;
    // 식은 연기는 위로 떠오른다.
    if (t > .45) position.y -= dt * 22;
    if (t >= 1) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final age = _age - delay;
    if (age < 0) return;
    final t = age / sheet.life;
    _paint.color = Color.fromRGBO(255, 255, 255, alphaAt(t));
    final f = low ? sheet.lowFrameAt(age) : sheet.frameAt(age);
    _frames[f].render(
      canvas,
      size: _drawSize..setAll(_size * spreadAt(t)),
      anchor: Anchor.center,
      overridePaint: _paint,
    );
  }
}
