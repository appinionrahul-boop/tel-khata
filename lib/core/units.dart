enum DistanceUnit { km, mi }

enum VolumeUnit { liter, gallon }

extension DistanceUnitX on DistanceUnit {
  String get label => this == DistanceUnit.km ? 'km' : 'mi';
  String get displayName => this == DistanceUnit.km ? 'Kilometers' : 'Miles';
}

extension VolumeUnitX on VolumeUnit {
  String get label => this == VolumeUnit.liter ? 'L' : 'gal';
  String get displayName => this == VolumeUnit.liter ? 'Liters' : 'Gallons (US)';
}

/// Data is stored in km and liters; these convert to and from the user's units.
class UnitConverter {
  static const double kmPerMile = 1.609344;
  static const double litersPerGallon = 3.785411784;

  final DistanceUnit distanceUnit;
  final VolumeUnit volumeUnit;

  const UnitConverter(this.distanceUnit, this.volumeUnit);

  double distanceFromKm(double km) =>
      distanceUnit == DistanceUnit.km ? km : km / kmPerMile;

  double distanceToKm(double value) =>
      distanceUnit == DistanceUnit.km ? value : value * kmPerMile;

  double volumeFromLiters(double liters) =>
      volumeUnit == VolumeUnit.liter ? liters : liters / litersPerGallon;

  double volumeToLiters(double value) =>
      volumeUnit == VolumeUnit.liter ? value : value * litersPerGallon;

  double pricePerVolumeFromPerLiter(double perLiter) =>
      volumeUnit == VolumeUnit.liter ? perLiter : perLiter * litersPerGallon;

  double efficiencyFromKmPerLiter(double kmPerLiter) =>
      distanceFromKm(kmPerLiter) / volumeFromLiters(1);

  String get efficiencyLabel => '${distanceUnit.label}/${volumeUnit.label}';
}
