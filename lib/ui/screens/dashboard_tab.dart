import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../services/oil_reminder.dart';
import '../../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/charts.dart';
import '../widgets/common.dart';
import '../widgets/glass.dart';
import '../widgets/list_widgets.dart';
import '../widgets/oil_reminder_card.dart';

class DashboardTab extends StatelessWidget {
  static const double _gap = 16;
  static const int _minTrendPoints = 2;

  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final s = state.stats;

    if (s.fillUpCount == 0 && state.expenses.isEmpty) {
      return const EmptyState(
        icon: Icons.local_gas_station,
        title: 'No fill-ups yet',
        message:
            'Tap + to add your first fill-up with a full tank. Mileage is calculated from the second full-tank fill-up.',
      );
    }

    final oilCard = OilReminderCard(reminder: state.oilReminder, fmt: state.fmt);
    final oilUrgent = (state.oilReminder?.status ?? OilStatus.ok) != OilStatus.ok;

    final sections = [
      _Hero(state: state),
      if (oilUrgent) oilCard,
      SectionCard(
        title: 'Mileage trend',
        trailing: NeonPill(text: state.units.efficiencyLabel, color: AppColors.primaryText),
        child: s.trend.length < _minTrendPoints
            ? const _ChartHint('Needs at least 3 full-tank fill-ups.')
            : RepaintBoundary(child: EfficiencyChart(points: s.trend, units: state.units)),
      ),
      if (!oilUrgent) oilCard,
      _SpendingBreakdown(state: state),
      _Insights(state: state),
      SectionCard(
        title: 'Monthly spend',
        trailing: NeonPill(text: state.currency.code, color: AppColors.primaryText),
        child: RepaintBoundary(child: MonthlySpendChart(months: s.monthly)),
      ),
    ];

    return RefreshIndicator(
      onRefresh: state.syncNow,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, kNavBarClearance),
        children: [
          for (var i = 0; i < sections.length; i++) ...[
            if (i > 0) const SizedBox(height: _gap),
            FadeSlideIn(index: i, child: sections[i]),
          ],
        ],
      ),
    );
  }
}

/// Big centered mileage figure with fuel and expense totals underneath.
class _Hero extends StatelessWidget {
  static const double _gap = 12;

  final AppState state;

  const _Hero({required this.state});

  @override
  Widget build(BuildContext context) {
    final s = state.stats;
    final fmt = state.fmt;

    return Column(
      children: [
        const SizedBox(height: 8),
        _MileageOrb(state: state),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: StatCard(
                label: 'Fuel cost',
                icon: Icons.south_west_rounded,
                value: CountUpText(value: s.totalFuelCost, format: fmt.moneyShort),
              ),
            ),
            const SizedBox(width: _gap),
            Expanded(
              child: StatCard(
                label: 'Other expenses',
                icon: Icons.north_east_rounded,
                gradient: AppGradients.accent,
                value: CountUpText(value: s.totalExpenseCost, format: fmt.moneyShort),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Glowing sphere with the average mileage, circled by a ring showing the
/// last fill-up against the best one.
class _MileageOrb extends StatelessWidget {
  static const double _ringSize = 232;
  static const double _ringStroke = 4;
  static const double _orbSize = 180;
  static const double _glowBlur = 40;
  static const double _shadowBlur = 24;
  static const Offset _shadowOffset = Offset(0, 12);
  static const Alignment _lightSource = Alignment(-0.3, -0.5);
  static const int _labelAlpha = 220;

  final AppState state;

  const _MileageOrb({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = state.stats;
    final fmt = state.fmt;
    final last = s.lastKmPerLiter;
    final best = s.bestKmPerLiter;
    final fraction = last != null && best != null && best > 0 ? last / best : 0.0;
    final onOrb = theme.textTheme.labelMedium
        ?.copyWith(color: AppColors.onAccent.withAlpha(_labelAlpha), letterSpacing: 1);

    return RingProgress(
      size: _ringSize,
      stroke: _ringStroke,
      fraction: fraction,
      center: Container(
        width: _orbSize,
        height: _orbSize,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            center: _lightSource,
            colors: [AppColors.primaryLight, AppColors.primary, AppColors.primaryDark],
            stops: [0, 0.55, 1],
          ),
          boxShadow: [
            BoxShadow(color: AppColors.glow, blurRadius: _glowBlur),
            BoxShadow(color: AppColors.shadow, blurRadius: _shadowBlur, offset: _shadowOffset),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('AVG MILEAGE', style: onOrb?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: CountUpText(
                value: s.averageKmPerLiter,
                format: fmt.efficiency,
                style: theme.textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.w800, color: AppColors.onAccent),
              ),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text('Last ${fmt.efficiency(last)}', style: onOrb),
            ),
          ],
        ),
      ),
    );
  }
}

/// Slider-style bars comparing fuel with the biggest expense categories.
class _SpendingBreakdown extends StatelessWidget {
  static const int _maxCategories = 4;

  final AppState state;

  const _SpendingBreakdown({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = state.fmt;

    final byCategory = <ExpenseCategory, double>{};
    for (final e in state.expenses) {
      byCategory[e.category] = (byCategory[e.category] ?? 0) + e.cost;
    }
    final top = byCategory.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final rows = [
      ('Fuel', Icons.local_gas_station, state.stats.totalFuelCost, AppGradients.primary),
      for (final c in top.take(_maxCategories))
        (c.key.displayName, c.key.icon, c.value, AppGradients.accent),
    ].where((r) => r.$3 > 0).toList();
    if (rows.isEmpty) return const SizedBox.shrink();
    final largest = rows.map((r) => r.$3).reduce(max);

    return SectionCard(
      title: 'Where the money goes',
      child: Column(
        children: [
          for (final (label, icon, amount, gradient) in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(icon, size: 16, color: gradient.colors.last),
                      const SizedBox(width: 8),
                      Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
                      Text(fmt.moneyShort(amount),
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  GlassProgressBar(fraction: amount / largest, gradient: gradient),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Insights extends StatelessWidget {
  final AppState state;

  const _Insights({required this.state});

  @override
  Widget build(BuildContext context) {
    final s = state.stats;
    final fmt = state.fmt;
    final rows = [
      (Icons.trending_up, 'Best mileage', fmt.efficiency(s.bestKmPerLiter)),
      (Icons.trending_down, 'Worst mileage', fmt.efficiency(s.worstKmPerLiter)),
      (Icons.route, 'Fuel cost per distance', fmt.costPerDistance(s.fuelCostPerKm)),
      (Icons.payments, 'Total cost per distance', fmt.costPerDistance(s.totalCostPerKm)),
      (Icons.straighten, 'Distance tracked', fmt.distance(s.totalDistanceKm)),
      (Icons.water_drop, 'Fuel used', fmt.volume(s.totalLiters)),
    ];

    return SectionCard(
      title: 'Insights',
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            _InsightRow(icon: rows[i].$1, label: rows[i].$2, value: rows[i].$3),
          ],
        ],
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  static const double _badgeSize = 36;

  final IconData icon;
  final String label;
  final String value;

  const _InsightRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          GradientIconBadge(icon: icon, size: _badgeSize),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          Text(value, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _ChartHint extends StatelessWidget {
  final String text;

  const _ChartHint(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted)),
        ),
      );
}
