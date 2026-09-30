import 'dart:ui';

/// 해역·모드별 하늘·바다·조명 색 (설계서 §10.2 “해역마다 물색·하늘색·조명 값만
/// 바꾼다”). M4 는 해역 1 일반 모드(맑은 낮)만 쓴다. 나머지 해역·모드 톤은 R3.
class SeaTheme {
  const SeaTheme({
    required this.sky,
    required this.sun,
    required this.farLand,
    required this.nearLand,
    required this.cloud,
    required this.sea,
    required this.foam,
    required this.light,
  });

  /// 하늘 그라데이션(위 → 수평선).
  final List<Color> sky;
  final Color sun;

  /// 원경 섬(먼 겹·가까운 겹).
  final Color farLand;
  final Color nearLand;
  final Color cloud;

  /// 바다 그라데이션(수면 → 깊은 곳).
  final List<Color> sea;
  final Color foam;

  /// 등대 불빛 등 조명.
  final Color light;

  /// 해역 1 ‘열대 만’ 일반 모드: 맑은 낮 (설계서 §10.2).
  static const SeaTheme tropicalDay = SeaTheme(
    sky: [Color(0xFF3E8ED8), Color(0xFF7FC0EC), Color(0xFFBFE3F4)],
    sun: Color(0xFFFFF4C8),
    farLand: Color(0xFF7FA7A0),
    nearLand: Color(0xFF4F8A6E),
    cloud: Color(0xCCFFFFFF),
    sea: [Color(0xFF2B8FB3), Color(0xFF1B6C92), Color(0xFF0E3F5E)],
    foam: Color(0xFFF4FBFF),
    light: Color(0xFFFFD86A),
  );
}
