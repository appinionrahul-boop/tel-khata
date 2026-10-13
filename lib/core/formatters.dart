import 'package:intl/intl.dart';

import 'constants.dart';
import 'units.dart';

class Formatters {
  static final DateFormat date = DateFormat('d MMM yyyy');
  static final DateFormat monthShort = DateFormat('MMM');
  static final NumberFormat _whole = NumberFormat('#,##0');
  static final NumberFormat _twoDp = NumberFormat('#,##0.00');

  final Currency currency;
  final UnitConverter units;

  Formatters(this.currency, this.units);

  String money(double value) => '${currency.symbol} ${_twoDp.format(value)}';

  String moneyShort(double value) => '${currency.symbol} ${_whole.format(value)}';

  String distance(double km) => '${_whole.format(units.distanceFromKm(km))} ${units.distanceUnit.label}';

  String volume(double liters) =>
      '${_twoDp.format(units.volumeFromLiters(liters))} ${units.volumeUnit.label}';

  String efficiency(double? kmPerLiter) => kmPerLiter == null
      ? '--'
      : '${_twoDp.format(units.efficiencyFromKmPerLiter(kmPerLiter))} ${units.efficiencyLabel}';

  String pricePerVolume(double perLiter) =>
      '${money(units.pricePerVolumeFromPerLiter(perLiter))}/${units.volumeUnit.label}';

  String costPerDistance(double? perKm) => perKm == null
      ? '--'
      : '${money(perKm / units.distanceFromKm(1))}/${units.distanceUnit.label}';

  static String trimNumber(double value) =>
      value == value.roundToDouble() ? value.toStringAsFixed(0) : value.toStringAsFixed(2);
}
