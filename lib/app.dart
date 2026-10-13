import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'state/app_state.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/onboarding_screen.dart';
import 'ui/theme/app_theme.dart';

class FuelLogApp extends StatefulWidget {
  const FuelLogApp({super.key});

  @override
  State<FuelLogApp> createState() => _FuelLogAppState();
}

class _FuelLogAppState extends State<FuelLogApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<AppState>().syncNow();
    }
  }

  @override
  Widget build(BuildContext context) {
    final onboarded = context.select<AppState, bool>((s) => s.settings.onboarded);
    return MaterialApp(
      title: 'Tel Khata',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: onboarded ? const HomeScreen() : const OnboardingScreen(),
    );
  }
}

/// Shown when startup fails so the app never hangs on the splash screen.
class StartupErrorApp extends StatelessWidget {
  final Object error;

  const StartupErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tel Khata',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                const SizedBox(height: 16),
                const Text('Tel Khata could not start',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                SelectableText('$error',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textMuted)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
