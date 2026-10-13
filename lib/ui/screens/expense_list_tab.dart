import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/formatters.dart';
import '../../data/models/expense_entry.dart';
import '../../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/glass.dart';
import '../widgets/list_widgets.dart';
import 'expense_form_screen.dart';

class ExpenseListTab extends StatelessWidget {
  const ExpenseListTab({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final entries = state.expenses;
    final fmt = state.fmt;

    if (entries.isEmpty) {
      return const EmptyState(
        icon: Icons.receipt_long,
        title: 'No expenses yet',
        message: 'Log services, repairs, insurance, tolls and other vehicle costs.',
      );
    }

    final rows = groupByMonth<ExpenseEntry>(entries, (e) => e.date, (e) => e.cost);
    final totalSpent = state.stats.totalExpenseCost;

    return RefreshIndicator(
      onRefresh: state.syncNow,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, kNavBarClearance),
        itemCount: rows.length + 1,
        itemBuilder: (context, i) {
          if (i == 0) {
            return FadeSlideIn(
              child: ListSummaryHeader(
                title: 'Total expenses',
                headline: totalSpent,
                format: fmt.money,
                gradient: AppGradients.accent,
                metrics: [
                  SummaryMetric('Entries', '${entries.length}'),
                  SummaryMetric('Average', fmt.moneyShort(totalSpent / entries.length)),
                  SummaryMetric('Top category', _topCategory(entries).displayName),
                ],
              ),
            );
          }
          final row = switch (rows[i - 1]) {
            MonthHeaderRow(:final month, :final total, :final count) =>
              MonthHeader(month: month, total: fmt.moneyShort(total), count: count),
            ItemRow(:final item) => _ExpenseCard(entry: item),
          };
          return FadeSlideIn(index: i, child: row);
        },
      ),
    );
  }

  static ExpenseCategory _topCategory(List<ExpenseEntry> entries) {
    final totals = <ExpenseCategory, double>{};
    for (final e in entries) {
      totals[e.category] = (totals[e.category] ?? 0) + e.cost;
    }
    return totals.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }
}

class _ExpenseCard extends StatelessWidget {
  final ExpenseEntry entry;

  const _ExpenseCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final fmt = state.fmt;
    final e = entry;
    final odometer = e.odometerKm;
    final interval = e.oilIntervalKm;
    final oilName = [e.oilBrand, e.oilGrade].whereType<String>().join(' ');

    return EntryCard(
      dismissKey: ValueKey(e.id),
      leading: GradientIconBadge(icon: e.category.icon, gradient: AppGradients.accent),
      title: Text(
        e.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
      pills: [
        NeonPill(text: e.category.displayName.toUpperCase(), color: AppColors.secondary),
        NeonPill(icon: Icons.event, text: Formatters.date.format(e.date)),
        if (odometer != null) NeonPill(icon: Icons.speed, text: fmt.distance(odometer)),
        if (oilName.isNotEmpty) NeonPill(icon: Icons.local_offer, text: oilName),
        if (interval != null)
          NeonPill(icon: Icons.av_timer, text: 'Runs ${fmt.distance(interval)}', color: AppColors.primaryText),
      ],
      trailing: TrailingValue(value: fmt.moneyShort(e.cost), color: AppColors.secondary),
      onTap: () => Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => ExpenseFormScreen(entry: e))),
      confirmDismiss: () => confirmDelete(context, 'expense'),
      onDismissed: () => state.deleteExpense(e),
    );
  }
}
