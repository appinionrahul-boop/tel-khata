import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/expense_entry.dart';
import '../models/fuel_entry.dart';
import '../models/vehicle.dart';

class AppDatabase {
  static const _fileName = 'fuel_log.db';
  static const _version = 2;
  static const _oilColumns = {
    'oil_brand': 'TEXT',
    'oil_grade': 'TEXT',
    'oil_interval_km': 'REAL',
    'oil_quantity_l': 'REAL',
  };

  Database? _db;

  Future<Database> get database async => _db ??= await _open();

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    return openDatabase(
      p.join(dir, _fileName),
      version: _version,
      onCreate: (db, _) async {
        final batch = db.batch();
        batch.execute('''
          CREATE TABLE ${Vehicle.table} (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            type TEXT NOT NULL,
            fuel_type TEXT NOT NULL,
            make_model TEXT,
            registration_no TEXT,
            updated_at INTEGER NOT NULL,
            deleted INTEGER NOT NULL DEFAULT 0,
            dirty INTEGER NOT NULL DEFAULT 1
          )''');
        batch.execute('''
          CREATE TABLE ${FuelEntry.table} (
            id TEXT PRIMARY KEY,
            vehicle_id TEXT NOT NULL,
            date INTEGER NOT NULL,
            odometer_km REAL NOT NULL,
            liters REAL NOT NULL,
            total_cost REAL NOT NULL,
            full_tank INTEGER NOT NULL,
            missed_previous INTEGER NOT NULL,
            station TEXT,
            note TEXT,
            updated_at INTEGER NOT NULL,
            deleted INTEGER NOT NULL DEFAULT 0,
            dirty INTEGER NOT NULL DEFAULT 1
          )''');
        batch.execute('''
          CREATE TABLE ${ExpenseEntry.table} (
            id TEXT PRIMARY KEY,
            vehicle_id TEXT NOT NULL,
            date INTEGER NOT NULL,
            category TEXT NOT NULL,
            title TEXT NOT NULL,
            cost REAL NOT NULL,
            odometer_km REAL,
            note TEXT,
            ${_oilColumns.entries.map((c) => '${c.key} ${c.value},').join('\n            ')}
            updated_at INTEGER NOT NULL,
            deleted INTEGER NOT NULL DEFAULT 0,
            dirty INTEGER NOT NULL DEFAULT 1
          )''');
        batch.execute(
            'CREATE INDEX idx_fuel_vehicle ON ${FuelEntry.table}(vehicle_id, odometer_km)');
        batch.execute(
            'CREATE INDEX idx_expense_vehicle ON ${ExpenseEntry.table}(vehicle_id, date)');
        await batch.commit(noResult: true);
      },
      onUpgrade: (db, oldVersion, _) async {
        if (oldVersion < 2) await _addMissingColumns(db, ExpenseEntry.table, _oilColumns);
      },
    );
  }

  // Some installs already have these columns, so only add the ones that are missing.
  static Future<void> _addMissingColumns(
      Database db, String table, Map<String, String> columns) async {
    final info = await db.rawQuery('PRAGMA table_info($table)');
    final existing = {for (final row in info) row['name'] as String};
    for (final c in columns.entries) {
      if (existing.contains(c.key)) continue;
      await db.execute('ALTER TABLE $table ADD COLUMN ${c.key} ${c.value}');
    }
  }
}
