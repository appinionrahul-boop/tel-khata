import 'package:flutter_test/flutter_test.dart';
import 'package:fuel_log/core/constants.dart';
import 'package:fuel_log/core/units.dart';
import 'package:fuel_log/data/models/expense_entry.dart';
import 'package:fuel_log/data/models/fuel_entry.dart';
import 'package:fuel_log/services/mileage_calculator.dart';
import 'package:fuel_log/services/oil_reminder.dart';

FuelEntry fill(String id, double odo, double liters,
        {bool full = true, bool missed = false, double price = 100}) =>
    FuelEntry(
      id: id,
      vehicleId: 'v1',
      date: DateTime(2026, 1, 1).add(Duration(days: odo ~/ 100)),
      odometerKm: odo,
      liters: liters,
      totalCost: liters * price,
      fullTank: full,
      missedPrevious: missed,
      updatedAt: 0,
    );

void main() {
  group('MileageCalculator', () {
    test('first full fill-up has no mileage', () {
      final s = MileageCalculator.calculate([fill('a', 1000, 40)], []);
      expect(s.perEntry, isEmpty);
      expect(s.averageKmPerLiter, isNull);
    });

    test('mileage between two full fill-ups', () {
      final s = MileageCalculator.calculate([fill('a', 1000, 40), fill('b', 1500, 25)], []);
      expect(s.perEntry['b']!.kmPerLiter, closeTo(20, 1e-9));
      expect(s.averageKmPerLiter, closeTo(20, 1e-9));
    });

    test('partial fill-ups are added to the next full fill-up', () {
      final s = MileageCalculator.calculate([
        fill('a', 1000, 40),
        fill('b', 1200, 10, full: false),
        fill('c', 1600, 20),
      ], []);
      expect(s.perEntry.containsKey('b'), isFalse);
      expect(s.perEntry['c']!.kmPerLiter, closeTo(600 / 30, 1e-9));
    });

    test('missed fill-up breaks the chain', () {
      final s = MileageCalculator.calculate([
        fill('a', 1000, 40),
        fill('b', 1500, 25, missed: true),
        fill('c', 1800, 15),
      ], []);
      expect(s.perEntry.containsKey('b'), isFalse);
      expect(s.perEntry['c']!.kmPerLiter, closeTo(20, 1e-9));
    });

    test('average is weighted by distance and fuel', () {
      final s = MileageCalculator.calculate([
        fill('a', 0, 10),
        fill('b', 100, 10),
        fill('c', 400, 10),
      ], []);
      expect(s.averageKmPerLiter, closeTo(400 / 20, 1e-9));
      expect(s.bestKmPerLiter, closeTo(30, 1e-9));
      expect(s.worstKmPerLiter, closeTo(10, 1e-9));
      expect(s.fuelCostPerKm, closeTo(2000 / 400, 1e-9));
    });
  });

  group('UnitConverter', () {
    test('km/L to mpg', () {
      const c = UnitConverter(DistanceUnit.mi, VolumeUnit.gallon);
      expect(c.efficiencyFromKmPerLiter(10), closeTo(23.521, 1e-3));
    });

    test('round trips', () {
      const c = UnitConverter(DistanceUnit.mi, VolumeUnit.gallon);
      expect(c.distanceToKm(c.distanceFromKm(123.4)), closeTo(123.4, 1e-9));
      expect(c.volumeToLiters(c.volumeFromLiters(45.6)), closeTo(45.6, 1e-9));
    });
  });

  group('OilReminder', () {
    ExpenseEntry oil(String id, double odo, double interval) => ExpenseEntry(
          id: id,
          vehicleId: 'v1',
          date: DateTime(2026, 1, 1),
          category: ExpenseCategory.engineOil,
          title: 'Engine oil',
          cost: 1500,
          odometerKm: odo,
          oilIntervalKm: interval,
          updatedAt: 0,
        );

    test('no oil change gives no reminder', () {
      expect(OilReminder.from([], 1000), isNull);
    });

    test('uses the latest oil change and reports status', () {
      final changes = [oil('a', 1000, 3000), oil('b', 4000, 3000)];
      expect(OilReminder.from(changes, 5000)!.status, OilStatus.ok);
      expect(OilReminder.from(changes, 6700)!.status, OilStatus.dueSoon);
      final overdue = OilReminder.from(changes, 7200)!;
      expect(overdue.status, OilStatus.overdue);
      expect(overdue.remainingKm, closeTo(-200, 1e-9));
      expect(overdue.usedFraction, 1.0);
    });
  });
}
