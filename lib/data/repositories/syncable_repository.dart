import 'package:sqflite/sqflite.dart';

import '../db/app_database.dart';
import '../models/expense_entry.dart';
import '../models/fuel_entry.dart';
import '../models/syncable.dart';
import '../models/vehicle.dart';

/// Local storage for one synced table. Local writes are flagged `dirty` so the
/// sync manager knows what to push; remote rows are applied only if newer.
class SyncableRepository<T extends Syncable> {
  static const _dirty = 'dirty';

  final AppDatabase _appDb;
  final String table;
  final T Function(Map<String, Object?>) fromMap;
  final String orderBy;

  SyncableRepository(this._appDb, {required this.table, required this.fromMap, required this.orderBy});

  Future<List<T>> getActive({String? vehicleId}) async {
    final db = await _appDb.database;
    final rows = await db.query(
      table,
      where: vehicleId == null ? 'deleted = 0' : 'deleted = 0 AND vehicle_id = ?',
      whereArgs: vehicleId == null ? null : [vehicleId],
      orderBy: orderBy,
    );
    return rows.map(fromMap).toList();
  }

  Future<void> save(T record) async {
    final db = await _appDb.database;
    await db.insert(
      table,
      {...record.toMap(), _dirty: 1},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, Object?>>> getDirty() async {
    final db = await _appDb.database;
    final rows = await db.query(table, where: '$_dirty = 1');
    return rows.map((r) => Map<String, Object?>.of(r)..remove(_dirty)).toList();
  }

  Future<void> markClean(List<Map<String, Object?>> pushed) async {
    final db = await _appDb.database;
    final batch = db.batch();
    for (final row in pushed) {
      // Only clear rows not edited again while the push was in flight.
      batch.update(
        table,
        {_dirty: 0},
        where: 'id = ? AND updated_at = ?',
        whereArgs: [row['id'], row['updated_at']],
      );
    }
    await batch.commit(noResult: true);
  }

  Future<int> applyRemote(List<Map<String, Object?>> remoteRows) async {
    if (remoteRows.isEmpty) return 0;
    final db = await _appDb.database;
    var applied = 0;
    await db.transaction((txn) async {
      for (final remote in remoteRows) {
        final local = await txn.query(table,
            columns: ['updated_at'], where: 'id = ?', whereArgs: [remote['id']], limit: 1);
        final localUpdated = local.isEmpty ? -1 : local.first['updated_at'] as int;
        if ((remote['updated_at'] as int) > localUpdated) {
          await txn.insert(table, {...remote, _dirty: 0},
              conflictAlgorithm: ConflictAlgorithm.replace);
          applied++;
        }
      }
    });
    return applied;
  }
}

class Repositories {
  final SyncableRepository<Vehicle> vehicles;
  final SyncableRepository<FuelEntry> fuel;
  final SyncableRepository<ExpenseEntry> expenses;

  Repositories(AppDatabase db)
      : vehicles = SyncableRepository(db,
            table: Vehicle.table, fromMap: Vehicle.fromMap, orderBy: 'name COLLATE NOCASE'),
        fuel = SyncableRepository(db,
            table: FuelEntry.table,
            fromMap: FuelEntry.fromMap,
            orderBy: 'odometer_km DESC, date DESC'),
        expenses = SyncableRepository(db,
            table: ExpenseEntry.table, fromMap: ExpenseEntry.fromMap, orderBy: 'date DESC');

  List<SyncableRepository> get all => [vehicles, fuel, expenses];
}
