import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/formatters.dart';
import '../../core/units.dart';
import '../../services/mileage_calculator.dart';
import '../theme/app_theme.dart';

const double _chartHeight = 200;
const double _leftAxisReserved = 44;
const double _bottomAxisReserved = 28;
const int _maxBottomLabels = 5;
const int _areaAlpha = 90;

final NumberFormat _compact = NumberFormat.compact();

FlGridData get _grid => FlGridData(
      drawVerticalLine: false,
      getDrawingHorizontalLine: (_) => FlLine(
        color: AppColors.divider,
        strokeWidth: 1,
        dashArray: const [4, 4],
      ),
    );

AxisTitles get _hidden => const AxisTitles(sideTitles: SideTitles(showTitles: false));

Widget _axisLabel(BuildContext context, String text) =>
    Text(text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textMuted));

class EfficiencyChart extends StatelessWidget {
  static final DateFormat _dayMonth = DateFormat('d MMM');

  final List<EfficiencyPoint> points;
  final UnitConverter units;

  const EfficiencyChart({super.key, required this.points, required this.units});

  @override
  Widget build(BuildContext context) {
    final spots = [
      for (var i = 0; i < points.length; i++)
        FlSpot(i.toDouble(), units.efficiencyFromKmPerLiter(points[i].kmPerLiter)),
    ];
    final labelEvery = max(1, (points.length / _maxBottomLabels).ceil());

    return SizedBox(
      height: _chartHeight,
      child: LineChart(
        LineChartData(
          gridData: _grid,
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: _hidden,
            rightTitles: _hidden,
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: _leftAxisReserved,
                getTitlesWidget: (value, meta) =>
                    _axisLabel(context, Formatters.trimNumber(value)),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                reservedSize: _bottomAxisReserved,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (value != i || i % labelEvery != 0 || i >= points.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: _axisLabel(context, _dayMonth.format(points[i].date)),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(getTooltipColor: (_) => AppColors.surface),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              preventCurveOverShooting: true,
              gradient: AppGradients.primary,
              barWidth: 4,
              shadow: Shadow(color: AppColors.glow, blurRadius: 12, offset: const Offset(0, 6)),
              dotData: FlDotData(
                getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                  radius: 4,
                  color: Colors.white,
                  strokeWidth: 3,
                  strokeColor: AppColors.primary,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.primary.withAlpha(_areaAlpha), AppColors.primary.withAlpha(0)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MonthlySpendChart extends StatelessWidget {
  static const double _barWidth = 20;
  static const double _legendDot = 12;

  final List<MonthlySpend> months;

  const MonthlySpendChart({super.key, required this.months});

  @override
  Widget build(BuildContext context) {
    const fuelColor = AppColors.primary;
    const expenseColor = AppColors.secondary;

    return Column(
      children: [
        SizedBox(
          height: _chartHeight,
          child: BarChart(
            BarChartData(
              gridData: _grid,
              borderData: FlBorderData(show: false),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(getTooltipColor: (_) => AppColors.surface),
              ),
              titlesData: FlTitlesData(
                topTitles: _hidden,
                rightTitles: _hidden,
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: _leftAxisReserved,
                    getTitlesWidget: (value, meta) =>
                        _axisLabel(context, _compact.format(value)),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: _bottomAxisReserved,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i < 0 || i >= months.length) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: _axisLabel(context, Formatters.monthShort.format(months[i].month)),
                      );
                    },
                  ),
                ),
              ),
              barGroups: [
                for (var i = 0; i < months.length; i++)
                  BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: months[i].total,
                        width: _barWidth,
                        color: fuelColor,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                        rodStackItems: [
                          BarChartRodStackItem(0, months[i].fuel, fuelColor),
                          BarChartRodStackItem(months[i].fuel, months[i].total, expenseColor),
                        ],
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Legend(color: fuelColor, label: 'Fuel', size: _legendDot),
            const SizedBox(width: 24),
            _Legend(color: expenseColor, label: 'Expenses', size: _legendDot),
          ],
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  final double size;

  const _Legend({required this.color, required this.label, required this.size});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(size / 2)),
          ),
          const SizedBox(width: 8),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
        ],
      );
}
