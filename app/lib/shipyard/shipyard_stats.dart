import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pirate_busters/app/app_theme.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';
import 'package:pirate_busters/shipyard/shipyard_model.dart';

/// 저장 조건 줄 (설계서 §13.6 “위에 건조 포인트 사용량”): 포인트 게이지와 선실·모듈·
/// 선장실 수. 어긋난 값은 빨갛고, 저장할 수 없으면 끝에 이유 한 줄을 붙인다.
class ShipyardGauges extends StatelessWidget {
  const ShipyardGauges({required this.model, super.key});

  final ShipyardModel model;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hull = model.hull;
    final s = model.stats;
    final cabins = model.cabins.length;
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          _Pill(
            text: l10n.statPoints(s.cost, hull.buildPoints),
            bad: s.cost > hull.buildPoints,
            fill: hull.buildPoints == 0 ? 0 : s.cost / hull.buildPoints,
          ),
          _Pill(
            text: l10n.statCabins(cabins, hull.cabinSlots),
            bad: cabins != hull.cabinSlots,
          ),
          _Pill(
            text: l10n.statModules(s.modulesCounted, hull.moduleLimit),
            bad: s.modulesCounted > hull.moduleLimit,
          ),
          _Pill(text: l10n.statCaptain(s.captains), bad: s.captains != 1),
          if (!model.canSave)
            Text(
              l10n.cannotSave,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.danger,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }
}

/// 참고 수치 한 줄 (설계서 §13.6 “무게·흘수선·속도·연료 탱크 수치가 바로 바뀐다”).
class ShipyardStatLine extends StatelessWidget {
  const ShipyardStatLine({required this.model, super.key});

  final ShipyardModel model;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hull = model.hull;
    final s = model.stats;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final one = NumberFormat('0.0', locale);
    final two = NumberFormat('0.00', locale);
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        [
          l10n.statWaterline(one.format(s.waterline / 1000)),
          l10n.statSpeed(one.format(hull.moveSpeed / 1000)),
          l10n.statFuelPerCell(
            two.format(hull.fuelPerCell * s.fuelPermille / 1000),
          ),
          l10n.statTank(s.tank),
        ].join('  ·  '),
        style: const TextStyle(fontSize: 12, color: AppColors.mute),
      ),
    );
  }
}

/// 수치 알약 하나. [fill] 이 있으면 아래에 채움 막대를 그린다.
class _Pill extends StatelessWidget {
  const _Pill({required this.text, this.bad = false, this.fill});

  final String text;
  final bool bad;
  final double? fill;

  @override
  Widget build(BuildContext context) {
    final color = bad ? AppColors.danger : AppColors.text;
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.fromLTRB(9, 4, 9, 4),
      decoration: BoxDecoration(
        color: const Color(0xE61B1E25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: bad ? AppColors.danger : AppColors.gold.withValues(alpha: 0.5),
          width: 1.2,
        ),
      ),
      child: IntrinsicWidth(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (fill case final f?) ...[
              const SizedBox(height: 2),
              SizedBox(
                height: 4,
                child: CustomPaint(
                  painter: _BarPainter(
                    f.clamp(0, 1),
                    bad ? AppColors.danger : AppColors.gold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 채움 막대: 어두운 바탕 위에 [fill] 만큼 [color] 로 채운다.
class _BarPainter extends CustomPainter {
  _BarPainter(this.fill, this.color);

  final double fill;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final r = Radius.circular(size.height / 2);
    canvas
      ..drawRRect(
        RRect.fromRectAndRadius(Offset.zero & size, r),
        Paint()..color = const Color(0xFF3A3F4A),
      )
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width * fill, size.height),
          r,
        ),
        Paint()..color = color,
      );
  }

  @override
  bool shouldRepaint(_BarPainter old) => old.fill != fill || old.color != color;
}
