import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/formatters.dart';
import '../../core/units.dart';
import '../../data/models/expense_entry.dart';
import '../../data/models/syncable.dart';
import '../../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/bottom_sheet_picker.dart';
import '../widgets/common.dart';

class ExpenseFormScreen extends StatefulWidget {
  final ExpenseEntry? entry;
  final ExpenseCategory initialCategory;

  const ExpenseFormScreen({
    super.key,
    this.entry,
    this.initialCategory = ExpenseCategory.service,
  });

  @override
  State<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends State<ExpenseFormScreen> {
  static const double _gap = 16;
  static final _decimal = FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'));
  static const _oilBrands = [
    'Mobil', 'Shell', 'Castrol', 'Total', 'Motul', 'Liqui Moly', 'Valvoline', 'Petronas', 'Caltex',
  ];
  static const _oilIntervalPresets = [2000.0, 3000.0, 5000.0, 7500.0, 10000.0];

  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _cost = TextEditingController();
  final _odometer = TextEditingController();
  final _note = TextEditingController();
  final _oilBrand = TextEditingController();
  final _oilGrade = TextEditingController();
  final _oilInterval = TextEditingController();
  final _oilQuantity = TextEditingController();

  late final AppState _state = context.read<AppState>();
  late DateTime _date;
  late ExpenseCategory _category;

  bool get _isEdit => widget.entry != null;
  bool get _isOil => _category == ExpenseCategory.engineOil;

  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    _date = e?.date ?? DateTime.now();
    _category = e?.category ?? widget.initialCategory;
    _fillOilFields(e ?? _state.oilReminder?.lastChange);
    if (e != null) {
      _title.text = e.title;
      _cost.text = Formatters.trimNumber(e.cost);
      final odo = e.odometerKm;
      if (odo != null) {
        _odometer.text = Formatters.trimNumber(_state.units.distanceFromKm(odo));
      }
      _note.text = e.note ?? '';
    } else {
      _title.text = _category.displayName;
      final latest = _state.latestOdometerKm;
      if (_isOil && latest != null) {
        _odometer.text = Formatters.trimNumber(_state.units.distanceFromKm(latest));
      }
    }
  }

  /// Prefills oil details from [source], usually the previous oil change.
  void _fillOilFields(ExpenseEntry? source) {
    if (source == null || !source.isOilChange) return;
    final units = _state.units;
    final interval = source.oilIntervalKm;
    final quantity = source.oilQuantityLiters;
    _oilBrand.text = source.oilBrand ?? '';
    _oilGrade.text = source.oilGrade ?? '';
    if (interval != null) _oilInterval.text = Formatters.trimNumber(units.distanceFromKm(interval));
    if (quantity != null) _oilQuantity.text = Formatters.trimNumber(quantity);
  }

  @override
  void dispose() {
    for (final c in [_title, _cost, _odometer, _note, _oilBrand, _oilGrade, _oilInterval, _oilQuantity]) {
      c.dispose();
    }
    super.dispose();
  }

  void _selectCategory(ExpenseCategory c) {
    // Keep a custom title; only replace the auto-filled category name.
    final autoTitle = _title.text.trim().isEmpty || _title.text == _category.displayName;
    setState(() => _category = c);
    if (autoTitle) _title.text = c.displayName;
    final latest = _state.latestOdometerKm;
    if (_isOil && _odometer.text.isEmpty && latest != null) {
      _odometer.text = Formatters.trimNumber(_state.units.distanceFromKm(latest));
    }
  }

  String? _optionalText(TextEditingController c) {
    final v = c.text.trim();
    return v.isEmpty ? null : v;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final units = _state.units;
    final odo = double.tryParse(_odometer.text.trim());
    final interval = double.tryParse(_oilInterval.text.trim());
    final quantity = double.tryParse(_oilQuantity.text.trim());
    final note = _note.text.trim();
    await _state.saveExpense(ExpenseEntry(
      id: widget.entry?.id ?? AppState.newId(),
      vehicleId: widget.entry?.vehicleId ?? _state.selectedVehicle!.id,
      date: _date,
      category: _category,
      title: _title.text.trim(),
      cost: double.parse(_cost.text.trim()),
      odometerKm: odo == null ? null : units.distanceToKm(odo),
      note: note.isEmpty ? null : note,
      oilBrand: _isOil ? _optionalText(_oilBrand) : null,
      oilGrade: _isOil ? _optionalText(_oilGrade) : null,
      oilIntervalKm: _isOil && interval != null ? units.distanceToKm(interval) : null,
      oilQuantityLiters: _isOil ? quantity : null,
      updatedAt: nowMs(),
    ));
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    if (!await confirmDelete(context, 'expense')) return;
    await _state.deleteExpense(widget.entry!);
    if (mounted) Navigator.pop(context);
  }

  List<Widget> _oilFields(TextInputType numberKeyboard) {
    final distanceLabel = _state.units.distanceUnit.label;
    Widget chips(List<String> values, TextEditingController target) => SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: values.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) => ActionChip(
              label: Text(values[i]),
              onPressed: () => setState(() => target.text = values[i]),
            ),
          ),
        );

    return [
      const SizedBox(height: _gap),
      TextFormField(
        controller: _oilBrand,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(labelText: 'Oil brand', prefixIcon: Icon(Icons.local_offer)),
        validator: requiredText,
      ),
      const SizedBox(height: 8),
      chips(_oilBrands, _oilBrand),
      const SizedBox(height: _gap),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TextFormField(
              controller: _oilGrade,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(labelText: 'Grade (optional)', hintText: '10W-40'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              controller: _oilQuantity,
              keyboardType: numberKeyboard,
              inputFormatters: [_decimal],
              decoration: const InputDecoration(labelText: 'Quantity (L, optional)'),
              validator: optionalNonNegative,
            ),
          ),
        ],
      ),
      const SizedBox(height: _gap),
      TextFormField(
        controller: _oilInterval,
        keyboardType: numberKeyboard,
        inputFormatters: [_decimal],
        decoration: InputDecoration(
          labelText: 'Oil run capacity ($distanceLabel)',
          helperText: 'Distance this oil lasts before the next change',
          prefixIcon: const Icon(Icons.av_timer),
        ),
        validator: positiveNumber,
      ),
      const SizedBox(height: 8),
      chips([for (final p in _oilIntervalPresets) Formatters.trimNumber(p)], _oilInterval),
    ];
  }

  @override
  Widget build(BuildContext context) {
    const numberKeyboard = TextInputType.numberWithOptions(decimal: true);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit expense' : 'Add expense'),
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
              BottomSheetPickerField<ExpenseCategory>(
                label: 'Category',
                value: _category,
                options: [
                  for (final c in ExpenseCategory.values)
                    PickerOption(value: c, label: c.displayName, icon: c.icon),
                ],
                onChanged: _selectCategory,
              ),
              const SizedBox(height: _gap),
              TextFormField(
                controller: _title,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: requiredText,
              ),
              const SizedBox(height: _gap),
              TextFormField(
                controller: _cost,
                keyboardType: numberKeyboard,
                inputFormatters: [_decimal],
                decoration: InputDecoration(labelText: 'Cost (${_state.currency.symbol})'),
                validator: positiveNumber,
              ),
              const SizedBox(height: _gap),
              DateField(
                value: _date,
                format: Formatters.date.format,
                onChanged: (d) => setState(() => _date = d),
              ),
              const SizedBox(height: _gap),
              TextFormField(
                controller: _odometer,
                keyboardType: numberKeyboard,
                inputFormatters: [_decimal],
                decoration: InputDecoration(
                    labelText: _isOil
                        ? 'Odometer at oil change (${_state.units.distanceUnit.label})'
                        : 'Odometer (${_state.units.distanceUnit.label}, optional)'),
                validator: _isOil ? positiveNumber : optionalNonNegative,
              ),
              if (_isOil) ..._oilFields(numberKeyboard),
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
