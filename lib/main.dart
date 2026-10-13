import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'data/db/app_database.dart';
import 'data/repositories/syncable_repository.dart';
import 'services/settings_service.dart';
import 'services/sync/sync_manager.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final SyncManager sync;
  final AppState state;
  try {
    final settings = await SettingsService.create();
    final repos = Repositories(AppDatabase());
    // Pass a RemoteStore implementation here to turn on cloud sync.
    sync = SyncManager(repos, settings, null);
    state = AppState(repos, settings, sync);
    await state.init();
  } catch (error, stack) {
    // Without runApp the native splash never goes away, so show the error.
    debugPrint('Startup failed: $error\n$stack');
    runApp(StartupErrorApp(error: error));
    return;
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: state),
        ChangeNotifierProvider.value(value: sync),
      ],
      child: const FuelLogApp(),
    ),
  );
}
