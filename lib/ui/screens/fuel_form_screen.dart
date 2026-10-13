import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/units.dart';
import '../../data/models/fuel_entry.dart';
import '../../data/models/syncable.dart';
import '../../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/glass.dart';

class FuelFormScreen extends StatefulWidget {
  final FuelEntry? entry;

  const FuelFormScreen({super.key, this.entry});

  @override
  State<FuelFormScreen> createState() => _FuelFormScreenState();
}

class _FuelFormScreenState extends State<FuelFormScreen> {
  static const double _gap = 16;
  static final _decimal = FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,3}'));

  final _formKey = GlobalKey<FormState>();
  final _distance = TextEditingController();
  final _volume = TextEditingController();
  final _price = TextEditingController();
  final _total = TextEditingController();
  final _station = TextEditingController();
  final _note = TextEditingController();

  late final AppState _state = context.read<AppState>();
  late DateTime _date;
  late bool _fullTank;
  late bool _missedPrevious;
  double? _lastOdometerKm;
  double? _previousFillOdometerKm;
  bool _useTrip = false;

  bool get _isEdit => widget.entry != null;

  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    final units = _state.units;
    _date = e?.date ?? DateTime.now();
    _fullTank = e?.fullTank ?? true;
    _missedPrevious = e?.missedPrevious ?? false;
    if (e != null) {
      _distance.text = Formatters.trimNumber(units.distanceFromKm(e.odometerKm));
      _previousFillOdometerKm = _state.fuelEntries
          .where((f) => f.id != e.id && f.odometerKm < e.odometerKm)
          .map((f) => f.odometerKm)
          .fold<double?>(null, (max, o) => max == null || o > max ? o : max);
      _volume.text = Formatters.trimNumber(units.volumeFromLiters(e.liters));
      _price.text = Formatters.trimNumber(units.pricePerVolumeFromPerLiter(e.pricePerLiter));
      _total.text = Formatters.trimNumber(e.totalCost);
      _station.text = e.station ?? '';
      _note.text = e.note ?? '';
    } else {
      _lastOdometerKm = _state.latestOdometerKm;
      final fuel = _state.fuelEntries;
      if (fuel.isNotEmpty) {
        _previousFillOdometerKm = fuel.first.odometerKm;
        _useTrip = _state.useTripInput;
        _price.text =
            Formatters.trimNumber(units.pricePerVolumeFromPerLiter(fuel.first.pricePerLiter));
      }
    }
  }

  @override
  void dispose() {
    for (final c in [_distance, _volume, _price, _total, _station, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  double? _num(TextEditingController c) => double.tryParse(c.text.trim());

  void _onVolumeOrPriceChanged(String _) {
    final volume = _num(_volume);
    final price = _num(_price);
    if (volume != null && price != null) {
      _total.text = Formatters.trimNumber(volume * price);
    }
  }

  void _onTotalChanged(String _) {
    final total = _num(_total);
    final price = _num(_price);
    if (total != null && price != null && price > 0) {
      _volume.text = Formatters.trimNumber(total / price);
    }
  }

  bool get _canUseTrip => _previousFillOdometerKm != null;

  /// Total odometer in km from whichever reading the user typed.
  double? get _totalOdometerKm {
    final value = _num(_distance);
    if (value == null) return null;
    final km = _state.units.distanceToKm(value);
    final previous = _previousFillOdometerKm;
    return _useTrip && previous != null ? previous + km : km;
  }

  void _setTripMode(bool useTrip) {
    if (useTrip == _useTrip) return;
    final total = _totalOdometerKm;
    final previous = _previousFillOdometerKm;
    setState(() => _useTrip = useTrip);
    if (total != null && previous != null) {
      final km = useTrip ? total - previous : total;
      _distance.text = km > 0 ? Formatters.trimNumber(_state.units.distanceFromKm(km)) : '';
    }
    if (!_isEdit) _state.setUseTripInput(useTrip);
  }

  String? _validateDistance(String? v) {
    final basic = positiveNumber(v);
    if (basic != null || _useTrip) return basic;
    final last = _lastOdometerKm;
    if (last != null && _state.units.distanceToKm(double.parse(v!.trim())) <= last) {
      return 'Must be more than last reading (${_state.fmt.distance(last)})';
    }
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final units = _state.units;
    final station = _station.text.trim();
    final note = _note.text.trim();
    await _state.saveFuel(FuelEntry(
      id: widget.entry?.id ?? AppState.newId(),
      vehicleId: widget.entry?.vehicleId ?? _state.selectedVehicle!.id,
      date: _date,
      odometerKm: _totalOdometerKm!,
      liters: units.volumeToLiters(_num(_volume)!),
      totalCost: _num(_total)!,
      fullTank: _fullTank,
      missedPrevious: _missedPrevious,
      station: station.isEmpty ? null : station,
      note: note.isEmpty ? null : note,
      updatedAt: nowMs(),
    ));
    if (mounted) Navigator.pop(context);
  }

  String? _distanceHelper(double? lastOdo) {
    final fmt = _state.fmt;
    if (_useTrip) {
      final total = _totalOdometerKm;
      return total == null
          ? 'Previous fill-up at ${fmt.distance(_previousFillOdometerKm!)}'
          : 'Total odometer: ${fmt.distance(total)}';
    }
    if (!_canUseTrip && !_isEdit) return 'Trip meter is available from your second fill-up';
    return lastOdo == null ? null : 'Last: ${fmt.distance(lastOdo)}';
  }

  Future<void> _delete() async {
    if (!await confirmDelete(context, 'fill-up')) return;
    await _state.deleteFuel(widget.entry!);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final units = _state.units;
    final currency = _state.currency.symbol;
    const numberKeyboard = TextInputType.numberWithOptions(decimal: true);
    final lastOdo = _lastOdometerKm;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit fill-up' : 'Add fill-up'),
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
              DateField(
                value: _date,
                format: Formatters.date.format,
                onChanged: (d) => setState(() => _date = d),
              ),
              const SizedBox(height: _gap),
              SegmentedButton<bool>(
                segments: [
                  const ButtonSegment(
                      value: false, icon: Icon(Icons.speed), label: Text('Odometer')),
                  ButtonSegment(
                    value: true,
                    icon: const Icon(Icons.route),
                    label: const Text('Trip meter'),
                    enabled: _canUseTrip,
                  ),
                ],
                selected: {_useTrip},
                onSelectionChanged: (s) => _setTripMode(s.first),
              ),
              const SizedBox(height: _gap),
              TextFormField(
                controller: _distance,
                keyboardType: numberKeyboard,
                inputFormatters: [_decimal],
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: _useTrip
                      ? 'Trip since last fill-up (${units.distanceUnit.label})'
                      : 'Odometer (${units.distanceUnit.label})',
                  helperText: _distanceHelper(lastOdo),
                ),
                validator: _validateDistance,
              ),
              const SizedBox(height: _gap),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _volume,
                      keyboardType: numberKeyboard,
                      inputFormatters: [_decimal],
                      decoration: InputDecoration(labelText: 'Fuel (${units.volumeUnit.label})'),
                      onChanged: _onVolumeOrPriceChanged,
                      validator: positiveNumber,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _price,
                      keyboardType: numberKeyboard,
                      inputFormatters: [_decimal],
                      decoration:
                          InputDecoration(labelText: 'Price ($currency/${units.volumeUnit.label})'),
                      onChanged: _onVolumeOrPriceChanged,
                      validator: positiveNumber,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: _gap),
              TextFormField(
                controller: _total,
                keyboardType: numberKeyboard,
                inputFormatters: [_decimal],
                decoration: InputDecoration(
                  labelText: 'Total cost ($currency)',
                  helperText: 'Filled automatically from fuel and price',
                ),
                onChanged: _onTotalChanged,
                validator: positiveNumber,
              ),
              const SizedBox(height: _gap),
              GlassCard(
                shadow: false,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Full tank'),
                      subtitle: const Text('Needed to calculate mileage'),
                      value: _fullTank,
                      onChanged: (v) => setState(() => _fullTank = v),
                    ),
                    const Divider(),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Missed previous fill-up'),
                      subtitle: const Text('Turn on if you forgot to log the last fill-up'),
                      value: _missedPrevious,
                      onChanged: (v) => setState(() => _missedPrevious = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: _gap),
              TextFormField(
                controller: _station,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Fuel station (optional)'),
              ),
              const SizedBox(height: _gap),
              TextFormField(
                controller: _note,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Note (optional)'),
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
