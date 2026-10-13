import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/units.dart';
import '../../services/settings_service.dart';
import 'bottom_sheet_picker.dart';

/// Currency and unit pickers, shared by onboarding and settings.
class UnitPreferencesFields extends StatelessWidget {
  static const double _gap = 16;

  final AppSettings value;
  final ValueChanged<AppSettings> onChanged;

  const UnitPreferencesFields({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.titleSmall;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BottomSheetPickerField<String>(
          label: 'Currency',
          value: value.currencyCode,
          searchable: true,
          options: [
            for (final c in kCurrencies)
              PickerOption(value: c.code, label: c.code, subtitle: c.name, badgeText: c.symbol),
          ],
          onChanged: (code) => onChanged(value.copyWith(currencyCode: code)),
        ),
        const SizedBox(height: _gap),
        Text('Distance', style: labelStyle),
        const SizedBox(height: 8),
        SegmentedButton<DistanceUnit>(
          segments: [
            for (final u in DistanceUnit.values)
              ButtonSegment(value: u, label: Text(u.displayName)),
          ],
          selected: {value.distanceUnit},
          onSelectionChanged: (s) => onChanged(value.copyWith(distanceUnit: s.first)),
        ),
        const SizedBox(height: _gap),
        Text('Fuel volume', style: labelStyle),
        const SizedBox(height: 8),
        SegmentedButton<VolumeUnit>(
          segments: [
            for (final u in VolumeUnit.values)
              ButtonSegment(value: u, label: Text(u.displayName)),
          ],
          selected: {value.volumeUnit},
          onSelectionChanged: (s) => onChanged(value.copyWith(volumeUnit: s.first)),
        ),
      ],
    );
  }
}
