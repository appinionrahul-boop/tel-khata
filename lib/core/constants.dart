import 'package:flutter/material.dart';

class Currency {
  final String code;
  final String symbol;
  final String name;

  const Currency(this.code, this.symbol, this.name);
}

const List<Currency> kCurrencies = [
  Currency('BDT', '৳', 'Bangladeshi Taka'),
  Currency('USD', '\$', 'US Dollar'),
  Currency('EUR', '€', 'Euro'),
  Currency('GBP', '£', 'British Pound'),
  Currency('INR', '₹', 'Indian Rupee'),
  Currency('PKR', 'Rs', 'Pakistani Rupee'),
  Currency('NPR', 'Rs', 'Nepalese Rupee'),
  Currency('LKR', 'Rs', 'Sri Lankan Rupee'),
  Currency('AED', 'AED', 'UAE Dirham'),
  Currency('SAR', 'SAR', 'Saudi Riyal'),
  Currency('MYR', 'RM', 'Malaysian Ringgit'),
  Currency('SGD', 'S\$', 'Singapore Dollar'),
  Currency('CAD', 'C\$', 'Canadian Dollar'),
  Currency('AUD', 'A\$', 'Australian Dollar'),
  Currency('JPY', '¥', 'Japanese Yen'),
];

Currency currencyByCode(String code) =>
    kCurrencies.firstWhere((c) => c.code == code, orElse: () => kCurrencies.first);

enum VehicleType { car, motorcycle, truck, bus, other }

extension VehicleTypeX on VehicleType {
  String get displayName => switch (this) {
        VehicleType.car => 'Car',
        VehicleType.motorcycle => 'Motorcycle',
        VehicleType.truck => 'Truck',
        VehicleType.bus => 'Bus / Van',
        VehicleType.other => 'Other',
      };

  IconData get icon => switch (this) {
        VehicleType.car => Icons.directions_car,
        VehicleType.motorcycle => Icons.two_wheeler,
        VehicleType.truck => Icons.local_shipping,
        VehicleType.bus => Icons.airport_shuttle,
        VehicleType.other => Icons.commute,
      };
}

enum FuelType { petrol, octane, diesel, cng, lpg, electric, other }

extension FuelTypeX on FuelType {
  IconData get icon => switch (this) {
        FuelType.petrol => Icons.local_gas_station,
        FuelType.octane => Icons.speed,
        FuelType.diesel => Icons.oil_barrel,
        FuelType.cng => Icons.propane_tank,
        FuelType.lpg => Icons.propane,
        FuelType.electric => Icons.electric_bolt,
        FuelType.other => Icons.more_horiz,
      };

  String get displayName => switch (this) {
        FuelType.petrol => 'Petrol',
        FuelType.octane => 'Octane',
        FuelType.diesel => 'Diesel',
        FuelType.cng => 'CNG',
        FuelType.lpg => 'LPG',
        FuelType.electric => 'Electric',
        FuelType.other => 'Other',
      };
}

enum ExpenseCategory { engineOil, service, repair, tyres, insurance, tax, parking, toll, wash, other }

extension ExpenseCategoryX on ExpenseCategory {
  String get displayName => switch (this) {
        ExpenseCategory.engineOil => 'Engine oil',
        ExpenseCategory.service => 'Service',
        ExpenseCategory.repair => 'Repair',
        ExpenseCategory.tyres => 'Tyres',
        ExpenseCategory.insurance => 'Insurance',
        ExpenseCategory.tax => 'Tax / Fitness',
        ExpenseCategory.parking => 'Parking',
        ExpenseCategory.toll => 'Toll',
        ExpenseCategory.wash => 'Wash',
        ExpenseCategory.other => 'Other',
      };

  IconData get icon => switch (this) {
        ExpenseCategory.engineOil => Icons.oil_barrel,
        ExpenseCategory.service => Icons.build,
        ExpenseCategory.repair => Icons.handyman,
        ExpenseCategory.tyres => Icons.tire_repair,
        ExpenseCategory.insurance => Icons.shield,
        ExpenseCategory.tax => Icons.receipt_long,
        ExpenseCategory.parking => Icons.local_parking,
        ExpenseCategory.toll => Icons.toll,
        ExpenseCategory.wash => Icons.local_car_wash,
        ExpenseCategory.other => Icons.more_horiz,
      };
}

T enumByName<T extends Enum>(List<T> values, String? name, T fallback) {
  for (final v in values) {
    if (v.name == name) return v;
  }
  return fallback;
}
