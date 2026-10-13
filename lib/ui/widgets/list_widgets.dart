import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/app_theme.dart';
import 'common.dart';
import 'glass.dart';

sealed class ListRow<T> {
  const ListRow();
}

class MonthHeaderRow<T> extends ListRow<T> {
  final DateTime month;
  final double total;
  final int count;

  const MonthHeaderRow(this.month, this.total, this.count);
}

class ItemRow<T> extends ListRow<T> {
  final T item;

  const ItemRow(this.item);
}

/// Flattens [items] (already newest first) into month headers followed by
/// their items, so one lazy ListView.builder can render the whole list.
List<ListRow<T>> groupByMonth<T>(
  List<T> items,
  DateTime Function(T) dateOf,
  double Function(T) amountOf,
) {
  final rows = <ListRow<T>>[];
  var i = 0;
  while (i < items.length) {
    final d = dateOf(items[i]);
    final month = DateTime(d.year, d.month);
    var j = i;
    var total = 0.0;
    while (j < items.length) {
      final dj = dateOf(items[j]);
      if (dj.year != month.year || dj.month != month.month) break;
      total += amountOf(items[j]);
      j++;
    }
    rows.add(MonthHeaderRow(month, total, j - i));
    for (var k = i; k < j; k++) {
      rows.add(ItemRow(items[k]));
    }
    i = j;
  }
  return rows;
}

class SummaryMetric {
  final String label;
  final String value;

  const SummaryMetric(this.label, this.value);
}

/// Glass header with the list's key totals; the headline counts up.
class ListSummaryHeader extends StatelessWidget {
  final String title;
  final double headline;
  final String Function(double) format;
  final List<SummaryMetric> metrics;
  final Gradient gradient;

  const ListSummaryHeader({
    super.key,
    required this.title,
    required this.headline,
    required this.format,
    required this.metrics,
    this.gradient = AppGradients.primary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      radius: AppRadius.xl,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Column(
        children: [
          Text(title.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.textMuted, letterSpacing: 1.5, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          ShaderMask(
            shaderCallback: (bounds) => gradient.createShader(bounds),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: CountUpText(
                value: headline,
                format: format,
                style: theme.textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.w800, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              for (var i = 0; i < metrics.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.glassStrong,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Column(
                      children: [
                        Text(metrics[i].label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall
                                ?.copyWith(color: AppColors.textMuted)),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(metrics[i].value,
                              style: theme.textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class MonthHeader extends StatelessWidget {
  static final DateFormat _format = DateFormat('MMMM yyyy');
  static const double _dot = 8;

  final DateTime month;
  final String total;
  final int count;

  const MonthHeader({super.key, required this.month, required this.total, required this.count});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 24, 4, 8),
      child: Row(
        children: [
          Container(
            width: _dot,
            height: _dot,
            decoration: const BoxDecoration(gradient: AppGradients.primary, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(_format.format(month),
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(width: 8),
          NeonPill(text: '$count', color: AppColors.primaryText),
          const SizedBox(width: 12),
          Expanded(child: Container(height: 1, color: AppColors.divider)),
          const SizedBox(width: 12),
          Text(total,
              style: theme.textTheme.labelLarge
                  ?.copyWith(color: AppColors.primaryText, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

/// Small rounded label, tinted with [color].
class NeonPill extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;

  const NeonPill({super.key, required this.text, this.color = AppColors.textMuted, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.tint(color),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(text,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

/// Glass card for one list entry, with swipe-to-delete.
class EntryCard extends StatelessWidget {
  final Key dismissKey;
  final Widget leading;
  final Widget title;
  final List<Widget> pills;
  final Widget? trailing;
  final VoidCallback onTap;
  final Future<bool?> Function() confirmDismiss;
  final VoidCallback onDismissed;

  const EntryCard({
    super.key,
    required this.dismissKey,
    required this.leading,
    required this.title,
    required this.pills,
    this.trailing,
    required this.onTap,
    required this.confirmDismiss,
    required this.onDismissed,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.lg - 4);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Dismissible(
        key: dismissKey,
        direction: DismissDirection.endToStart,
        background: ClipRRect(borderRadius: radius, child: const DeleteBackground()),
        confirmDismiss: (_) => confirmDismiss(),
        onDismissed: (_) => onDismissed(),
        // Shadows are skipped on rows to keep long lists cheap to scroll.
        child: GlassCard(
          radius: AppRadius.lg - 4,
          shadow: false,
          padding: const EdgeInsets.all(12),
          onTap: onTap,
          child: Row(
            children: [
              leading,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    title,
                    const SizedBox(height: 8),
                    Wrap(spacing: 6, runSpacing: 6, children: pills),
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 8), trailing!],
            ],
          ),
        ),
      ),
    );
  }
}

/// Right-aligned bold value with a small caption underneath.
class TrailingValue extends StatelessWidget {
  final String value;
  final String? caption;
  final Color color;
  final IconData? icon;

  const TrailingValue({
    super.key,
    required this.value,
    this.caption,
    this.color = AppColors.primaryText,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
            ],
            Text(value,
                style: theme.textTheme.titleMedium?.copyWith(color: color, fontWeight: FontWeight.w800)),
          ],
        ),
        if (caption != null)
          Text(caption!, style: theme.textTheme.labelSmall?.copyWith(color: AppColors.textMuted)),
      ],
    );
  }
}
