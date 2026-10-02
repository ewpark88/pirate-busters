import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

/// 컷신의 해적 그림 (설계서 §15.4 ‘해적 파츠(10.1)를 그대로 써서’): 부위 PNG 를
/// `parts.json` 자리에 겹치고 머리·눈을 표정(`expr.json`) 부위로 바꾼 정지 자세다.
/// [silhouette] 면 검게 칠하고 금관을 씌운다(골드핀, 설계서 §15.4).
class RigPortrait extends StatelessWidget {
  const RigPortrait({
    required this.species,
    required this.height,
    this.team = 'blue',
    this.expr = 'default',
    this.flip = false,
    this.silhouette = false,
    super.key,
  });

  final String species;
  final String team;
  final String expr;
  final double height;

  /// 왼쪽을 본다(오른쪽에 선 적).
  final bool flip;
  final bool silhouette;

  static final Map<String, Future<RigPose>> _cache = {};
  static final Map<String, RigPose> _loaded = {};

  /// 자세 데이터를 읽는다. 같은 해적·팀·표정은 한 번만 읽고, 읽은 뒤에는 바로 그린다.
  static Future<RigPose> pose(String species, String team, String expr) {
    final key = '$species/$team/$expr';
    return _cache.putIfAbsent(
      key,
      () async => _loaded[key] = await RigPose.load(species, team, expr),
    );
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<RigPose>(
    future: pose(species, team, expr),
    initialData: _loaded['$species/$team/$expr'],
    builder: (context, snap) {
      final pose = snap.data;
      if (pose == null) return SizedBox(height: height);
      Widget body = SizedBox(
        width: pose.width,
        height: pose.height,
        child: Stack(
          children: [
            for (final p in pose.parts)
              Positioned.fromRect(
                rect: p.rect,
                child: Image.asset(p.file, fit: BoxFit.fill),
              ),
          ],
        ),
      );
      if (silhouette) {
        body = Stack(
          clipBehavior: Clip.none,
          children: [
            ColorFiltered(
              colorFilter: const ColorFilter.mode(
                Color(0xFF0B0D14),
                BlendMode.srcIn,
              ),
              child: body,
            ),
            Positioned.fromRect(rect: pose.crownRect, child: const _Crown()),
          ],
        );
      }
      return SizedBox(
        height: height,
        width: height * pose.width / pose.height,
        child: FittedBox(
          child: Transform.flip(flipX: flip, child: body),
        ),
      );
    },
  );
}

/// 부위 하나: 그림 경로와 캔버스 안 자리(@2x px).
class RigPart {
  const RigPart(this.id, this.file, this.rect);

  final String id;
  final String file;
  final Rect rect;
}

/// 정지 자세: 캔버스 크기와 z 순 부위. 효과(`fx`) 부위는 뺀다(전투에서도 동작
/// 때만 보인다).
class RigPose {
  const RigPose(this.width, this.height, this.parts);

  final double width;
  final double height;
  final List<RigPart> parts;

  static Future<RigPose> load(String species, String team, String expr) async {
    final dir = 'assets/images/characters/$species';
    final body =
        jsonDecode(await rootBundle.loadString('$dir/parts_$team/parts.json'))
            as Map<String, Object?>;
    // 40명 모두 표정 부위가 있다 (A11, 에셋 v0.22).
    final faces =
        (jsonDecode(await rootBundle.loadString('$dir/expr_$team/expr.json'))
                as Map<String, Object?>)['expressions']!
            as Map<String, Object?>;
    final swap = {
      for (final p in (faces[expr] as List<Object?>?) ?? const <Object?>[])
        (p! as Map<String, Object?>)['id']! as String:
            p as Map<String, Object?>,
    };
    final canvas = (body['canvas']! as List<Object?>).cast<num>();
    final parts = (body['parts']! as List<Object?>).cast<Map<String, Object?>>()
      ..sort((a, b) => (a['z']! as num).compareTo(b['z']! as num));
    return RigPose(canvas[0].toDouble(), canvas[1].toDouble(), [
      for (final p in parts)
        if (p['id'] != 'fx')
          if (swap[p['id']] case final face?)
            _part(p['id']! as String, '$dir/expr_$team', face)
          else
            _part(p['id']! as String, '$dir/parts_$team', p),
    ]);
  }

  static RigPart _part(String id, String dir, Map<String, Object?> j) {
    final o = (j['offset']! as List<Object?>).cast<num>();
    final s = (j['size']! as List<Object?>).cast<num>();
    return RigPart(
      id,
      '$dir/${j['file']}',
      Rect.fromLTWH(
        o[0].toDouble(),
        o[1].toDouble(),
        s[0].toDouble(),
        s[1].toDouble(),
      ),
    );
  }

  /// 금관 자리: 머리 위 가운데, 머리 폭의 절반.
  Rect get crownRect {
    final head = parts
        .firstWhere(
          (p) => p.id == 'head',
          orElse: () => parts.last,
        )
        .rect;
    final w = head.width * 0.5;
    return Rect.fromLTWH(
      head.center.dx - w / 2,
      head.top - w * 0.45,
      w,
      w * 0.6,
    );
  }
}

/// 금관 (새 그림 없이 코드로, 0원 원칙).
class _Crown extends StatelessWidget {
  const _Crown();

  @override
  Widget build(BuildContext context) => CustomPaint(painter: _CrownPainter());
}

class _CrownPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(0, h)
      ..lineTo(0, h * 0.25)
      ..lineTo(w * 0.25, h * 0.6)
      ..lineTo(w * 0.5, 0)
      ..lineTo(w * 0.75, h * 0.6)
      ..lineTo(w, h * 0.25)
      ..lineTo(w, h)
      ..close();
    canvas
      ..drawPath(path, Paint()..color = const Color(0xFFF2C14E))
      ..drawPath(
        path,
        Paint()
          ..color = const Color(0xFF14161C)
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.06
          ..strokeJoin = StrokeJoin.round,
      );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
