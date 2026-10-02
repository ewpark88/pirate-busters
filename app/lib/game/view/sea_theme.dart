import 'dart:ui';

/// 바다 색 (설계서 §10.2 “해역마다 물색·하늘색·조명 값만 바꾼다”). 사인파 바다·
/// 포말·굴절 셰이더가 쓴다. 하늘과 원경은 해역 배경 그림(`Backdrop`)이 그린다
/// (ADR-063). MVP 는 해역 1 일반 모드(맑은 낮)만 쓴다. 나머지 해역·모드 톤은 R3.
class SeaTheme {
  const SeaTheme({required this.sea, required this.foam});

  /// 바다 그라데이션(수면 → 깊은 곳).
  final List<Color> sea;
  final Color foam;

  /// 해역 1 ‘열대 만’ 일반 모드: 맑은 낮 (설계서 §10.2).
  static const SeaTheme tropicalDay = SeaTheme(
    sea: [Color(0xFF2B8FB3), Color(0xFF1B6C92), Color(0xFF0E3F5E)],
    foam: Color(0xFFF4FBFF),
  );
}
