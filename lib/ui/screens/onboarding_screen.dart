import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../data/models/syncable.dart';
import '../../data/models/vehicle.dart';
import '../../services/settings_service.dart';
import '../../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/glass.dart';
import '../widgets/unit_preferences_fields.dart';
import '../widgets/vehicle_fields.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _logoAsset = 'assets/images/logo.png';
  static const double _logoSize = 96;
  static const double _logoRadius = 24;
  static const double _logoShadowBlur = 24;
  static const double _gap = 20;

  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  late AppSettings _prefs = context.read<AppState>().settings;
  VehicleType _type = VehicleType.car;
  FuelType _fuelType = FuelType.octane;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final state = context.read<AppState>();
    await state.saveVehicle(Vehicle(
      id: AppState.newId(),
      name: _name.text.trim(),
      type: _type,
      fuelType: _fuelType,
      updatedAt: nowMs(),
    ));
    await state.updateSettings(_prefs.copyWith(onboarded: true));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sections = [
      Column(
        children: [
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_logoRadius),
              boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: _logoShadowBlur)],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(_logoRadius),
              child: Image.asset(_logoAsset, width: _logoSize, height: _logoSize),
            ),
          ),
          const SizedBox(height: 16),
          Text('Welcome to Tel Khata',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text('Set your currency and units. You can change them later in Settings.',
              style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center),
        ],
      ),
      SectionCard(
        title: 'Currency & units',
        child: UnitPreferencesFields(
          value: _prefs,
          onChanged: (p) => setState(() => _prefs = p),
        ),
      ),
      SectionCard(
        title: 'Your first vehicle',
        child: VehicleFields(
          nameController: _name,
          type: _type,
          fuelType: _fuelType,
          onTypeChanged: (t) => setState(() => _type = t),
          onFuelTypeChanged: (f) => setState(() => _fuelType = f),
        ),
      ),
      PrimaryButton(label: 'Get started', onPressed: _saving ? null : _finish),
    ];

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                for (var i = 0; i < sections.length; i++) ...[
                  if (i > 0) const SizedBox(height: _gap),
                  FadeSlideIn(index: i, child: sections[i]),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
