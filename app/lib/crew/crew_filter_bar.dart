import 'package:flutter/material.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/app/app_theme.dart';
import 'package:pirate_busters/crew/crew_filter.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';
import 'package:pirate_busters/ui/hud/ammo_label.dart';
import 'package:pirate_busters/ui/kit/kit_motion.dart';
import 'package:pirate_busters/ui/kit/pb_button.dart';
import 'package:pirate_busters/ui/labels.dart';

/// 펼친 필터 묶음.
enum CrewFilterGroup { rarity, family, ammo }

/// 선원 목록 위 필터 막대 (설계서 §13.7, A63): 등급·계열·탄종 버튼, 초기화, 개수.
/// 버튼을 누르면 그 묶음의 칩이 아래로 펼쳐진다. 칩은 목록에 있는 값만 보인다.
class CrewFilterBar extends StatefulWidget {
  const CrewFilterBar({
    required this.filter,
    required this.onChanged,
    required this.shown,
    required this.total,
    required this.specs,
    super.key,
  });

  final CrewFilter filter;
  final ValueChanged<CrewFilter> onChanged;
  final int shown;
  final int total;

  /// 목록에 오를 수 있는 해적(필터 전). 칩 후보를 여기서 고른다.
  final List<PirateSpec> specs;

  @override
  State<CrewFilterBar> createState() => _CrewFilterBarState();
}

class _CrewFilterBarState extends State<CrewFilterBar> {
  CrewFilterGroup? _open;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final f = widget.filter;
    Widget group(CrewFilterGroup g, String label, int count) => _GroupButton(
      key: ValueKey('crew-filter-${g.name}'),
      label: count == 0 ? label : '$label $count',
      active: count > 0,
      open: _open == g,
      onTap: () => setState(() => _open = _open == g ? null : g),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 좁은 화면에서는 초기화·개수가 다음 줄로 내려간다.
        Wrap(
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            group(
              CrewFilterGroup.rarity,
              l10n.crewFilterRarity,
              f.rarities.length,
            ),
            group(
              CrewFilterGroup.family,
              l10n.crewFilterFamily,
              f.families.length,
            ),
            group(CrewFilterGroup.ammo, l10n.crewFilterAmmo, f.ammos.length),
            if (!f.isEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: PbButton.small(
                  key: const ValueKey('crew-filter-reset'),
                  label: l10n.crewFilterReset,
                  onPressed: () => widget.onChanged(const CrewFilter()),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                l10n.crewFilterCount(widget.shown, widget.total),
                style: const TextStyle(color: AppColors.mute, fontSize: 13),
              ),
            ),
          ],
        ),
        if (_open case final g?)
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 2),
            child: Wrap(spacing: 4, runSpacing: 4, children: _chips(l10n, g)),
          ),
      ],
    );
  }

  List<Widget> _chips(AppLocalizations l10n, CrewFilterGroup g) {
    final f = widget.filter;
    final specs = widget.specs;
    Widget chip(
      String key,
      String label,
      CrewFilter next, {
      required bool on,
      String? icon,
    }) => _Chip(
      key: ValueKey('crew-chip-$key'),
      label: label,
      icon: icon,
      on: on,
      onTap: () => widget.onChanged(next),
    );
    return switch (g) {
      CrewFilterGroup.rarity => [
        for (final r in Rarity.values)
          if (specs.any((s) => s.rarity == r))
            chip(
              r.name,
              Labels.rarity(l10n, r),
              f.toggleRarity(r),
              on: f.rarities.contains(r),
            ),
      ],
      CrewFilterGroup.family => [
        for (final v in Family.values)
          if (specs.any((s) => s.family == v))
            chip(
              v.name,
              Labels.family(l10n, v),
              f.toggleFamily(v),
              on: f.families.contains(v),
            ),
      ],
      CrewFilterGroup.ammo => [
        for (final a in AmmoType.values)
          if (specs.any((s) => s.ammo == a))
            chip(
              a.name,
              Labels.ammoKind(l10n, a),
              f.toggleAmmo(a),
              on: f.ammos.contains(a),
              icon: ammoIconPath(a),
            ),
      ],
    };
  }
}

class _GroupButton extends StatelessWidget {
  const _GroupButton({
    required this.label,
    required this.active,
    required this.open,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool active;
  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 4),
    child: Pressable(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 36),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: active ? const Color(0x33FFC24A) : const Color(0xFF1E2129),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active || open ? AppColors.gold : const Color(0x55FFFFFF),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: const TextStyle(color: AppColors.text)),
            const SizedBox(width: 4),
            CustomPaint(
              size: const Size(10, 6),
              painter: _Caret(up: open),
            ),
          ],
        ),
      ),
    ),
  );
}

/// 필터 칩 하나: 켜지면 금빛.
class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.on,
    required this.onTap,
    this.icon,
    super.key,
  });

  final String label;
  final bool on;
  final VoidCallback onTap;
  final String? icon;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: on,
    button: true,
    child: Pressable(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 34),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: on ? const Color(0x55FFC24A) : const Color(0xFF262A33),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: on ? const Color(0xFFFFC24A) : const Color(0x44FFFFFF),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon case final path?) ...[
              Image.asset(path, width: 16, height: 16),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: on ? AppColors.text : AppColors.mute,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// 펼침 표시 삼각형 (메타 화면은 Material 아이콘을 쓰지 않는다).
class _Caret extends CustomPainter {
  const _Caret({required this.up});

  final bool up;

  @override
  void paint(Canvas canvas, Size size) {
    final path = up
        ? (Path()
            ..moveTo(0, size.height)
            ..lineTo(size.width / 2, 0)
            ..lineTo(size.width, size.height))
        : (Path()
            ..moveTo(0, 0)
            ..lineTo(size.width / 2, size.height)
            ..lineTo(size.width, 0));
    canvas.drawPath(path..close(), Paint()..color = AppColors.mute);
  }

  @override
  bool shouldRepaint(_Caret old) => old.up != up;
}
