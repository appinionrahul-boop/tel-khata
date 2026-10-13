import 'package:flutter/material.dart';

import '../../core/constants.dart';
import 'bottom_sheet_picker.dart';
import 'common.dart';

/// Vehicle name/type/fuel fields shared by onboarding and the vehicle form.
class VehicleFields extends StatelessWidget {
  static const double _gap = 16;

  final TextEditingController nameController;
  final TextEditingController? makeModelController;
  final TextEditingController? registrationController;
  final VehicleType type;
  final FuelType fuelType;
  final ValueChanged<VehicleType> onTypeChanged;
  final ValueChanged<FuelType> onFuelTypeChanged;

  const VehicleFields({
    super.key,
    required this.nameController,
    this.makeModelController,
    this.registrationController,
    required this.type,
    required this.fuelType,
    required this.onTypeChanged,
    required this.onFuelTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: nameController,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
              labelText: 'Vehicle name', hintText: 'e.g. My Corolla'),
          validator: requiredText,
        ),
        const SizedBox(height: _gap),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final t in VehicleType.values)
              ChoiceChip(
                avatar: Icon(t.icon, size: 18),
                label: Text(t.displayName),
                selected: t == type,
                onSelected: (_) => onTypeChanged(t),
              ),
          ],
        ),
        const SizedBox(height: _gap),
        BottomSheetPickerField<FuelType>(
          label: 'Fuel type',
          value: fuelType,
          options: [
            for (final f in FuelType.values)
              PickerOption(value: f, label: f.displayName, icon: f.icon),
          ],
          onChanged: onFuelTypeChanged,
        ),
        if (makeModelController != null) ...[
          const SizedBox(height: _gap),
          TextFormField(
            controller: makeModelController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Make & model (optional)'),
          ),
        ],
        if (registrationController != null) ...[
          const SizedBox(height: _gap),
          TextFormField(
            controller: registrationController,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(labelText: 'Registration no. (optional)'),
          ),
        ],
      ],
    );
  }
}
