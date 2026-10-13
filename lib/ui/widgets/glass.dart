import 'dart:math';
import 'dart:ui';

import 'package:flutter/gestures.dart' show kTouchSlop;
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Space under scrolling content so the floating nav bar never covers it.
const double kNavBarClearance = 120;

/// Frosted white panel. Live [blur] is costly, so it is off by default and
/// only used on a few fixed surfaces such as the nav bar.
class GlassCard extends StatelessWidget {
  static const double _blurSigma = 16;
  static const double _shadowBlur = 24;
  static const double _highlightBlur = 16;
  static const Offset _shadowOffset = Offset(8, 8);
  static const Offset _highlightOffset = Offset(-6, -6);

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool blur;
  final bool shadow;
  final Color? borderColor;
  final double borderWidth;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = AppRadius.lg,
    this.blur = false,
    this.shadow = true,
    this.borderColor,
    this.borderWidth = 1.5,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);
    Widget content = Padding(padding: padding, child: child);
    if (onTap != null) {
      content = Material(
        type: MaterialType.transparency,
        child: InkWell(borderRadius: borderRadius, onTap: onTap, child: content),
      );
    }

    Widget panel = DecoratedBox(
      decoration: BoxDecoration(
        gradient: blur ? AppGlass.blurFill : AppGlass.fill,
        borderRadius: borderRadius,
        border: Border.all(color: borderColor ?? AppColors.glassBorder, width: borderWidth),
      ),
      child: content,
    );

    if (blur) {
      panel = ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: _blurSigma, sigmaY: _blurSigma),
          child: panel,
        ),
      );
    }

    if (shadow) {
      panel = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          boxShadow: [
            BoxShadow(color: AppColors.shadow, blurRadius: _shadowBlur, offset: _shadowOffset),
            BoxShadow(
                color: AppColors.highlight, blurRadius: _highlightBlur, offset: _highlightOffset),
          ],
        ),
        child: panel,
      );
    }

    return onTap == null ? panel : PressScale(child: panel);
  }
}

/// Gently shrinks its child while pressed, without taking over the tap.
/// Releases as soon as the finger starts scrolling.
class PressScale extends StatefulWidget {
  static const double _pressedScale = 0.95;

  final Widget child;

  const PressScale({super.key, required this.child});

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _pressed = false;
  Offset? _downAt;

  void _set(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  void _onMove(PointerMoveEvent e) {
    final start = _downAt;
    if (start != null && (e.position - start).distance > kTouchSlop) {
      _downAt = null;
      _set(false);
    }
  }

  void _release() {
    _downAt = null;
    _set(false);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (e) {
        _downAt = e.position;
        _set(true);
      },
      onPointerMove: _onMove,
      onPointerUp: (_) => _release(),
      onPointerCancel: (_) => _release(),
      child: AnimatedScale(
        scale: _pressed ? PressScale._pressedScale : 1,
        duration: AppDurations.fast,
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

/// Fades and slides its child up once when first shown. The first few
/// [index]es start a little later, giving a staggered entrance.
class FadeSlideIn extends StatefulWidget {
  static const int _maxStagger = 6;
  static const Duration _step = Duration(milliseconds: 60);
  static const Duration _duration = Duration(milliseconds: 420);
  static const double _offset = 0.08;

  final Widget child;
  final int index;

  const FadeSlideIn({super.key, required this.child, this.index = 0});

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    // Only the first screenful is staggered; rows scrolled in later appear at once.
    final staggered = widget.index <= FadeSlideIn._maxStagger;
    final delay = staggered ? FadeSlideIn._step * widget.index : Duration.zero;
    final total = delay + FadeSlideIn._duration;
    _controller = AnimationController(vsync: this, duration: total);
    final curve = CurvedAnimation(
      parent: _controller,
      curve: Interval(delay.inMilliseconds / total.inMilliseconds, 1, curve: Curves.easeOutCubic),
    );
    _fade = curve;
    _slide = Tween(begin: const Offset(0, FadeSlideIn._offset), end: Offset.zero).animate(curve);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

/// Text that counts up to [value] and animates smoothly when it changes.
class CountUpText extends StatelessWidget {
  final double? value;
  final String Function(double) format;
  final TextStyle? style;
  final String placeholder;

  const CountUpText({
    super.key,
    required this.value,
    required this.format,
    this.style,
    this.placeholder = '--',
  });

  @override
  Widget build(BuildContext context) {
    final target = value;
    if (target == null) return Text(placeholder, style: style);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: target),
      duration: AppDurations.slow,
      curve: Curves.easeOutCubic,
      builder: (_, v, __) => Text(format(v), style: style, maxLines: 1),
    );
  }
}

/// Circular gauge with a gradient arc and a knob at its end.
class RingProgress extends StatelessWidget {
  static const double defaultSize = 128;
  static const double defaultStroke = 14;

  final double fraction;
  final double size;
  final double stroke;
  final Color color;
  final Widget? center;

  const RingProgress({
    super.key,
    required this.fraction,
    this.size = defaultSize,
    this.stroke = defaultStroke,
    this.color = AppColors.primary,
    this.center,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: fraction.clamp(0.0, 1.0)),
        duration: AppDurations.slow,
        curve: Curves.easeOutCubic,
        builder: (_, v, child) => CustomPaint(
          painter: _RingPainter(fraction: v, stroke: stroke, color: color),
          child: child,
        ),
        child: Center(child: center),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  static const double _startAngle = -pi / 2;
  static const double _knobRatio = 0.7;

  final double fraction;
  final double stroke;
  final Color color;

  _RingPainter({required this.fraction, required this.stroke, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = color.withAlpha(AppColors.tintAlpha),
    );
    if (fraction <= 0) return;

    final sweep = 2 * pi * fraction;
    canvas.drawArc(
      rect,
      _startAngle,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          startAngle: 0,
          endAngle: 2 * pi,
          colors: [color.withAlpha(AppColors.glassAlpha), color],
          transform: const GradientRotation(_startAngle),
        ).createShader(rect),
    );

    final end = _startAngle + sweep;
    final knob = center + Offset(cos(end), sin(end)) * radius;
    canvas.drawCircle(knob, stroke * _knobRatio, Paint()..color = Colors.white);
    canvas.drawCircle(knob, stroke * _knobRatio / 2, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.fraction != fraction || old.color != color || old.stroke != stroke;
}

/// Thin slider-style bar with a knob, filled to [fraction].
class GlassProgressBar extends StatelessWidget {
  static const double _height = 8;
  static const double _knob = 16;

  final double fraction;
  final Gradient gradient;

  const GlassProgressBar({super.key, required this.fraction, this.gradient = AppGradients.primary});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _knob,
      child: LayoutBuilder(
        builder: (context, constraints) => TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: fraction.clamp(0.0, 1.0)),
          duration: AppDurations.slow,
          curve: Curves.easeOutCubic,
          builder: (_, v, __) {
            final filled = max(_knob, constraints.maxWidth * v);
            return Stack(
              alignment: Alignment.centerLeft,
              children: [
                Container(
                  height: _height,
                  decoration: BoxDecoration(
                    color: AppColors.glassStrong,
                    borderRadius: BorderRadius.circular(_height / 2),
                  ),
                ),
                Container(
                  width: filled,
                  height: _height,
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(_height / 2),
                  ),
                ),
                Positioned(
                  left: filled - _knob,
                  child: Container(
                    width: _knob,
                    height: _knob,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: gradient.colors.last, width: 4),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Round frosted button, like the menu button in the header.
class GlassCircleButton extends StatelessWidget {
  static const double defaultSize = 48;

  final IconData icon;
  final VoidCallback onPressed;
  final double size;
  final String? tooltip;

  const GlassCircleButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = defaultSize,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final button = PressScale(
      child: Material(
        color: AppColors.glassStrong,
        shape: CircleBorder(side: BorderSide(color: AppColors.glassBorder, width: 1.5)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(icon, color: AppColors.primaryText, size: size / 2),
          ),
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}
