import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../data/models/syncable.dart';
import '../../data/repositories/syncable_repository.dart';
import '../settings_service.dart';
import 'remote_store.dart';

enum SyncStatus { disabled, idle, syncing, synced, failed }

class SyncManager extends ChangeNotifier {
  // Pull slightly before the last sync to tolerate clock skew between devices.
  static const int _clockSkewMarginMs = 5 * 60 * 1000;

  final Repositories _repos;
  final SettingsService _settings;
  final RemoteStore? _remote;

  SyncStatus _status;
  String? _error;

  SyncManager(this._repos, this._settings, this._remote)
      : _status = _remote == null ? SyncStatus.disabled : SyncStatus.idle;

  SyncStatus get status => _status;
  String? get error => _error;
  bool get isEnabled => _remote != null;
  DateTime? get lastSyncAt => _settings.lastSyncAt == 0
      ? null
      : DateTime.fromMillisecondsSinceEpoch(_settings.lastSyncAt);

  /// Pushes local changes, then pulls remote ones. Returns true if local data
  /// changed. Failures (e.g. no internet) are recorded, never thrown.
  Future<bool> sync() async {
    final remote = _remote;
    if (remote == null || _status == SyncStatus.syncing) return false;
    _setStatus(SyncStatus.syncing);
    try {
      final startedAt = nowMs();
      final since = max(0, _settings.lastSyncAt - _clockSkewMarginMs);
      var applied = 0;
      for (final repo in _repos.all) {
        final dirty = await repo.getDirty();
        if (dirty.isNotEmpty) {
          await remote.push(repo.table, dirty);
          await repo.markClean(dirty);
        }
        applied += await repo.applyRemote(await remote.pullSince(repo.table, since));
      }
      await _settings.setLastSyncAt(startedAt);
      _error = null;
      _setStatus(SyncStatus.synced);
      return applied > 0;
    } catch (e) {
      _error = e.toString();
      debugPrint('Sync failed: $e');
      _setStatus(SyncStatus.failed);
      return false;
    }
  }

  void _setStatus(SyncStatus s) {
    _status = s;
    notifyListeners();
  }
}
