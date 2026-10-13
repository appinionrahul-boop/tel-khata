import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'common.dart';
import 'glass.dart';

/// How each option is displayed in the picker.
class PickerOption<T> {
  final T value;
  final String label;
  final String? subtitle;
  final IconData? icon;
  // Short text shown in the badge when there is no icon (e.g. a currency symbol).
  final String? badgeText;

  const PickerOption({
    required this.value,
    required this.label,
    this.subtitle,
    this.icon,
    this.badgeText,
  });
}

class _OptionBadge extends StatelessWidget {
  static const double _size = 36;

  final PickerOption option;

  const _OptionBadge(this.option);

  @override
  Widget build(BuildContext context) {
    final icon = option.icon;
    if (icon != null) return GradientIconBadge(icon: icon, size: _size);
    return Container(
      width: _size,
      height: _size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: AppGradients.primary,
        borderRadius: BorderRadius.circular(_size * 0.3),
      ),
      child: FittedBox(
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Text(
            option.badgeText ?? option.label.characters.first,
            style: const TextStyle(color: AppColors.onAccent, fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }
}

/// Opens a glass bottom sheet listing [options]; resolves to the picked
/// value, or null if dismissed. [footer] is shown under the list (e.g. an
/// "Add" button) and can close the sheet itself.
Future<T?> showPickerSheet<T>({
  required BuildContext context,
  required String title,
  required List<PickerOption<T>> options,
  T? selected,
  bool searchable = false,
  Widget? footer,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.tint(AppColors.text),
    sheetAnimationStyle: AnimationStyle(
      duration: AppDurations.sheetIn,
      reverseDuration: AppDurations.sheetOut,
      curve: Curves.easeOutQuart,
    ),
    builder: (_) => _PickerSheet<T>(
      title: title,
      options: options,
      selected: selected,
      searchable: searchable,
      footer: footer,
    ),
  );
}

class _PickerSheet<T> extends StatefulWidget {
  final String title;
  final List<PickerOption<T>> options;
  final T? selected;
  final bool searchable;
  final Widget? footer;

  const _PickerSheet({
    required this.title,
    required this.options,
    required this.selected,
    required this.searchable,
    required this.footer,
  });

  @override
  State<_PickerSheet<T>> createState() => _PickerSheetState<T>();
}

class _PickerSheetState<T> extends State<_PickerSheet<T>> {
  static const double _handleWidth = 40;
  static const double _handleHeight = 4;
  static const double _maxHeightFactor = 0.75;

  String _query = '';

  List<PickerOption<T>> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return widget.options;
    return widget.options
        .where((o) =>
            o.label.toLowerCase().contains(q) ||
            (o.subtitle?.toLowerCase().contains(q) ?? false))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final media = MediaQuery.of(context);
    final options = _filtered;

    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: media.size.height * _maxHeightFactor),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.surface, AppColors.backgroundEnd],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: _handleWidth,
                  height: _handleHeight,
                  decoration: BoxDecoration(
                    gradient: AppGradients.primary,
                    borderRadius: BorderRadius.circular(_handleHeight / 2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(widget.title.toUpperCase(),
                    style: theme.textTheme.labelLarge?.copyWith(
                        letterSpacing: 1.5, fontWeight: FontWeight.w800, color: AppColors.primaryText)),
              ),
              if (widget.searchable)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: TextField(
                    onChanged: (v) => setState(() => _query = v),
                    decoration: const InputDecoration(
                      hintText: 'Search',
                      prefixIcon: Icon(Icons.search),
                      isDense: true,
                    ),
                  ),
                ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                  itemCount: options.length,
                  itemBuilder: (context, i) => FadeSlideIn(
                    index: i,
                    child: PressScale(
                      child: _OptionTile<T>(
                        option: options[i],
                        selected: options[i].value == widget.selected,
                        onTap: () => Navigator.pop(context, options[i].value),
                      ),
                    ),
                  ),
                ),
              ),
              if (widget.footer != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: widget.footer,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionTile<T> extends StatelessWidget {
  final PickerOption<T> option;
  final bool selected;
  final VoidCallback onTap;

  const _OptionTile({required this.option, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = option.subtitle;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: selected ? AppColors.tint(AppColors.primary) : AppColors.glassCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(
              color: selected ? AppColors.primary : AppColors.glassBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                _OptionBadge(option),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(option.label,
                          style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: selected ? AppColors.primaryText : null)),
                      if (subtitle != null)
                        Text(subtitle,
                            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
                    ],
                  ),
                ),
                if (selected) const Icon(Icons.check_circle, color: AppColors.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Dropdown-style form field that opens [showPickerSheet].
class BottomSheetPickerField<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<PickerOption<T>> options;
  final ValueChanged<T> onChanged;
  final bool searchable;

  const BottomSheetPickerField({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.searchable = false,
  });

  @override
  Widget build(BuildContext context) {
    final current = options.firstWhere((o) => o.value == value, orElse: () => options.first);
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: () async {
        final picked = await showPickerSheet<T>(
          context: context,
          title: label,
          options: options,
          selected: value,
          searchable: searchable,
        );
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Padding(
            padding: const EdgeInsets.all(8),
            child: _OptionBadge(current),
          ),
          suffixIcon: const Icon(Icons.expand_more, color: AppColors.primary),
        ),
        child: Text(
          current.subtitle == null ? current.label : '${current.label}  ·  ${current.subtitle}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
