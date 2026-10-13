import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../core/constants.dart';
import '../core/formatters.dart';
import '../core/units.dart';
import '../data/models/expense_entry.dart';
import '../data/models/fuel_entry.dart';
import '../data/models/syncable.dart';
import '../data/models/vehicle.dart';
import '../data/repositories/syncable_repository.dart';
import '../services/mileage_calculator.dart';
import '../services/oil_reminder.dart';
import '../services/settings_service.dart';
import '../services/sync/sync_manager.dart';

class AppState extends ChangeNotifier {
  static const _uuid = Uuid();

  final Repositories _repos;
  final SettingsService _settingsService;
  final SyncManager sync;

  AppState(this._repos, this._settingsService, this.sync)
      : _settings = _settingsService.load() {
    _updateFormatters();
  }

  AppSettings _settings;
  late UnitConverter _units;
  late Formatters _fmt;
  List<Vehicle> _vehicles = [];
  Vehicle? _selected;
  List<FuelEntry> _fuel = [];
  List<ExpenseEntry> _expenses = [];
  VehicleStats _stats = VehicleStats.empty;
  OilReminder? _oilReminder;
  bool _loading = true;

  AppSettings get settings => _settings;
  List<Vehicle> get vehicles => _vehicles;
  Vehicle? get selectedVehicle => _selected;
  List<FuelEntry> get fuelEntries => _fuel;
  List<ExpenseEntry> get expenses => _expenses;
  VehicleStats get stats => _stats;
  OilReminder? get oilReminder => _oilReminder;
  bool get loading => _loading;

  UnitConverter get units => _units;
  Currency get currency => _fmt.currency;
  Formatters get fmt => _fmt;

  void _updateFormatters() {
    _units = UnitConverter(_settings.distanceUnit, _settings.volumeUnit);
    _fmt = Formatters(currencyByCode(_settings.currencyCode), _units);
  }

  static String newId() => _uuid.v4();

  Future<void> init() async {
    await _reload();
    _loading = false;
    notifyListeners();
    syncNow();
  }

  Future<void> syncNow() async {
    final changed = await sync.sync();
    if (changed) {
      await _reload();
      notifyListeners();
    }
  }

  Future<void> updateSettings(AppSettings s) async {
    _settings = s;
    _updateFormatters();
    await _settingsService.save(s);
    notifyListeners();
  }

  Future<void> selectVehicle(Vehicle v) async {
    await _settingsService.setSelectedVehicleId(v.id);
    await _reload();
    notifyListeners();
  }

  Future<void> saveVehicle(Vehicle v) async {
    await _repos.vehicles.save(v.copyWith(updatedAt: nowMs()));
    if (_selected == null) await _settingsService.setSelectedVehicleId(v.id);
    await _afterWrite();
  }

  Future<void> deleteVehicle(Vehicle v) async {
    final now = nowMs();
    for (final f in await _repos.fuel.getActive(vehicleId: v.id)) {
      await _repos.fuel.save(f.copyWith(deleted: true, updatedAt: now));
    }
    for (final e in await _repos.expenses.getActive(vehicleId: v.id)) {
      await _repos.expenses.save(e.copyWith(deleted: true, updatedAt: now));
    }
    await _repos.vehicles.save(v.copyWith(deleted: true, updatedAt: now));
    await _afterWrite();
  }

  Future<void> saveFuel(FuelEntry e) async {
    await _repos.fuel.save(e.copyWith(updatedAt: nowMs()));
    await _afterWrite();
  }

  Future<void> deleteFuel(FuelEntry e) async {
    await _repos.fuel.save(e.copyWith(deleted: true, updatedAt: nowMs()));
    await _afterWrite();
  }

  Future<void> saveExpense(ExpenseEntry e) async {
    await _repos.expenses.save(e.copyWith(updatedAt: nowMs()));
    await _afterWrite();
  }

  Future<void> deleteExpense(ExpenseEntry e) async {
    await _repos.expenses.save(e.copyWith(deleted: true, updatedAt: nowMs()));
    await _afterWrite();
  }

  bool get useTripInput => _settingsService.useTripInput;

  Future<void> setUseTripInput(bool value) => _settingsService.setUseTripInput(value);

  /// Latest known odometer of the selected vehicle, used to prefill forms.
  double? get latestOdometerKm => _stats.latestOdometerKm;

  Future<void> _afterWrite() async {
    await _reload();
    notifyListeners();
    syncNow();
  }

  Future<void> _reload() async {
    _vehicles = await _repos.vehicles.getActive();
    final selectedId = _settingsService.selectedVehicleId;
    _selected = _vehicles.where((v) => v.id == selectedId).firstOrNull ??
        (_vehicles.isEmpty ? null : _vehicles.first);
    final vehicle = _selected;
    if (vehicle == null) {
      _fuel = [];
      _expenses = [];
      _stats = VehicleStats.empty;
      _oilReminder = null;
      return;
    }
    _fuel = await _repos.fuel.getActive(vehicleId: vehicle.id);
    _expenses = await _repos.expenses.getActive(vehicleId: vehicle.id);
    _stats = MileageCalculator.calculate(_fuel, _expenses);
    _oilReminder = OilReminder.from(_expenses, _stats.latestOdometerKm);
  }
}
