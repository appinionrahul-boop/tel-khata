import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/bottom_sheet_picker.dart';
import '../widgets/common.dart';
import '../widgets/glass.dart';
import 'dashboard_tab.dart';
import 'expense_form_screen.dart';
import 'expense_list_tab.dart';
import 'fuel_form_screen.dart';
import 'fuel_list_tab.dart';
import 'settings_tab.dart';
import 'vehicle_form_screen.dart';

enum _AddAction { fillUp, expense, oilChange }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  static const _dashboard = 0;
  static const _fuel = 1;
  static const _expenses = 2;
  static const _settings = 3;

  static const _tabCount = 4;
  static const double _tabSlideOffset = 0.02;

  int _tab = _dashboard;
  // Tabs are built on first visit and then kept alive, so switching is instant.
  final Set<int> _visited = {_dashboard};

  late final AnimationController _tabAnimation =
      AnimationController(vsync: this, duration: AppDurations.medium, value: 1);
  late final Animation<double> _tabFade =
      CurvedAnimation(parent: _tabAnimation, curve: Curves.easeOutCubic);
  late final Animation<Offset> _tabSlide =
      Tween(begin: const Offset(0, _tabSlideOffset), end: Offset.zero).animate(_tabFade);

  @override
  void dispose() {
    _tabAnimation.dispose();
    super.dispose();
  }

  void _open(Widget screen) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

  void _selectTab(int i) {
    if (i == _tab) return;
    HapticFeedback.selectionClick();
    setState(() {
      _tab = i;
      _visited.add(i);
    });
    _tabAnimation.forward(from: 0);
  }

  Future<void> _openAddMenu(AppState state) async {
    HapticFeedback.lightImpact();
    if (state.selectedVehicle == null) {
      _open(const VehicleFormScreen());
      return;
    }
    final picked = await showPickerSheet<_AddAction>(
      context: context,
      title: 'Add new',
      options: const [
        PickerOption(
            value: _AddAction.fillUp,
            label: 'Fill-up',
            subtitle: 'Fuel, price and odometer',
            icon: Icons.local_gas_station),
        PickerOption(
            value: _AddAction.expense,
            label: 'Expense',
            subtitle: 'Service, repair, tolls and more',
            icon: Icons.receipt_long),
        PickerOption(
            value: _AddAction.oilChange,
            label: 'Engine oil change',
            subtitle: 'Brand and run capacity',
            icon: Icons.oil_barrel),
      ],
    );
    if (!mounted || picked == null) return;
    _open(switch (picked) {
      _AddAction.fillUp => const FuelFormScreen(),
      _AddAction.expense => const ExpenseFormScreen(),
      _AddAction.oilChange => const ExpenseFormScreen(initialCategory: ExpenseCategory.engineOil),
    });
  }

  Future<void> _switchVehicle(AppState state) async {
    final selected = state.selectedVehicle!;
    final picked = await showPickerSheet<String>(
      context: context,
      title: 'Switch vehicle',
      selected: selected.id,
      options: [
        for (final v in state.vehicles)
          PickerOption(
            value: v.id,
            label: v.name,
            subtitle: [v.fuelType.displayName, if (v.makeModel != null) v.makeModel!].join('  ·  '),
            icon: v.type.icon,
          ),
      ],
      footer: Builder(
        builder: (sheetContext) => OutlinedButton.icon(
          onPressed: () {
            Navigator.pop(sheetContext);
            _open(const VehicleFormScreen());
          },
          icon: const Icon(Icons.add),
          label: const Text('Add vehicle'),
        ),
      ),
    );
    if (picked != null && picked != selected.id) {
      await state.selectVehicle(state.vehicles.firstWhere((v) => v.id == picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final vehicle = state.selectedVehicle;
    final shown = _tab == _settings ? null : vehicle;

    final body = IndexedStack(
      index: _tab,
      children: [
        for (var i = 0; i < _tabCount; i++)
          TickerMode(
            enabled: i == _tab,
            child: _visited.contains(i) ? _tabBody(i, vehicle != null) : const SizedBox.shrink(),
          ),
      ],
    );

    return Scaffold(
      extendBody: true,
      body: AppBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _Header(
                icon: shown != null ? shown.type.icon : Icons.local_gas_station,
                title: shown != null ? shown.name : (_tab == _settings ? 'Settings' : 'Tel Khata'),
                subtitle: shown != null
                    ? (shown.makeModel ?? shown.fuelType.displayName)
                    : 'Fuel & mileage log',
                onSwitch: shown != null ? () => _switchVehicle(state) : null,
              ),
              Expanded(
                child: FadeTransition(
                  opacity: _tabFade,
                  child: SlideTransition(position: _tabSlide, child: body),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _GlassNavBar(
        selected: _tab,
        onSelect: _selectTab,
        onAdd: () => _openAddMenu(state),
      ),
    );
  }

  Widget _tabBody(int tab, bool hasVehicle) {
    if (!hasVehicle && tab != _settings) {
      return EmptyState(
        icon: Icons.directions_car,
        title: 'No vehicle yet',
        message: 'Add a vehicle to start logging fuel and expenses.',
        actionLabel: 'Add vehicle',
        onAction: () => _open(const VehicleFormScreen()),
      );
    }
    return switch (tab) {
      _fuel => const FuelListTab(),
      _expenses => const ExpenseListTab(),
      _settings => const SettingsTab(),
      _ => const DashboardTab(),
    };
  }
}

class _Header extends StatelessWidget {
  static const double _avatarSize = 52;

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onSwitch;

  const _Header({required this.icon, required this.title, required this.subtitle, this.onSwitch});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Container(
            width: _avatarSize,
            height: _avatarSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.glassStrong,
              border: Border.all(color: AppColors.glassBorder, width: 2),
            ),
            child: Center(child: GradientIconBadge(icon: icon, size: _avatarSize - 16)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onSwitch,
              child: AnimatedSwitcher(
                duration: AppDurations.medium,
                child: Column(
                  key: ValueKey(title),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                    Text(subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
                  ],
                ),
              ),
            ),
          ),
          if (onSwitch != null)
            GlassCircleButton(icon: Icons.swap_horiz_rounded, tooltip: 'Switch vehicle', onPressed: onSwitch!),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const _NavItem(this.icon, this.selectedIcon, this.label);
}

/// Floating frosted nav bar with a raised add button in the middle.
class _GlassNavBar extends StatelessWidget {
  static const double _height = 72;
  static const double _addSize = 60;
  static const double _raise = 20;

  static const _items = [
    _NavItem(Icons.insights_outlined, Icons.insights, 'Dashboard'),
    _NavItem(Icons.local_gas_station_outlined, Icons.local_gas_station, 'Fuel'),
    _NavItem(Icons.receipt_long_outlined, Icons.receipt_long, 'Expenses'),
    _NavItem(Icons.settings_outlined, Icons.settings, 'Settings'),
  ];

  final int selected;
  final ValueChanged<int> onSelect;
  final VoidCallback onAdd;

  const _GlassNavBar({required this.selected, required this.onSelect, required this.onAdd});

  Widget _button(int i) => Expanded(
        child: _NavButton(item: _items[i], selected: i == selected, onTap: () => onSelect(i)),
      );

  @override
  Widget build(BuildContext context) {
    final half = _items.length ~/ 2;
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: SizedBox(
        height: _height + _raise,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: _height,
              child: GlassCard(
                blur: true,
                radius: AppRadius.xl,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Material(
                  type: MaterialType.transparency,
                  child: Row(
                    children: [
                      for (var i = 0; i < half; i++) _button(i),
                      const SizedBox(width: _addSize + 16),
                      for (var i = half; i < _items.length; i++) _button(i),
                    ],
                  ),
                ),
              ),
            ),
            _AddButton(size: _addSize, onTap: onAdd),
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _NavButton({required this.item, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primaryText : AppColors.textMuted;
    return Semantics(
      selected: selected,
      button: true,
      label: item.label,
      child: PressScale(
        child: InkResponse(
          onTap: onTap,
          radius: AppRadius.xl,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: AppDurations.medium,
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: selected ? AppColors.tint(AppColors.primary) : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(selected ? item.selectedIcon : item.icon, color: color),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: AppDurations.medium,
                style: Theme.of(context).textTheme.labelSmall!.copyWith(
                      color: color,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                    ),
                child: Text(item.label, maxLines: 1, overflow: TextOverflow.fade, softWrap: false),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  static const double _shadowBlur = 20;
  static const Offset _shadowOffset = Offset(0, 8);

  final double size;
  final VoidCallback onTap;

  const _AddButton({required this.size, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return PressScale(
      child: Tooltip(
        message: 'Add',
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppGradients.primary,
            border: Border.all(color: AppColors.backgroundMid, width: 4),
            boxShadow: [
              BoxShadow(color: AppColors.glow, blurRadius: _shadowBlur, offset: _shadowOffset),
            ],
          ),
          child: Material(
            type: MaterialType.transparency,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: Icon(Icons.add_rounded, color: AppColors.onAccent, size: size / 2),
            ),
          ),
        ),
      ),
    );
  }
}
