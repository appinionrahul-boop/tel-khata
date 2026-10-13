import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/formatters.dart';
import '../../services/oil_reminder.dart';
import '../screens/expense_form_screen.dart';
import '../theme/app_theme.dart';
import 'common.dart';
import 'glass.dart';
import 'list_widgets.dart';

/// Dashboard card with a ring gauge of oil life left until the next change.
/// Turns amber when due soon and red when overdue.
class OilReminderCard extends StatelessWidget {
  static const double _ringSize = 128;
  static const double _highlightBorder = 2;

  final OilReminder? reminder;
  final Formatters fmt;

  const OilReminderCard({super.key, required this.reminder, required this.fmt});

  static Color colorFor(OilStatus status) => switch (status) {
        OilStatus.ok => AppColors.primary,
        OilStatus.dueSoon => AppColors.amber,
        OilStatus.overdue => AppColors.error,
      };

  void _logOilChange(BuildContext context) => Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => const ExpenseFormScreen(initialCategory: ExpenseCategory.engineOil)));

  @override
  Widget build(BuildContext context) {
    final r = reminder;
    return r == null ? _emptyCard(context) : _reminderCard(context, r);
  }

  Widget _emptyCard(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      onTap: () => _logOilChange(context),
      child: Row(
        children: [
          const GradientIconBadge(icon: Icons.oil_barrel, gradient: AppGradients.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Track engine oil',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                Text('Log your last oil change to get reminders here.',
                    style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
              ],
            ),
          ),
          const Icon(Icons.add_circle, color: AppColors.primary),
        ],
      ),
    );
  }

  Widget _reminderCard(BuildContext context, OilReminder r) {
    final theme = Theme.of(context);
    final status = r.status;
    final color = colorFor(status);
    final highlighted = status != OilStatus.ok;
    final last = r.lastChange;
    final overdue = status == OilStatus.overdue;

    final pill = switch (status) {
      OilStatus.ok => 'Good',
      OilStatus.dueSoon => 'Change soon',
      OilStatus.overdue => 'Change now',
    };
    final oilName = [last.oilBrand, last.oilGrade].whereType<String>().join(' ');
    final muted = theme.textTheme.bodySmall?.copyWith(color: AppColors.textMuted);

    return GlassCard(
      onTap: () => _logOilChange(context),
      borderColor: highlighted ? color : null,
      borderWidth: highlighted ? _highlightBorder : 1.5,
      child: Row(
        children: [
          RingProgress(
            size: _ringSize,
            fraction: 1 - r.usedFraction,
            color: color,
            center: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  child: Text(fmt.distance(r.remainingKm.abs()),
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800, color: highlighted ? color : null)),
                ),
                Text(overdue ? 'overdue' : 'left', style: muted),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ENGINE OIL',
                    style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.textMuted, letterSpacing: 1.5, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                NeonPill(text: pill, color: color),
                if (oilName.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(oilName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                ],
                const SizedBox(height: 4),
                Text('Changed at ${fmt.distance(last.odometerKm!)}', style: muted),
                Text('Next at ${fmt.distance(r.dueAtKm)}', style: muted),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
