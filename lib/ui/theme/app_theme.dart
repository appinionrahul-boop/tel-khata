import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppColors {
  static const background = Color(0xFF2E3136);
  static const backgroundMid = Color(0xFF26292D);
  static const backgroundEnd = Color(0xFF1C1E21);
  static const surface = Color(0xFF33363C);
  static const primary = Color(0xFFEC4C8A);
  static const primaryLight = Color(0xFFF77FAE);
  static const primaryText = Color(0xFFF7709F);
  static const primaryDark = Color(0xFFB8285D);
  static const secondary = Color(0xFF8E6CF0);
  static const secondaryLight = Color(0xFFB49CFF);
  static const amber = Color(0xFFFBBF24);
  static const success = Color(0xFF34D399);
  static const error = Color(0xFFFF5C6C);
  static const text = Color(0xFFEDEFF3);
  static const textMuted = Color(0xFF8D939E);
  static const onAccent = Colors.white;

  // Alpha values (0-255) for smoked glass layers on the dark backdrop.
  static const int glassAlpha = 14;
  static const int glassCardAlpha = 16;
  static const int glassSheenAlpha = 26;
  static const int glassClearAlpha = 6;
  static const int glassStrongAlpha = 20;
  static const int glassBorderAlpha = 22;
  static const int dividerAlpha = 18;
  static const int highlightAlpha = 12;
  static const int tintAlpha = 40;
  static const int glowAlpha = 110;
  static const int shadowAlpha = 140;

  static Color get glass => Colors.white.withAlpha(glassAlpha);
  static Color get glassCard => Colors.white.withAlpha(glassCardAlpha);
  static Color get glassSheen => Colors.white.withAlpha(glassSheenAlpha);
  static Color get glassClear => Colors.white.withAlpha(glassClearAlpha);
  static Color get glassStrong => Colors.white.withAlpha(glassStrongAlpha);
  static Color get glassBorder => Colors.white.withAlpha(glassBorderAlpha);
  static Color get divider => Colors.white.withAlpha(dividerAlpha);
  // Neumorphic pair: dark drop shadow bottom-right, faint light edge top-left.
  static Color get shadow => Colors.black.withAlpha(shadowAlpha);
  static Color get highlight => Colors.white.withAlpha(highlightAlpha);
  static Color get glow => primary.withAlpha(glowAlpha);
  static Color tint(Color c) => c.withAlpha(tintAlpha);
}

class AppGradients {
  static const primary = LinearGradient(
    colors: [AppColors.primaryLight, AppColors.primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const accent = LinearGradient(
    colors: [AppColors.secondaryLight, AppColors.secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const background = LinearGradient(
    colors: [AppColors.background, AppColors.backgroundMid, AppColors.backgroundEnd],
    stops: [0, 0.5, 1],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

class AppGlass {
  // Bright top-left sheen fading to clear glass, like light on frosted panes.
  static LinearGradient get fill => LinearGradient(
        colors: [AppColors.glassSheen, AppColors.glassClear],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get blurFill => LinearGradient(
        colors: [AppColors.glassCard, AppColors.glassClear],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
}

class AppRadius {
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

class AppDurations {
  static const fast = Duration(milliseconds: 180);
  static const medium = Duration(milliseconds: 320);
  static const slow = Duration(milliseconds: 700);
  static const sheetIn = Duration(milliseconds: 420);
  static const sheetOut = Duration(milliseconds: 260);
}

class AppTheme {
  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
    ).copyWith(
      primary: AppColors.primary,
      onPrimary: AppColors.onAccent,
      secondary: AppColors.secondary,
      tertiary: AppColors.secondary,
      error: AppColors.error,
      surface: AppColors.background,
      onSurface: AppColors.text,
      onSurfaceVariant: AppColors.textMuted,
      surfaceContainerHighest: AppColors.glassStrong,
      outline: AppColors.divider,
    );

    final base = ThemeData(useMaterial3: true, colorScheme: scheme, brightness: Brightness.dark);
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md));
    OutlineInputBorder inputBorder(Color color, [double width = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: color, width: width),
        );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      // Soft expanding ripple instead of the sharper default sparkle.
      splashFactory: InkRipple.splashFactory,
      splashColor: AppColors.tint(AppColors.primary),
      highlightColor: AppColors.glassClear,
      textTheme: base.textTheme.apply(bodyColor: AppColors.text, displayColor: AppColors.text),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: AppColors.backgroundEnd,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: TextStyle(
            fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 0.6, color: AppColors.text),
      ),
      cardTheme: CardThemeData(
        color: AppColors.glassCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: AppColors.glassBorder),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.glassStrong,
        border: inputBorder(AppColors.glassBorder),
        enabledBorder: inputBorder(AppColors.glassBorder),
        focusedBorder: inputBorder(AppColors.primary, 2),
        errorBorder: inputBorder(AppColors.error),
        focusedErrorBorder: inputBorder(AppColors.error, 2),
        labelStyle: const TextStyle(color: AppColors.textMuted),
        floatingLabelStyle: const TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.w600),
        helperStyle: const TextStyle(color: AppColors.textMuted),
        prefixIconColor: AppColors.primary,
        suffixIconColor: AppColors.primary,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onAccent,
          shape: shape,
          elevation: 0,
          textStyle: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.4),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryText,
          backgroundColor: AppColors.glass,
          side: BorderSide(color: AppColors.glassBorder),
          shape: shape,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.primaryText, shape: shape),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: AppColors.primaryText),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColors.glassStrong,
        selectedColor: AppColors.tint(AppColors.primary),
        labelStyle: const TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.w600),
        side: BorderSide(color: AppColors.glassBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.selected) ? AppColors.primary : AppColors.glassStrong),
          foregroundColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.selected) ? AppColors.onAccent : AppColors.textMuted),
          iconColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.selected) ? AppColors.onAccent : AppColors.textMuted),
          side: WidgetStatePropertyAll(BorderSide(color: AppColors.glassBorder)),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll(Colors.white),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? AppColors.primary : AppColors.divider),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.primary),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      ),
      dividerTheme: DividerThemeData(color: AppColors.divider, space: 1),
      listTileTheme: const ListTileThemeData(iconColor: AppColors.primary),
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: FadeSlidePageTransitionsBuilder(),
        TargetPlatform.iOS: FadeSlidePageTransitionsBuilder(),
      }),
    );
  }
}

/// New page fades and glides up while the page behind eases back a little.
/// Only fade, slide and scale are used, so it stays smooth on low-end devices.
class FadeSlidePageTransitionsBuilder extends PageTransitionsBuilder {
  static const double _slideOffset = 0.06;
  static const double _exitScale = 0.95;

  static final Animatable<double> _ease = CurveTween(curve: Curves.easeOutQuart);
  static final Animatable<Offset> _slide =
      Tween(begin: const Offset(0, _slideOffset), end: Offset.zero).chain(_ease);
  static final Animatable<double> _exit = Tween(begin: 1.0, end: _exitScale).chain(_ease);

  const FadeSlidePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return ScaleTransition(
      scale: secondaryAnimation.drive(_exit),
      child: FadeTransition(
        opacity: animation.drive(_ease),
        child: SlideTransition(position: animation.drive(_slide), child: child),
      ),
    );
  }
}

/// Charcoal gradient backdrop behind the frosted cards.
/// Static, so it is painted once and cached.
class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(
          child: RepaintBoundary(
            child: DecoratedBox(decoration: BoxDecoration(gradient: AppGradients.background)),
          ),
        ),
        Positioned.fill(child: child),
      ],
    );
  }
}
