import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers/core_providers.dart';
import 'core/router/app_router.dart';
import 'core/debug/navigation_observer.dart';
import 'core/debug/debug_overlay.dart';
import 'core/settings/settings_repository.dart';

class DebtManagerApp extends ConsumerStatefulWidget {
  const DebtManagerApp({super.key});

  @override
  ConsumerState<DebtManagerApp> createState() => _DebtManagerAppState();
}

class _DebtManagerAppState extends ConsumerState<DebtManagerApp> with WidgetsBindingObserver {
  final _settings = SettingsRepository();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Initialize notifier values from persisted preferences
    _settings.getThemeMode().then((m) => SettingsRepository.themeModeNotifier.value = m);
    _settings.getFontSize().then((f) => SettingsRepository.fontSizeNotifier.value = f);
    _settings.getCalendarType().then((c) => SettingsRepository.calendarTypeNotifier.value = c);
    _settings.getLanguage().then((l) => SettingsRepository.languageNotifier.value = l);
    _settings.getBiometricEnabled().then((b) {
      SettingsRepository.biometricEnabledNotifier.value = b;
      final auth = ref.read(authNotifierProvider);
      auth.tryUnlock();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(authNotifierProvider).lock();
      ref.read(authNotifierProvider).tryUnlock();
    }
  }

  @override
  Widget build(BuildContext context) {
    final goRouter = ref.read(goRouterProvider);

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: SettingsRepository.themeModeNotifier,
      builder: (context, themeMode, _) {
        return ValueListenableBuilder<FontSizeOption>(
          valueListenable: SettingsRepository.fontSizeNotifier,
          builder: (context, fontSize, _) {
            final fontScale = _settings.getFontScale(fontSize);

            const seed = Color(0xFF0D47A1);
            final lightScheme = ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light);
            final darkScheme = ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark);

            final baseTextTheme = Typography.material2021().black.apply(
              bodyColor: Colors.black87,
              displayColor: Colors.black87,
              fontSizeFactor: fontScale,
            );

            final lightTextTheme = baseTextTheme.copyWith(
              titleLarge: baseTextTheme.titleLarge?.copyWith(fontSize: 22 * fontScale, fontWeight: FontWeight.w700),
              titleMedium: baseTextTheme.titleMedium?.copyWith(fontSize: 18 * fontScale, fontWeight: FontWeight.w600),
              bodyMedium: baseTextTheme.bodyMedium?.copyWith(fontSize: 15 * fontScale),
              bodySmall: baseTextTheme.bodySmall?.copyWith(fontSize: 13 * fontScale),
            );

            final darkBase = Typography.material2021().white.apply(
              bodyColor: Colors.white70,
              displayColor: Colors.white70,
              fontSizeFactor: fontScale,
            );

            final darkTextTheme = darkBase.copyWith(
              titleLarge: darkBase.titleLarge?.copyWith(fontSize: 22 * fontScale, fontWeight: FontWeight.w700),
              titleMedium: darkBase.titleMedium?.copyWith(fontSize: 18 * fontScale, fontWeight: FontWeight.w600),
              bodyMedium: darkBase.bodyMedium?.copyWith(fontSize: 15 * fontScale),
              bodySmall: darkBase.bodySmall?.copyWith(fontSize: 13 * fontScale),
            );

            final lightTheme = ThemeData(
              useMaterial3: true,
              colorScheme: lightScheme,
              scaffoldBackgroundColor: lightScheme.surface,
              textTheme: lightTextTheme,
              appBarTheme: AppBarTheme(backgroundColor: lightScheme.surface, foregroundColor: lightScheme.onSurface, elevation: 1),
              listTileTheme: const ListTileThemeData(contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
              materialTapTargetSize: MaterialTapTargetSize.padded,
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: lightScheme.surfaceContainerHighest,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                floatingLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
              ),
            );

            final darkTheme = ThemeData(
              useMaterial3: true,
              colorScheme: darkScheme,
              scaffoldBackgroundColor: darkScheme.surface,
              textTheme: darkTextTheme,
              appBarTheme: AppBarTheme(backgroundColor: darkScheme.surface, foregroundColor: darkScheme.onSurface, elevation: 1),
              listTileTheme: const ListTileThemeData(contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
              materialTapTargetSize: MaterialTapTargetSize.padded,
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: darkScheme.surfaceContainerHighest,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                floatingLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
              ),
            );

            return MaterialApp.router(
              title: 'Debt Manager',
              debugShowCheckedModeBanner: false,
              theme: lightTheme,
              darkTheme: darkTheme,
              themeMode: themeMode,
              routerConfig: goRouter,
              // Add a navigator observer to log navigation events in debug.
              navigatorObservers: [LoggingNavigatorObserver()],
              // Inject debug overlay at the top-level so it wraps all routes.
              builder: (context, child) => DebugOverlay(child: child ?? const SizedBox.shrink()),
            );
          },
        );
      },
    );
  }
}
