import '../../core/constants.dart';
import 'syncable.dart';

class Vehicle implements Syncable {
  static const table = 'vehicles';

  @override
  final String id;
  final String name;
  final VehicleType type;
  final FuelType fuelType;
  final String? makeModel;
  final String? registrationNo;
  @override
  final int updatedAt;
  @override
  final bool deleted;

  const Vehicle({
    required this.id,
    required this.name,
    required this.type,
    required this.fuelType,
    this.makeModel,
    this.registrationNo,
    required this.updatedAt,
    this.deleted = false,
  });

  Vehicle copyWith({
    String? name,
    VehicleType? type,
    FuelType? fuelType,
    String? makeModel,
    String? registrationNo,
    int? updatedAt,
    bool? deleted,
  }) =>
      Vehicle(
        id: id,
        name: name ?? this.name,
        type: type ?? this.type,
        fuelType: fuelType ?? this.fuelType,
        makeModel: makeModel ?? this.makeModel,
        registrationNo: registrationNo ?? this.registrationNo,
        updatedAt: updatedAt ?? this.updatedAt,
        deleted: deleted ?? this.deleted,
      );

  @override
  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'type': type.name,
        'fuel_type': fuelType.name,
        'make_model': makeModel,
        'registration_no': registrationNo,
        'updated_at': updatedAt,
        'deleted': boolToInt(deleted),
      };

  factory Vehicle.fromMap(Map<String, Object?> m) => Vehicle(
        id: m['id'] as String,
        name: m['name'] as String,
        type: enumByName(VehicleType.values, m['type'] as String?, VehicleType.car),
        fuelType: enumByName(FuelType.values, m['fuel_type'] as String?, FuelType.petrol),
        makeModel: m['make_model'] as String?,
        registrationNo: m['registration_no'] as String?,
        updatedAt: m['updated_at'] as int,
        deleted: intToBool(m['deleted']),
      );
}
