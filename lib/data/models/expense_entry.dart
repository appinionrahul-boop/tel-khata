import '../../core/constants.dart';
import 'syncable.dart';

class ExpenseEntry implements Syncable {
  static const table = 'expense_entries';

  @override
  final String id;
  final String vehicleId;
  final DateTime date;
  final ExpenseCategory category;
  final String title;
  final double cost;
  final double? odometerKm;
  final String? note;
  final String? oilBrand;
  final String? oilGrade;
  final double? oilIntervalKm;
  final double? oilQuantityLiters;
  @override
  final int updatedAt;
  @override
  final bool deleted;

  const ExpenseEntry({
    required this.id,
    required this.vehicleId,
    required this.date,
    required this.category,
    required this.title,
    required this.cost,
    this.odometerKm,
    this.note,
    this.oilBrand,
    this.oilGrade,
    this.oilIntervalKm,
    this.oilQuantityLiters,
    required this.updatedAt,
    this.deleted = false,
  });

  bool get isOilChange => category == ExpenseCategory.engineOil;

  ExpenseEntry copyWith({int? updatedAt, bool? deleted}) => ExpenseEntry(
        id: id,
        vehicleId: vehicleId,
        date: date,
        category: category,
        title: title,
        cost: cost,
        odometerKm: odometerKm,
        note: note,
        oilBrand: oilBrand,
        oilGrade: oilGrade,
        oilIntervalKm: oilIntervalKm,
        oilQuantityLiters: oilQuantityLiters,
        updatedAt: updatedAt ?? this.updatedAt,
        deleted: deleted ?? this.deleted,
      );

  @override
  Map<String, Object?> toMap() => {
        'id': id,
        'vehicle_id': vehicleId,
        'date': date.millisecondsSinceEpoch,
        'category': category.name,
        'title': title,
        'cost': cost,
        'odometer_km': odometerKm,
        'note': note,
        'oil_brand': oilBrand,
        'oil_grade': oilGrade,
        'oil_interval_km': oilIntervalKm,
        'oil_quantity_l': oilQuantityLiters,
        'updated_at': updatedAt,
        'deleted': boolToInt(deleted),
      };

  factory ExpenseEntry.fromMap(Map<String, Object?> m) => ExpenseEntry(
        id: m['id'] as String,
        vehicleId: m['vehicle_id'] as String,
        date: DateTime.fromMillisecondsSinceEpoch(m['date'] as int),
        category: enumByName(
            ExpenseCategory.values, m['category'] as String?, ExpenseCategory.other),
        title: m['title'] as String,
        cost: (m['cost'] as num).toDouble(),
        odometerKm: toDoubleOrNull(m['odometer_km']),
        note: m['note'] as String?,
        oilBrand: m['oil_brand'] as String?,
        oilGrade: m['oil_grade'] as String?,
        oilIntervalKm: toDoubleOrNull(m['oil_interval_km']),
        oilQuantityLiters: toDoubleOrNull(m['oil_quantity_l']),
        updatedAt: m['updated_at'] as int,
        deleted: intToBool(m['deleted']),
      );
}
