import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../data/models/fuel_entry.dart';
import '../../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/glass.dart';
import '../widgets/list_widgets.dart';
import 'fuel_form_screen.dart';

class FuelListTab extends StatelessWidget {
  const FuelListTab({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final entries = state.fuelEntries;
    final fmt = state.fmt;
    final stats = state.stats;

    if (entries.isEmpty) {
      return const EmptyState(
        icon: Icons.local_gas_station,
        title: 'No fill-ups yet',
        message: 'Tap "Fill-up" to log fuel. Fill the tank completely for accurate mileage.',
      );
    }

    final rows = groupByMonth<FuelEntry>(entries, (e) => e.date, (e) => e.totalCost);
    final avgPrice = stats.totalLiters > 0 ? stats.totalFuelCost / stats.totalLiters : 0.0;

    return RefreshIndicator(
      onRefresh: state.syncNow,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, kNavBarClearance),
        itemCount: rows.length + 1,
        itemBuilder: (context, i) {
          if (i == 0) {
            return FadeSlideIn(
              child: ListSummaryHeader(
                title: 'Total fuel spend',
                headline: stats.totalFuelCost,
                format: fmt.money,
                metrics: [
                  SummaryMetric('Fill-ups', '${stats.fillUpCount}'),
                  SummaryMetric('Fuel used', fmt.volume(stats.totalLiters)),
                  SummaryMetric('Avg price', fmt.pricePerVolume(avgPrice)),
                ],
              ),
            );
          }
          final row = switch (rows[i - 1]) {
            MonthHeaderRow(:final month, :final total, :final count) =>
              MonthHeader(month: month, total: fmt.moneyShort(total), count: count),
            ItemRow(:final item) => _FuelCard(entry: item),
          };
          return FadeSlideIn(index: i, child: row);
        },
      ),
    );
  }
}

class _FuelCard extends StatelessWidget {
  final FuelEntry entry;

  const _FuelCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final fmt = state.fmt;
    final e = entry;
    final efficiency = state.stats.perEntry[e.id];
    final average = state.stats.averageKmPerLiter;
    final station = e.station;
    // Compare this fill-up's mileage with the overall average.
    final trend = efficiency == null || average == null
        ? null
        : efficiency.kmPerLiter.compareTo(average);

    return EntryCard(
      dismissKey: ValueKey(e.id),
      leading: GradientIconBadge(icon: e.fullTank ? Icons.local_gas_station : Icons.opacity),
      title: Text(
        '${fmt.volume(e.liters)}  ·  ${fmt.money(e.totalCost)}',
        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
      pills: [
        NeonPill(icon: Icons.event, text: Formatters.date.format(e.date)),
        NeonPill(icon: Icons.speed, text: fmt.distance(e.odometerKm)),
        NeonPill(icon: Icons.sell, text: fmt.pricePerVolume(e.pricePerLiter)),
        if (!e.fullTank) const NeonPill(text: 'PARTIAL', color: AppColors.amber),
        if (e.missedPrevious) const NeonPill(text: 'MISSED PREV', color: AppColors.error),
        if (station != null) NeonPill(icon: Icons.place, text: station),
      ],
      trailing: efficiency == null
          ? null
          : TrailingValue(
              value: fmt.efficiency(efficiency.kmPerLiter),
              caption: '+${fmt.distance(efficiency.distanceKm)}',
              color: switch (trend) {
                1 => AppColors.success,
                -1 => AppColors.error,
                _ => AppColors.primaryText,
              },
              icon: switch (trend) {
                1 => Icons.trending_up_rounded,
                -1 => Icons.trending_down_rounded,
                _ => null,
              },
            ),
      onTap: () => Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => FuelFormScreen(entry: e))),
      confirmDismiss: () => confirmDelete(context, 'fill-up'),
      onDismissed: () => state.deleteFuel(e),
    );
  }
}
