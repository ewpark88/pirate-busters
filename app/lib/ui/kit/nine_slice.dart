import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

/// 9조각 바탕 (설계서 §13 공통): 그림을 [slice] 기준 9장으로 잘라 모서리는 [scale]
/// 만큼 줄인 크기 그대로, 가운데만 늘려 그린다.
///
/// `DecorationImage(centerSlice:, scale:)` 는 렌더러마다 배율 처리가 달라 기기
/// (Impeller)에서 모서리가 배율 없이 커지며 버튼·패널이 상자 밖으로 부풀었다(A42).
/// 9장을 `drawImageRect` 로 직접 그려 어느 렌더러에서나 같은 크기로 보이게 한다.
class NineSliceDecoration extends Decoration {
  const NineSliceDecoration({
    required this.image,
    required this.slice,
    required this.scale,
  });

  final ImageProvider image;

  /// 그림 px 기준 늘어나는 가운데.
  final Rect slice;

  /// 그림 px 을 화면 크기로 줄이는 배율(모서리 화면 크기 = 그림 px / [scale]).
  final double scale;

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) =>
      _NineSlicePainter(this, onChanged);

  @override
  bool operator ==(Object other) =>
      other is NineSliceDecoration &&
      other.image == image &&
      other.slice == slice &&
      other.scale == scale;

  @override
  int get hashCode => Object.hash(image, slice, scale);

  /// 그림 크기 [src] 를 [dst] 상자에 그릴 때 9칸의 (그림 사각형, 화면 사각형).
  /// 상자가 모서리 합보다 작으면 모서리를 가로·세로 같은 비율로 줄인다.
  static List<(Rect, Rect)> plan(Size src, Rect slice, double scale, Rect dst) {
    final l = slice.left / scale;
    final t = slice.top / scale;
    final r = (src.width - slice.right) / scale;
    final b = (src.height - slice.bottom) / scale;
    // 모서리 비율이 깨지지 않게 가로·세로를 같은 비율로 줄인다.
    final kx = l + r > dst.width && l + r > 0 ? dst.width / (l + r) : 1.0;
    final ky0 = t + b > dst.height && t + b > 0 ? dst.height / (t + b) : 1.0;
    final k = math.min(kx, ky0);
    final xs = [
      dst.left,
      dst.left + l * k,
      dst.right - r * k,
      dst.right,
    ];
    final ys = [
      dst.top,
      dst.top + t * k,
      dst.bottom - b * k,
      dst.bottom,
    ];
    final sx = [0.0, slice.left, slice.right, src.width];
    final sy = [0.0, slice.top, slice.bottom, src.height];
    return [
      for (var j = 0; j < 3; j++)
        for (var i = 0; i < 3; i++)
          (
            Rect.fromLTRB(sx[i], sy[j], sx[i + 1], sy[j + 1]),
            Rect.fromLTRB(xs[i], ys[j], xs[i + 1], ys[j + 1]),
          ),
    ];
  }
}

class _NineSlicePainter extends BoxPainter {
  _NineSlicePainter(this._d, super.onChanged);

  final NineSliceDecoration _d;
  ImageStream? _stream;
  ImageInfo? _info;
  bool _painting = false;

  /// 이미지가 이미 캐시에 있으면 [paint] 도중 바로 불린다: 그때는 다시 그리기를
  /// 요청하지 않는다(그리는 중 markNeedsPaint 예외).
  late final ImageStreamListener _listener = ImageStreamListener((info, _) {
    _info?.dispose();
    _info = info;
    if (!_painting) onChanged?.call();
  });

  static final Paint _paint = Paint()..filterQuality = ui.FilterQuality.medium;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final stream = _d.image.resolve(configuration);
    if (_stream == null || stream.key != _stream!.key) {
      _stream?.removeListener(_listener);
      _painting = true;
      _stream = stream..addListener(_listener);
      _painting = false;
    }
    final image = _info?.image;
    final size = configuration.size;
    if (image == null || size == null) return;
    final src = Size(image.width.toDouble(), image.height.toDouble());
    for (final (s, d) in NineSliceDecoration.plan(
      src,
      _d.slice,
      _d.scale,
      offset & size,
    )) {
      if (d.width <= 0 || d.height <= 0) continue;
      canvas.drawImageRect(image, s, d, _paint);
    }
  }

  @override
  void dispose() {
    _stream?.removeListener(_listener);
    _info?.dispose();
    super.dispose();
  }
}
