import '../data/models/expense_entry.dart';
import '../data/models/fuel_entry.dart';

class FillUpEfficiency {
  final double kmPerLiter;
  final double distanceKm;

  const FillUpEfficiency(this.kmPerLiter, this.distanceKm);
}

class EfficiencyPoint {
  final DateTime date;
  final double kmPerLiter;

  const EfficiencyPoint(this.date, this.kmPerLiter);
}

class MonthlySpend {
  final DateTime month;
  final double fuel;
  final double expenses;

  const MonthlySpend(this.month, this.fuel, this.expenses);

  double get total => fuel + expenses;
}

class VehicleStats {
  final Map<String, FillUpEfficiency> perEntry;
  final List<EfficiencyPoint> trend;
  final List<MonthlySpend> monthly;
  final double? averageKmPerLiter;
  final double? lastKmPerLiter;
  final double? bestKmPerLiter;
  final double? worstKmPerLiter;
  final double totalDistanceKm;
  final double totalLiters;
  final double totalFuelCost;
  final double totalExpenseCost;
  final double? fuelCostPerKm;
  final double? totalCostPerKm;
  final double? latestOdometerKm;
  final int fillUpCount;

  const VehicleStats({
    required this.perEntry,
    required this.trend,
    required this.monthly,
    required this.averageKmPerLiter,
    required this.lastKmPerLiter,
    required this.bestKmPerLiter,
    required this.worstKmPerLiter,
    required this.totalDistanceKm,
    required this.totalLiters,
    required this.totalFuelCost,
    required this.totalExpenseCost,
    required this.fuelCostPerKm,
    required this.totalCostPerKm,
    required this.latestOdometerKm,
    required this.fillUpCount,
  });

  static const empty = VehicleStats(
    perEntry: {},
    trend: [],
    monthly: [],
    averageKmPerLiter: null,
    lastKmPerLiter: null,
    bestKmPerLiter: null,
    worstKmPerLiter: null,
    totalDistanceKm: 0,
    totalLiters: 0,
    totalFuelCost: 0,
    totalExpenseCost: 0,
    fuelCostPerKm: null,
    totalCostPerKm: null,
    latestOdometerKm: null,
    fillUpCount: 0,
  );
}

/// Full-tank method: mileage for a full fill-up is the distance since the
/// previous full fill-up divided by all fuel added after it (partials included).
/// A "missed previous fill-up" entry breaks the chain, since fuel is unknown.
class MileageCalculator {
  static const int monthsInChart = 6;

  static VehicleStats calculate(List<FuelEntry> fuel, List<ExpenseEntry> expenses) {
    if (fuel.isEmpty && expenses.isEmpty) return VehicleStats.empty;

    final sorted = [...fuel]..sort((a, b) {
        final byOdo = a.odometerKm.compareTo(b.odometerKm);
        return byOdo != 0 ? byOdo : a.date.compareTo(b.date);
      });

    final perEntry = <String, FillUpEfficiency>{};
    final trend = <EfficiencyPoint>[];
    FuelEntry? lastFull;
    var litersSinceFull = 0.0;
    var costSinceFull = 0.0;
    var segmentDistance = 0.0;
    var segmentLiters = 0.0;
    var segmentCost = 0.0;

    for (final entry in sorted) {
      if (entry.missedPrevious) {
        lastFull = entry.fullTank ? entry : null;
        litersSinceFull = 0;
        costSinceFull = 0;
        continue;
      }
      litersSinceFull += entry.liters;
      costSinceFull += entry.totalCost;
      if (!entry.fullTank) continue;

      final previous = lastFull;
      if (previous != null) {
        final distance = entry.odometerKm - previous.odometerKm;
        if (distance > 0 && litersSinceFull > 0) {
          final kmpl = distance / litersSinceFull;
          perEntry[entry.id] = FillUpEfficiency(kmpl, distance);
          trend.add(EfficiencyPoint(entry.date, kmpl));
          segmentDistance += distance;
          segmentLiters += litersSinceFull;
          segmentCost += costSinceFull;
        }
      }
      lastFull = entry;
      litersSinceFull = 0;
      costSinceFull = 0;
    }

    final efficiencies = perEntry.values.map((e) => e.kmPerLiter).toList();
    final totalFuelCost = fuel.fold<double>(0, (s, e) => s + e.totalCost);
    final totalExpenseCost = expenses.fold<double>(0, (s, e) => s + e.cost);
    final totalDistance =
        sorted.length < 2 ? 0.0 : sorted.last.odometerKm - sorted.first.odometerKm;

    final latestOdo = _latestOdometer(sorted, expenses);

    return VehicleStats(
      perEntry: perEntry,
      trend: trend,
      monthly: _monthly(fuel, expenses),
      averageKmPerLiter: segmentLiters > 0 ? segmentDistance / segmentLiters : null,
      lastKmPerLiter: trend.isEmpty ? null : trend.last.kmPerLiter,
      bestKmPerLiter: efficiencies.isEmpty ? null : efficiencies.reduce((a, b) => a > b ? a : b),
      worstKmPerLiter: efficiencies.isEmpty ? null : efficiencies.reduce((a, b) => a < b ? a : b),
      totalDistanceKm: totalDistance,
      totalLiters: fuel.fold<double>(0, (s, e) => s + e.liters),
      totalFuelCost: totalFuelCost,
      totalExpenseCost: totalExpenseCost,
      fuelCostPerKm: segmentDistance > 0 ? segmentCost / segmentDistance : null,
      totalCostPerKm:
          totalDistance > 0 ? (totalFuelCost + totalExpenseCost) / totalDistance : null,
      latestOdometerKm: latestOdo,
      fillUpCount: fuel.length,
    );
  }

  static double? _latestOdometer(List<FuelEntry> sortedFuel, List<ExpenseEntry> expenses) {
    double? latest = sortedFuel.isEmpty ? null : sortedFuel.last.odometerKm;
    for (final e in expenses) {
      final odo = e.odometerKm;
      if (odo != null && (latest == null || odo > latest)) latest = odo;
    }
    return latest;
  }

  static List<MonthlySpend> _monthly(List<FuelEntry> fuel, List<ExpenseEntry> expenses) {
    final now = DateTime.now();
    final months = List.generate(
        monthsInChart, (i) => DateTime(now.year, now.month - (monthsInChart - 1 - i)));
    final fuelByMonth = <DateTime, double>{};
    final expenseByMonth = <DateTime, double>{};
    for (final e in fuel) {
      final key = DateTime(e.date.year, e.date.month);
      fuelByMonth[key] = (fuelByMonth[key] ?? 0) + e.totalCost;
    }
    for (final e in expenses) {
      final key = DateTime(e.date.year, e.date.month);
      expenseByMonth[key] = (expenseByMonth[key] ?? 0) + e.cost;
    }
    return months
        .map((m) => MonthlySpend(m, fuelByMonth[m] ?? 0, expenseByMonth[m] ?? 0))
        .toList();
  }
}
