import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../data/models/syncable.dart';
import '../../data/models/vehicle.dart';
import '../../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/vehicle_fields.dart';

class VehicleFormScreen extends StatefulWidget {
  final Vehicle? vehicle;

  const VehicleFormScreen({super.key, this.vehicle});

  @override
  State<VehicleFormScreen> createState() => _VehicleFormScreenState();
}

class _VehicleFormScreenState extends State<VehicleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.vehicle?.name);
  late final _makeModel = TextEditingController(text: widget.vehicle?.makeModel);
  late final _registration = TextEditingController(text: widget.vehicle?.registrationNo);
  late VehicleType _type = widget.vehicle?.type ?? VehicleType.car;
  late FuelType _fuelType = widget.vehicle?.fuelType ?? FuelType.octane;

  bool get _isEdit => widget.vehicle != null;

  @override
  void dispose() {
    _name.dispose();
    _makeModel.dispose();
    _registration.dispose();
    super.dispose();
  }

  String? _optional(TextEditingController c) {
    final v = c.text.trim();
    return v.isEmpty ? null : v;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final state = context.read<AppState>();
    final vehicle = Vehicle(
      id: widget.vehicle?.id ?? AppState.newId(),
      name: _name.text.trim(),
      type: _type,
      fuelType: _fuelType,
      makeModel: _optional(_makeModel),
      registrationNo: _optional(_registration),
      updatedAt: nowMs(),
    );
    await state.saveVehicle(vehicle);
    if (!_isEdit) await state.selectVehicle(vehicle);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    if (!await confirmDelete(context, 'vehicle and all its records')) return;
    if (!mounted) return;
    await context.read<AppState>().deleteVehicle(widget.vehicle!);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit vehicle' : 'Add vehicle'),
        actions: [
          if (_isEdit) IconButton(onPressed: _delete, icon: const Icon(Icons.delete_outline)),
        ],
      ),
      body: AppBackground(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              VehicleFields(
                nameController: _name,
                makeModelController: _makeModel,
                registrationController: _registration,
                type: _type,
                fuelType: _fuelType,
                onTypeChanged: (t) => setState(() => _type = t),
                onFuelTypeChanged: (f) => setState(() => _fuelType = f),
              ),
              const SizedBox(height: 24),
              PrimaryButton(label: 'Save', onPressed: _save),
            ],
          ),
        ),
      ),
    );
  }
}
