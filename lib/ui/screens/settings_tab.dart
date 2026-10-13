import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/formatters.dart';
import '../../services/sync/sync_manager.dart';
import '../../state/app_state.dart';
import '../widgets/common.dart';
import '../widgets/glass.dart';
import '../widgets/unit_preferences_fields.dart';
import 'vehicle_form_screen.dart';

class SettingsTab extends StatelessWidget {
  static const double _gap = 16;

  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    final sections = [
      SectionCard(
        title: 'Currency & units',
        child: UnitPreferencesFields(value: state.settings, onChanged: state.updateSettings),
      ),
      SectionCard(
        title: 'Vehicles',
        child: Column(
          children: [
            for (final v in state.vehicles)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: GradientIconBadge(icon: v.type.icon),
                title: Text(v.name),
                subtitle: Text([
                  v.fuelType.displayName,
                  if (v.makeModel != null) v.makeModel!,
                  if (v.registrationNo != null) v.registrationNo!,
                ].join('  ·  ')),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => VehicleFormScreen(vehicle: v))),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => const VehicleFormScreen())),
                icon: const Icon(Icons.add),
                label: const Text('Add vehicle'),
              ),
            ),
          ],
        ),
      ),
      const _SyncCard(),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, kNavBarClearance),
      children: [
        for (var i = 0; i < sections.length; i++) ...[
          if (i > 0) const SizedBox(height: _gap),
          FadeSlideIn(index: i, child: sections[i]),
        ],
      ],
    );
  }
}

class _SyncCard extends StatelessWidget {
  const _SyncCard();

  @override
  Widget build(BuildContext context) {
    final sync = context.watch<SyncManager>();
    final last = sync.lastSyncAt;

    final (IconData icon, String text) = switch (sync.status) {
      SyncStatus.disabled => (Icons.cloud_off, 'Cloud sync is not set up. Data is saved on this phone.'),
      SyncStatus.idle => (Icons.cloud_queue, 'Waiting to sync.'),
      SyncStatus.syncing => (Icons.cloud_sync, 'Syncing...'),
      SyncStatus.synced => (Icons.cloud_done, 'Up to date.'),
      SyncStatus.failed => (Icons.cloud_off, 'Could not sync. Will retry when online.'),
    };

    return SectionCard(
      title: 'Cloud sync',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(icon),
            title: Text(text),
            subtitle: last == null ? null : Text('Last synced ${Formatters.date.format(last)}'),
          ),
          if (sync.isEnabled)
            FilledButton.tonalIcon(
              onPressed: sync.status == SyncStatus.syncing
                  ? null
                  : () => context.read<AppState>().syncNow(),
              icon: const Icon(Icons.sync),
              label: const Text('Sync now'),
            ),
        ],
      ),
    );
  }
}
