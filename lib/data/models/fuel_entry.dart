import 'syncable.dart';

/// A fill-up. Odometer is stored in km and volume in liters.
class FuelEntry implements Syncable {
  static const table = 'fuel_entries';

  @override
  final String id;
  final String vehicleId;
  final DateTime date;
  final double odometerKm;
  final double liters;
  final double totalCost;
  final bool fullTank;
  final bool missedPrevious;
  final String? station;
  final String? note;
  @override
  final int updatedAt;
  @override
  final bool deleted;

  const FuelEntry({
    required this.id,
    required this.vehicleId,
    required this.date,
    required this.odometerKm,
    required this.liters,
    required this.totalCost,
    this.fullTank = true,
    this.missedPrevious = false,
    this.station,
    this.note,
    required this.updatedAt,
    this.deleted = false,
  });

  double get pricePerLiter => liters > 0 ? totalCost / liters : 0;

  FuelEntry copyWith({int? updatedAt, bool? deleted}) => FuelEntry(
        id: id,
        vehicleId: vehicleId,
        date: date,
        odometerKm: odometerKm,
        liters: liters,
        totalCost: totalCost,
        fullTank: fullTank,
        missedPrevious: missedPrevious,
        station: station,
        note: note,
        updatedAt: updatedAt ?? this.updatedAt,
        deleted: deleted ?? this.deleted,
      );

  @override
  Map<String, Object?> toMap() => {
        'id': id,
        'vehicle_id': vehicleId,
        'date': date.millisecondsSinceEpoch,
        'odometer_km': odometerKm,
        'liters': liters,
        'total_cost': totalCost,
        'full_tank': boolToInt(fullTank),
        'missed_previous': boolToInt(missedPrevious),
        'station': station,
        'note': note,
        'updated_at': updatedAt,
        'deleted': boolToInt(deleted),
      };

  factory FuelEntry.fromMap(Map<String, Object?> m) => FuelEntry(
        id: m['id'] as String,
        vehicleId: m['vehicle_id'] as String,
        date: DateTime.fromMillisecondsSinceEpoch(m['date'] as int),
        odometerKm: (m['odometer_km'] as num).toDouble(),
        liters: (m['liters'] as num).toDouble(),
        totalCost: (m['total_cost'] as num).toDouble(),
        fullTank: intToBool(m['full_tank']),
        missedPrevious: intToBool(m['missed_previous']),
        station: m['station'] as String?,
        note: m['note'] as String?,
        updatedAt: m['updated_at'] as int,
        deleted: intToBool(m['deleted']),
      );
}
