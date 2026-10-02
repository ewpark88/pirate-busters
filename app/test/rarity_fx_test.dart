import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/game/anim/anim_data.dart';
import 'package:pirate_busters/game/anim/rarity_fx.dart';
import 'package:pirate_busters/game/view/aim_painter.dart';
import 'package:pirate_busters/game/view/rarity_painter.dart';
import 'package:pirate_busters/game/view/trail_painter.dart';

void main() {
  final fx = PbAnims.fromJsonString(
    File('assets/data/anims.json').readAsStringSync(),
  ).rarity;

  group('등급별 전투 연출 값 (설계서 §10.5)', () {
    test('일반은 색을 더하지 않고, 등급이 오를수록 고리·외곽 빛·흔들림이 늘어난다', () {
      final common = fx.of(Rarity.common);
      expect(common.color, isNull);
      expect(common.aura, 0);
      expect(common.glow, 0);
      expect(common.ring, 0);
      expect(common.shake, 1.0);

      final rare = fx.of(Rarity.rare);
      expect(rare.aura, 1, reason: '푸른 고리');
      expect(rare.glow, 0, reason: '희귀는 외곽 빛 없음');
      expect(rare.trail, 'dots');
      expect(rare.ring, 1);
      expect(rare.shake, 1.0);

      final hero = fx.of(Rarity.hero);
      expect(hero.motes, greaterThan(0), reason: '보라 고리 + 별빛');
      expect(hero.glow, greaterThan(0));
      expect(hero.trail, 'ribbon');
      expect(hero.shards, greaterThan(0));
      expect(hero.shake, 1.08);

      final legend = fx.of(Rarity.legend);
      expect(legend.aura, 2, reason: '금 고리 2겹 + 빛기둥');
      expect(legend.glow, greaterThan(hero.glow));
      expect(legend.trail, 'ribbon+stars');
      expect(legend.ring, 2);
      expect(legend.shake, 1.15);
    });

    test('같은 해적을 등급만 바꾸면 조준 점선 색이 달라진다', () {
      final colors = {
        for (final r in [
          Rarity.common,
          Rarity.rare,
          Rarity.hero,
          Rarity.legend,
        ])
          fx.of(r).aim,
      };
      expect(colors, hasLength(4));
      expect(fx.of(Rarity.common).aim, const Color(0xFFFFF2DC));
    });

    test('신화 값이 데이터에 없으면 전설 연출을 쓰고, 있으면 신화 값을 쓴다', () {
      const legendOnly = RarityFx({'legend': RarityTier(ring: 2)});
      expect(legendOnly.of(Rarity.myth).ring, 2);
      expect(legendOnly.of(Rarity.hero).ring, 0, reason: '아래 등급이 없으면 일반');

      final withMythic = RarityFx.fromJson({
        'tiers': {
          'legend': {'ring': 2, 'trail': 'ribbon+stars'},
          'mythic': {
            'color': '#7af0ff',
            'hi': '#ff9ae8',
            'aura': 3,
            'trail': 'prism',
            'ring': 3,
            'shake': 1.2,
          },
        },
      });
      final myth = withMythic.of(Rarity.myth);
      expect(myth.trail, 'prism');
      expect(myth.aura, 3);
      expect(myth.color, const Color(0xFF7AF0FF));
      expect(myth.shake, 1.2);
    });

    test('rarityFx 가 없는 데이터는 모든 등급이 일반 연출이다', () {
      expect(RarityFx.fromJson(null).of(Rarity.legend).aura, 0);
    });

    test('모든 등급의 발밑 고리·반짝·꼬리를 오류 없이 그린다', () {
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      const mythic = RarityTier(
        color: Color(0xFF7AF0FF),
        hi: Color(0xFFFF9AE8),
        aura: 3,
        motes: 7,
        glint: 3,
        trail: 'prism',
        glow: 8,
      );
      final pts = [for (var i = 0; i < 13; i++) Offset(i * 8, -i * 3)];
      for (final tier in [...Rarity.values.map(fx.of), mythic]) {
        RarityPainter.glow(canvas, Offset.zero, tier, 1);
        RarityPainter.aura(canvas, Offset.zero, tier, 1.3);
        RarityPainter.glint(canvas, Offset.zero, tier, .2);
        TrailPainter.tier(canvas, pts, tier, 1.3);
        TrailPainter.tier(canvas, pts, tier, 1.3, water: true);
      }
      for (final trail in const [
        'smoke',
        'fire',
        'lava',
        'spark',
        'bubble',
        'water',
        'wind',
        'none',
      ]) {
        TrailPainter.base(canvas, pts, trail, 1.3);
      }
      recorder.endRecording().dispose();
    });
  });

  group('조준 표시 (설계서 §10.4)', () {
    test('궤적 점선은 멀어질수록 흐려진다', () {
      final alphas = [for (var i = 0; i <= 10; i++) AimPainter.dotAlpha(i, 10)];
      expect(alphas.first, 1);
      for (var i = 1; i < alphas.length; i++) {
        expect(alphas[i], lessThan(alphas[i - 1]));
      }
      expect(alphas.last, greaterThan(0), reason: '끝 점도 보인다');
    });

    test('고무줄은 조준 방향의 반대로, 세게 당길수록 길게 늘어난다', () {
      const from = Offset(100, -50);
      // 오른쪽을 보는 배가 45° 위로 조준: 방향은 오른쪽 위.
      final dir = AimPainter.direction(1, 45000);
      expect(dir.dx, greaterThan(0));
      expect(dir.dy, lessThan(0));
      // 왼쪽을 보는 배는 좌우가 뒤집힌다.
      expect(AimPainter.direction(-1, 45000).dx, lessThan(0));

      final weak = AimPainter.pulled(from, 1, 45000, .2);
      final strong = AimPainter.pulled(from, 1, 45000, 1);
      expect(strong.dx, lessThan(weak.dx), reason: '뒤(왼쪽)로 더 당긴다');
      expect(strong.dy, greaterThan(weak.dy), reason: '아래로 더 당긴다');
      expect((strong - from).distance, greaterThan((weak - from).distance));
    });

    test('고무줄·각도 호·힘 링을 양쪽 진영 모두 오류 없이 그린다', () {
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      for (final facing in const [1, -1]) {
        AimPainter.sling(
          canvas,
          const Offset(10, -40),
          facing: facing,
          angleMdeg: 30000,
          stretch: .7,
          power: .7,
          color: fx.of(Rarity.hero).aim,
        );
      }
      AimPainter.trajectory(
        canvas,
        [for (var i = 0; i < 8; i++) Offset(i * 10, -i * 6)],
        fx.of(Rarity.rare).aim,
      );
      recorder.endRecording().dispose();
    });
  });
}
