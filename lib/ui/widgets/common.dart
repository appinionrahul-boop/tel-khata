import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'glass.dart';

class GradientIconBadge extends StatelessWidget {
  static const double defaultSize = 40;
  static const double _glowBlur = 16;
  static const Offset _glowOffset = Offset(0, 6);

  final IconData icon;
  final double size;
  final Gradient gradient;
  // Blurred shadows are costly; keep off for list rows.
  final bool glow;

  const GradientIconBadge({
    super.key,
    required this.icon,
    this.size = defaultSize,
    this.gradient = AppGradients.primary,
    this.glow = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(size * 0.3),
        boxShadow: glow
            ? [BoxShadow(color: AppColors.glow, blurRadius: _glowBlur, offset: _glowOffset)]
            : null,
      ),
      child: Icon(icon, size: size * 0.5, color: AppColors.onAccent),
    );
  }
}

class EmptyState extends StatelessWidget {
  static const double _badgeSize = 88;

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, kNavBarClearance),
        child: FadeSlideIn(
          child: GlassCard(
            padding: const EdgeInsets.all(32),
            radius: AppRadius.xl,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GradientIconBadge(icon: icon, size: _badgeSize, glow: true),
                const SizedBox(height: 24),
                Text(title,
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                    textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(message,
                    style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
                    textAlign: TextAlign.center),
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: 24),
                  PressScale(
                    child: FilledButton.icon(
                      onPressed: onAction,
                      icon: const Icon(Icons.add),
                      label: Text(actionLabel!),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Small glass tile with an icon badge, a label and a value.
class StatCard extends StatelessWidget {
  static const double _badgeSize = 36;

  final String label;
  final Widget value;
  final IconData icon;
  final Gradient gradient;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.gradient = AppGradients.primary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      padding: const EdgeInsets.all(12),
      radius: AppRadius.md,
      child: Row(
        children: [
          GradientIconBadge(icon: icon, size: _badgeSize, gradient: gradient),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(color: AppColors.textMuted)),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: DefaultTextStyle.merge(
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                    child: value,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  const SectionCard({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(16, 16, 16, 12),
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800)),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

/// Full-width main action button with press feedback.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const PrimaryButton({super.key, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return PressScale(
      child: FilledButton(
        onPressed: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(label),
        ),
      ),
    );
  }
}

Future<bool> confirmDelete(BuildContext context, String what) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Delete $what?'),
      content: const Text('This cannot be undone.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
      ],
    ),
  );
  return result ?? false;
}

String? requiredText(String? v) => (v == null || v.trim().isEmpty) ? 'Required' : null;

String? positiveNumber(String? v) {
  final n = double.tryParse(v?.trim() ?? '');
  if (n == null) return 'Enter a number';
  if (n <= 0) return 'Must be greater than 0';
  return null;
}

String? optionalNonNegative(String? v) {
  if (v == null || v.trim().isEmpty) return null;
  final n = double.tryParse(v.trim());
  if (n == null || n < 0) return 'Enter a valid number';
  return null;
}

class DateField extends StatelessWidget {
  final DateTime value;
  final ValueChanged<DateTime> onChanged;
  final String Function(DateTime) format;

  const DateField({super.key, required this.value, required this.onChanged, required this.format});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
        );
        if (picked != null) {
          onChanged(DateTime(picked.year, picked.month, picked.day, value.hour, value.minute));
        }
      },
      child: InputDecorator(
        decoration: const InputDecoration(
            labelText: 'Date', suffixIcon: Icon(Icons.calendar_today)),
        child: Text(format(value)),
      ),
    );
  }
}

class DeleteBackground extends StatelessWidget {
  const DeleteBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      color: scheme.errorContainer,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Icon(Icons.delete, color: scheme.onErrorContainer),
    );
  }
}
