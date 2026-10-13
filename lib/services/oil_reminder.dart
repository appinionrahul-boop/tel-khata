import '../data/models/expense_entry.dart';

enum OilStatus { ok, dueSoon, overdue }

class OilReminder {
  // Due soon once this share of the oil's run capacity is left.
  static const double dueSoonFraction = 0.15;

  final ExpenseEntry lastChange;
  final double dueAtKm;
  final double remainingKm;
  final double usedFraction;

  const OilReminder._(this.lastChange, this.dueAtKm, this.remainingKm, this.usedFraction);

  OilStatus get status {
    if (remainingKm <= 0) return OilStatus.overdue;
    if (remainingKm <= lastChange.oilIntervalKm! * dueSoonFraction) return OilStatus.dueSoon;
    return OilStatus.ok;
  }

  /// Based on the oil change with the highest odometer that has a run capacity.
  static OilReminder? from(List<ExpenseEntry> expenses, double? latestOdometerKm) {
    ExpenseEntry? last;
    for (final e in expenses) {
      final odo = e.odometerKm;
      final interval = e.oilIntervalKm;
      if (!e.isOilChange || odo == null || interval == null || interval <= 0) continue;
      if (last == null || odo > last.odometerKm!) last = e;
    }
    if (last == null) return null;

    final interval = last.oilIntervalKm!;
    final changedAt = last.odometerKm!;
    final current = latestOdometerKm ?? changedAt;
    final dueAt = changedAt + interval;
    final used = ((current - changedAt) / interval).clamp(0.0, 1.0);
    return OilReminder._(last, dueAt, dueAt - current, used);
  }
}
