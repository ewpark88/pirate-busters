import 'dart:ui';

import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/game/view/damage_painter.dart';
import 'package:pirate_busters/game/view/damage_style.dart';
import 'package:pirate_busters/game/view/iron_damage_painter.dart';
import 'package:pirate_busters/game/view/scorch_painter.dart';
import 'package:pirate_busters/game/view/torn_edge_painter.dart';

/// 배 한 척의 손상 표현 전체(배 속 → 그을음 → 금 → 구멍 → 찢긴 변 → 파편)를
/// 한 장으로 녹화해 다시 쓴다 (설계서 §10.2·§10.4, 에셋 v0.26, ADR-070).
/// 칸 단계나 젖은 줄이 바뀔 때만 다시 녹화한다. 타일을 모두 그린 뒤에 부른다.
class DamageLayer {
  Picture? _picture;
  List<int> _key = const [];

  /// 지금까지 녹화한 횟수 (캐시 테스트용).
  int recordings = 0;

  /// 손상 칸 코드: 설계도에 없음 −1, 블록이면 손상 단계 0~2, 부서졌으면 3.
  /// 블록은 단계 안 닳음 0~3 을 [wearStep] 배로 더해 담는다 (A36).
  static const int none = -1;
  static const int broken = 3;
  static const int wearStep = 4;

  /// 단계 안 닳음 최대값.
  static const int maxWear = 3;

  /// 칸 하나의 손상 코드: 지금 재질 [material], 판 시작 재질 [built], 내구도 [hp]/[max].
  /// 돛대 칸은 손상 그림을 얹지 않는다(돛대는 MastPainter 가 그린다, 설계서 §3.3).
  static int codeOf(int material, int built, int hp, int max) {
    if (material == ShipGrid.emptyCell) {
      return built == ShipGrid.emptyCell || BlockMaterial.values[built].rig
          ? none
          : broken;
    }
    if (BlockMaterial.values[material].rig) return none;
    return ShipGrid.stageFor(hp, max).index + wearStep * wearOf(hp, max);
  }

  /// 단계 안 닳음 0~3 (설계서 §10.2 ‘단계 안 손상’, A36): 지금 단계 구간(내구도의
  /// 3등분) 위끝에서 얼마나 내려왔는가. 구간 위끝이면 0, 다음 단계 직전이면 3.
  static int wearOf(int hp, int max) {
    if (max <= 0 || hp >= max) return 0;
    final hp3 = hp * 3;
    final top = hp3 > max * 2 ? max * 3 : (hp3 > max ? max * 2 : max);
    final depth = top - hp3;
    return depth <= 0
        ? 0
        : (1 + (depth * maxWear - 1) ~/ max).clamp(1, maxWear);
  }

  /// 코드의 손상 단계 부분 ([none]·0~2·[broken]).
  static int stageOf(int code) => code < 0 ? code : code % wearStep;

  /// 코드의 단계 안 닳음 부분 (0~3).
  static int wearPart(int code) => code < 0 ? 0 : code ~/ wearStep;

  /// 칸 단계 [codes](칸 번호 = y × width + x, y 는 위로 는다)와 젖은 줄 수
  /// [wetRows](아래부터)로 손상을 그린다. [materials] 는 칸별 재질이고 부서진
  /// 칸은 판 시작 때 재질이다.
  /// [origin] 은 맨 윗줄 왼쪽 칸의 왼쪽 위, [cell] 은 칸 크기다.
  void paint(
    Canvas canvas, {
    required int width,
    required List<int> codes,
    required List<int> materials,
    required int wetRows,
    required Offset origin,
    required double cell,
  }) {
    if (_picture == null || !_same(codes, wetRows)) {
      _picture?.dispose();
      final recorder = PictureRecorder();
      draw(Canvas(recorder), width, codes, materials, wetRows);
      _picture = recorder.endRecording();
      _key = [...codes, wetRows];
      recordings++;
    }
    canvas
      ..save()
      ..translate(origin.dx, origin.dy)
      ..scale(cell / DamageStyle.unit)
      ..drawPicture(_picture!)
      ..restore();
  }

  void dispose() {
    _picture?.dispose();
    _picture = null;
  }

  /// 지난 녹화의 키와 같은가 (프레임마다 새 리스트를 만들지 않는다).
  bool _same(List<int> codes, int wetRows) {
    if (_key.length != codes.length + 1 || _key.last != wetRows) return false;
    for (var i = 0; i < codes.length; i++) {
      if (_key[i] != codes[i]) return false;
    }
    return true;
  }

  /// 상하좌우가 모두 빈 칸([none])인 부서진 칸은 공중에 뜬 판이 되므로 [none] 으로
  /// 바꾼 사본 (A33, 플레이 점검). 배 안쪽 구멍 무리는 그대로 배 속을 보인다.
  static List<int> floating(int width, List<int> codes) {
    final height = codes.length ~/ width;
    int at(int x, int y) => x < 0 || x >= width || y < 0 || y >= height
        ? none
        : codes[y * width + x];
    return [
      for (var i = 0; i < codes.length; i++)
        if (codes[i] == broken &&
            [
              (1, 0),
              (-1, 0),
              (0, 1),
              (0, -1),
            ].every((d) => at(i % width + d.$1, i ~/ width + d.$2) == none))
          none
        else
          codes[i],
    ];
  }

  /// 단위 공간(칸 = [DamageStyle.unit], 줄 r 은 위에서 아래로)에 그린다.
  static void draw(
    Canvas canvas,
    int width,
    List<int> worn,
    List<int> materials,
    int wetRows,
  ) {
    final codes = [for (final c in worn) stageOf(c)];
    final height = codes.length ~/ width;
    final shown = floating(width, codes);
    int at(int c, int r) => c < 0 || c >= width || r < 0 || r >= height
        ? none
        : shown[(height - 1 - r) * width + c];
    BlockMaterial mat(int c, int r) =>
        BlockMaterial.values[materials[(height - 1 - r) * width + c]];
    bool wet(int r) => height - 1 - r < wetRows;
    Offset o(int c, int r) =>
        Offset(c * DamageStyle.unit, r * DamageStyle.unit);
    // 상하좌우: 참고 구현 D4 순서(오른쪽·왼쪽·아래·위).
    const d4 = [(1, 0, 'r'), (-1, 0, 'l'), (0, 1, 'b'), (0, -1, 't')];

    void each(void Function(int c, int r, int code) f) {
      for (var r = 0; r < height; r++) {
        for (var c = 0; c < width; c++) {
          final code = at(c, r);
          if (code != none) f(c, r, code);
        }
      }
    }

    // 1) 부서진 칸 안쪽(배 속).
    each((c, r, code) {
      if (code != broken) return;
      final sides = [
        for (final (dc, dr, s) in d4)
          if (at(c + dc, r + dr) case final n when n != none && n < broken) s,
      ];
      String? open;
      for (final (dc, dr, s) in d4) {
        if (at(c + dc, r + dr) == none) {
          open = s;
          break;
        }
      }
      DamagePainter.interior(
        canvas,
        o(c, r),
        c,
        r,
        wet: wet(r),
        sides: sides,
        openSide: open,
      );
    });

    // 2) 그을음: 설계도 칸 밖으로 번지지 않게 잘라낸다.
    final hot = ScorchPainter.clusters(width, height, (c, r) => at(c, r) >= 2);
    if (hot.isNotEmpty) {
      final clip = Path();
      each(
        (c, r, _) =>
            clip.addRect(o(c, r) & const Size.square(DamageStyle.unit)),
      );
      canvas
        ..save()
        ..clipPath(clip);
      for (final comp in hot) {
        ScorchPainter.cluster(canvas, comp);
      }
      canvas.restore();
    }

    // 2-1) 단계 안 그을음: 닳을수록 짙게 (설계서 §10.2, A36).
    each((c, r, code) {
      if (code == broken) return;
      final wear = wearPart(worn[(height - 1 - r) * width + c]);
      if (wear > 0) ScorchPainter.wear(canvas, o(c, r), c, r, wear);
    });

    // 3) 금 전부, 4) 구멍 전부 (damage_v3.json `order`).
    each((c, r, code) {
      if (code != 1) return;
      final m = mat(c, r);
      if (m == BlockMaterial.iron) {
        IronDamagePainter.crack(canvas, o(c, r), c, r);
      } else {
        String? entry;
        for (final (dc, dr, s) in d4) {
          if (at(c + dc, r + dr) >= 2) {
            entry = s;
            break;
          }
        }
        final wood = DamageStyle.woodOf(m, wet: wet(r));
        DamagePainter.crackWood(canvas, o(c, r), c, r, wood, entry);
      }
    });
    each((c, r, code) {
      if (code != 2) return;
      final m = mat(c, r);
      final wood = DamageStyle.woodOf(m, wet: wet(r));
      if (m == BlockMaterial.iron) {
        IronDamagePainter.hole(canvas, o(c, r), c, r, wet: wet(r));
      } else {
        DamagePainter.holeWood(canvas, o(c, r), c, r, wood, wet: wet(r));
      }
    });

    // 5) 부서진 칸과 맞닿은 남은 블록의 찢긴 변.
    each((c, r, code) {
      if (code == broken) return;
      final m = mat(c, r);
      for (final (dc, dr, s) in d4) {
        if (at(c + dc, r + dr) != broken) continue;
        if (m == BlockMaterial.iron) {
          TornEdgePainter.iron(canvas, o(c, r), c, r, s, holeWet: wet(r + dr));
        } else {
          TornEdgePainter.wood(
            canvas,
            o(c, r),
            c,
            r,
            s,
            DamageStyle.woodOf(m, wet: wet(r)),
            holeWet: wet(r + dr),
          );
        }
      }
    });

    // 6) 파편: 부서진 칸 바로 아래 블록 윗면, 또는 위가 빈 옆 블록 윗면.
    each((c, r, code) {
      if (code == broken) return;
      final up = at(c, r - 1);
      final beside = at(c - 1, r) == broken || at(c + 1, r) == broken;
      if (up == broken || (up == none && beside)) {
        final m = mat(c, r);
        TornEdgePainter.debris(
          canvas,
          o(c, r),
          c,
          r,
          m == BlockMaterial.iron
              ? DamageStyle.oak
              : DamageStyle.woodOf(m, wet: wet(r)),
        );
      }
    });
  }
}
