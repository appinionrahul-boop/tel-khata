import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';
import '../core/units.dart';

class AppSettings {
  final String currencyCode;
  final DistanceUnit distanceUnit;
  final VolumeUnit volumeUnit;
  final bool onboarded;

  const AppSettings({
    required this.currencyCode,
    required this.distanceUnit,
    required this.volumeUnit,
    required this.onboarded,
  });

  AppSettings copyWith({
    String? currencyCode,
    DistanceUnit? distanceUnit,
    VolumeUnit? volumeUnit,
    bool? onboarded,
  }) =>
      AppSettings(
        currencyCode: currencyCode ?? this.currencyCode,
        distanceUnit: distanceUnit ?? this.distanceUnit,
        volumeUnit: volumeUnit ?? this.volumeUnit,
        onboarded: onboarded ?? this.onboarded,
      );
}

class SettingsService {
  static const _kCurrency = 'currency';
  static const _kDistance = 'distance_unit';
  static const _kVolume = 'volume_unit';
  static const _kOnboarded = 'onboarded';
  static const _kSelectedVehicle = 'selected_vehicle';
  static const _kLastSync = 'last_sync_at';
  static const _kTripInput = 'trip_input';
  static const _defaultCurrency = 'BDT';

  final SharedPreferences _prefs;

  SettingsService(this._prefs);

  static Future<SettingsService> create() async =>
      SettingsService(await SharedPreferences.getInstance());

  AppSettings load() => AppSettings(
        currencyCode: _prefs.getString(_kCurrency) ?? _defaultCurrency,
        distanceUnit: enumByName(DistanceUnit.values, _prefs.getString(_kDistance), DistanceUnit.km),
        volumeUnit: enumByName(VolumeUnit.values, _prefs.getString(_kVolume), VolumeUnit.liter),
        onboarded: _prefs.getBool(_kOnboarded) ?? false,
      );

  Future<void> save(AppSettings s) async {
    await _prefs.setString(_kCurrency, s.currencyCode);
    await _prefs.setString(_kDistance, s.distanceUnit.name);
    await _prefs.setString(_kVolume, s.volumeUnit.name);
    await _prefs.setBool(_kOnboarded, s.onboarded);
  }

  String? get selectedVehicleId => _prefs.getString(_kSelectedVehicle);

  Future<void> setSelectedVehicleId(String id) => _prefs.setString(_kSelectedVehicle, id);

  bool get useTripInput => _prefs.getBool(_kTripInput) ?? false;

  Future<void> setUseTripInput(bool value) => _prefs.setBool(_kTripInput, value);

  int get lastSyncAt => _prefs.getInt(_kLastSync) ?? 0;

  Future<void> setLastSyncAt(int ms) => _prefs.setInt(_kLastSync, ms);
}
