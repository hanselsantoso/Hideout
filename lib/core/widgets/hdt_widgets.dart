// ============================================================
// HIDEOUT SHARED WIDGETS
// Small reusable widgets used across the app.
// Import: import 'package:your_app/core/widgets/hdt_widgets.dart';
// ============================================================

import 'package:flutter/material.dart';
import '../theme/hideout_tokens.dart';

// ════════════════════════════════════════════════════════════
// HDTPagination
// ════════════════════════════════════════════════════════════
class HDTPagination extends StatelessWidget {
  final int total;
  final int page; // 0-based
  final int perPage;
  final String label;
  final void Function(int) onPage;

  const HDTPagination({
    super.key,
    required this.total,
    required this.page,
    required this.perPage,
    required this.onPage,
    this.label = 'item',
  });

  @override
  Widget build(BuildContext context) {
    final totalPages = (total / perPage).ceil();
    if (totalPages <= 1) return const SizedBox.shrink();

    final from = page * perPage + 1;
    final to = ((page + 1) * perPage).clamp(0, total);

    // Build page number list with ellipsis
    final pages = <Object>[];
    for (int i = 0; i < totalPages; i++) {
      if (i == 0 || i == totalPages - 1 || (i - page).abs() <= 1) {
        pages.add(i);
      } else if (pages.isNotEmpty && pages.last != '…') {
        pages.add('…');
      }
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$from-$to of $total $label',
          style: HDTText.mono(size: 11, color: HDTColors.text3),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _PageBtn(
                icon: Icons.chevron_left,
                enabled: page > 0,
                onTap: () => onPage(page - 1),
              ),
              ...pages.map((p) {
                if (p == '…') {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text('…',
                        style: HDTText.mono(size: 11, color: HDTColors.text3)),
                  );
                }
                final idx = p as int;
                final active = idx == page;
                return _PageBtn(
                  label: '${idx + 1}',
                  active: active,
                  onTap: () => onPage(idx),
                );
              }),
              _PageBtn(
                icon: Icons.chevron_right,
                enabled: page < totalPages - 1,
                onTap: () => onPage(page + 1),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PageBtn extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final bool active;
  final bool enabled;
  final VoidCallback onTap;

  const _PageBtn({
    this.label,
    this.icon,
    this.active = false,
    this.enabled = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 30,
        height: 30,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: active ? HDTColors.accent : Colors.transparent,
          borderRadius: HDTR.md,
          border: Border.all(color: active ? HDTColors.accent : HDTColors.s2),
        ),
        child: Center(
          child: icon != null
              ? Icon(icon,
                  size: 15, color: enabled ? HDTColors.text2 : HDTColors.text3)
              : Text(
                  label!,
                  style: HDTText.mono(
                      size: 11, color: active ? Colors.white : HDTColors.text2),
                ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// HDTResultBadge  — WIN / LOSS / DRAW
// ════════════════════════════════════════════════════════════
class HDTResultBadge extends StatelessWidget {
  final String result;
  final double height;

  const HDTResultBadge(this.result, {super.key, this.height = 22});

  @override
  Widget build(BuildContext context) {
    final isWin = result.toUpperCase() == 'WIN';
    final isDraw = result.toUpperCase() == 'DRAW';
    final color = isDraw
        ? HDTColors.text3
        : isWin
            ? HDTColors.success
            : HDTColors.danger;

    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: HDTR.sm,
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Center(
        child: Text(
          result.toUpperCase(),
          style: HDTText.overline(size: 9, color: color),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// HDTEloChip  — +24 / -8
// ════════════════════════════════════════════════════════════
class HDTEloChip extends StatelessWidget {
  final int change;
  final double size;

  const HDTEloChip(this.change, {super.key, this.size = 12});

  @override
  Widget build(BuildContext context) {
    final color = change > 0
        ? HDTColors.success
        : change < 0
            ? HDTColors.danger
            : HDTColors.text3;
    final text = change > 0 ? '+$change' : '$change';
    return Text(text, style: HDTText.mono(size: size, color: color));
  }
}

// ════════════════════════════════════════════════════════════
// HDTDeckClassBadge  — RUSHER / STAMINA / DEFENDER / BALANCE
// ════════════════════════════════════════════════════════════
class HDTDeckClassBadge extends StatelessWidget {
  final String deckClass;

  const HDTDeckClassBadge(this.deckClass, {super.key});

  @override
  Widget build(BuildContext context) {
    final color = HDTColors.fromDeckClass(deckClass);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: HDTR.sm,
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        deckClass.toUpperCase(),
        style: HDTText.overline(size: 8, color: color),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// HDTGameBadge  — BURST / OVER / SPIN / LOSS
// ════════════════════════════════════════════════════════════
class HDTGameBadge extends StatelessWidget {
  final String type;

  const HDTGameBadge(this.type, {super.key});

  @override
  Widget build(BuildContext context) {
    final color = HDTColors.fromFinish(type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: HDTR.sm,
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(type.toUpperCase(),
          style: HDTText.overline(size: 7, color: color)),
    );
  }
}

// ════════════════════════════════════════════════════════════
// HDTStatCard  — Stat summary card
// ════════════════════════════════════════════════════════════
class HDTStatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final String? sub;

  const HDTStatCard({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(HDTSpace.lg),
      decoration: hdtCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: HDTText.overline(size: 9)),
          const SizedBox(height: 6),
          Text(
            value,
            style:
                HDTText.display(size: 26, color: valueColor ?? HDTColors.text),
          ),
          if (sub != null) ...[
            const SizedBox(height: 2),
            Text(sub!, style: HDTText.mono(size: 10, color: HDTColors.text3)),
          ],
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// HDTOverlineLabel  — Section label kecil
// ════════════════════════════════════════════════════════════
class HDTOverlineLabel extends StatelessWidget {
  final String text;
  final Color? color;
  final double size;
  final EdgeInsets padding;

  const HDTOverlineLabel(
    this.text, {
    super.key,
    this.color,
    this.size = 9,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Text(
        text.toUpperCase(),
        style: HDTText.overline(size: size, color: color),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// HDTFilterChip  — Single toggle filter chip
// ════════════════════════════════════════════════════════════
class HDTFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget? leading;

  const HDTFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? HDTColors.accentDim : Colors.transparent,
          borderRadius: HDTR.md,
          border: Border.all(
            color: selected ? HDTColors.accent : HDTColors.s2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 4)],
            Text(
              label.toUpperCase(),
              style: HDTText.overline(
                size: 9,
                color: selected ? HDTColors.accentHover : HDTColors.text3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// HDTSearchField  — Search input box
// ════════════════════════════════════════════════════════════
class HDTSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String placeholder;
  final ValueChanged<String>? onChanged;

  const HDTSearchField({
    super.key,
    required this.controller,
    this.placeholder = 'Search...',
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: HDTText.body(size: 13),
      decoration: InputDecoration(
        hintText: placeholder,
        prefixIcon: const Icon(Icons.search, size: 16, color: HDTColors.text3),
        prefixIconConstraints:
            const BoxConstraints(minWidth: 36, minHeight: 36),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// HDTStatusBadge  — LIVE / UPCOMING / COMPLETED / etc.
// ════════════════════════════════════════════════════════════
class HDTStatusBadge extends StatelessWidget {
  final String status;
  final bool pulseDot;

  const HDTStatusBadge(this.status, {super.key, this.pulseDot = false});

  static Color _color(String s) {
    switch (s.toUpperCase()) {
      case 'LIVE':
        return HDTColors.accent;
      case 'REGISTRATION OPEN':
        return HDTColors.success;
      case 'UPCOMING':
        return HDTColors.info;
      case 'COMPLETED':
        return HDTColors.text3;
      default:
        return HDTColors.text3;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: HDTR.sm,
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (pulseDot || status.toUpperCase() == 'LIVE') ...[
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(right: 5),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ],
          Text(status.toUpperCase(),
              style: HDTText.overline(size: 8, color: color)),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// HDTTierBadge  — PREMIER / STANDARD / CASUAL
// ════════════════════════════════════════════════════════════
class HDTTierBadge extends StatelessWidget {
  final String tier;

  const HDTTierBadge(this.tier, {super.key});

  static Color _color(String t) {
    switch (t.toUpperCase()) {
      case 'PREMIER':
        return HDTColors.warning;
      case 'STANDARD':
        return HDTColors.info;
      case 'CASUAL':
        return HDTColors.text3;
      default:
        return HDTColors.text3;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color(tier);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: HDTR.sm,
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(tier.toUpperCase(),
          style: HDTText.overline(size: 8, color: color)),
    );
  }
}

// ════════════════════════════════════════════════════════════
// HDTSectionHeader  — Section title + optional action
// ════════════════════════════════════════════════════════════
class HDTSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;
  final EdgeInsets padding;

  const HDTSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: HDTText.display(size: 28)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!,
                      style: HDTText.mono(size: 11, color: HDTColors.text3)),
                ],
              ],
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// HDTEmptyState  — Empty list placeholder
// ════════════════════════════════════════════════════════════
class HDTEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const HDTEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(HDTSpace.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 36, color: HDTColors.text3),
            const SizedBox(height: HDTSpace.lg),
            Text(title,
                style: HDTText.display(size: 18, color: HDTColors.text3)),
            if (subtitle != null) ...[
              const SizedBox(height: HDTSpace.sm),
              Text(
                subtitle!,
                style: HDTText.body(size: 13, color: HDTColors.text3),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: HDTSpace.xl),
              action!
            ],
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// HDTCardContainer  — Wrapper container berstandar HIDEOUT
// ════════════════════════════════════════════════════════════
class HDTCardContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? bg;
  final Color? borderColor;
  final BorderRadius? radius;
  final VoidCallback? onTap;

  const HDTCardContainer({
    super.key,
    required this.child,
    this.padding,
    this.bg,
    this.borderColor,
    this.radius,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final container = Container(
      padding: padding,
      decoration: hdtCard(bg: bg, borderColor: borderColor, radius: radius),
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        borderRadius: radius ?? HDTR.lg,
        onTap: onTap,
        child: container,
      );
    }
    return container;
  }
}

// ════════════════════════════════════════════════════════════
// HDTDateRangeBar - Date range filter with presets.
// ════════════════════════════════════════════════════════════
enum HDTDatePreset {
  all,
  sevenDays,
  thirtyDays,
  threeMonths,
  sixMonths,
  thisYear
}

extension HDTDatePresetLabel on HDTDatePreset {
  String get label {
    switch (this) {
      case HDTDatePreset.all:
        return 'SEMUA';
      case HDTDatePreset.sevenDays:
        return '7 HARI';
      case HDTDatePreset.thirtyDays:
        return '30 HARI';
      case HDTDatePreset.threeMonths:
        return '3 BULAN';
      case HDTDatePreset.sixMonths:
        return '6 BULAN';
      case HDTDatePreset.thisYear:
        return 'TAHUN INI';
    }
  }

  DateTimeRange? get range {
    final now = DateTime.now();
    switch (this) {
      case HDTDatePreset.all:
        return null;
      case HDTDatePreset.sevenDays:
        return DateTimeRange(
            start: now.subtract(const Duration(days: 7)), end: now);
      case HDTDatePreset.thirtyDays:
        return DateTimeRange(
            start: now.subtract(const Duration(days: 30)), end: now);
      case HDTDatePreset.threeMonths:
        return DateTimeRange(
            start: now.subtract(const Duration(days: 90)), end: now);
      case HDTDatePreset.sixMonths:
        return DateTimeRange(
            start: now.subtract(const Duration(days: 180)), end: now);
      case HDTDatePreset.thisYear:
        return DateTimeRange(start: DateTime(now.year), end: now);
    }
  }
}

class HDTDateRangeBar extends StatelessWidget {
  final HDTDatePreset selectedPreset;
  final DateTimeRange? customRange;
  final ValueChanged<HDTDatePreset> onPreset;
  final ValueChanged<DateTimeRange?> onCustomRange;

  const HDTDateRangeBar({
    super.key,
    required this.selectedPreset,
    this.customRange,
    required this.onPreset,
    required this.onCustomRange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(HDTSpace.md),
      decoration: hdtCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Presets
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        size: 13, color: HDTColors.text3),
                    const SizedBox(width: 6),
                    Text('RENTANG:', style: HDTText.overline(size: 9)),
                    const SizedBox(width: 8),
                  ],
                ),
                ...HDTDatePreset.values.map((p) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: HDTFilterChip(
                        label: p.label,
                        selected: selectedPreset == p,
                        onTap: () => onPreset(p),
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Custom range picker
          InkWell(
            borderRadius: HDTR.md,
            onTap: () async {
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2024),
                lastDate: DateTime.now(),
                initialDateRange: customRange ?? selectedPreset.range,
                builder: (ctx, child) => Theme(
                  data: Theme.of(ctx),
                  child: child!,
                ),
              );
              if (picked != null) onCustomRange(picked);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: HDTColors.bg,
                borderRadius: HDTR.md,
                border: Border.all(
                  color: customRange != null ? HDTColors.accent : HDTColors.s2,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.date_range, size: 14, color: HDTColors.text3),
                  const SizedBox(width: 8),
                  Text(
                    customRange != null
                        ? '${_fmtDate(customRange!.start)}  →  ${_fmtDate(customRange!.end)}'
                        : 'Choose a custom date range...',
                    style: HDTText.mono(
                      size: 11,
                      color: customRange != null
                          ? HDTColors.text
                          : HDTColors.text3,
                    ),
                  ),
                  const Spacer(),
                  if (customRange != null)
                    GestureDetector(
                      onTap: () => onCustomRange(null),
                      child:
                          const Icon(Icons.close, size: 14, color: HDTColors.text3),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.day} ${_months[d.month - 1]} ${d.year.toString().substring(2)}';

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des'
  ];
}

// ════════════════════════════════════════════════════════════
// HDTResultFormStrip - Green/red form strip boxes.
// ════════════════════════════════════════════════════════════
class HDTResultFormStrip extends StatelessWidget {
  final List<String> results; // 'WIN' | 'LOSS' | 'DRAW'
  final double size;

  const HDTResultFormStrip({
    super.key,
    required this.results,
    this.size = 18,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: results.map((r) {
        final color = HDTColors.fromResult(r);
        return Tooltip(
          message: r,
          child: Container(
            width: size,
            height: size,
            margin: const EdgeInsets.only(right: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: HDTR.sm,
            ),
          ),
        );
      }).toList(),
    );
  }
}
