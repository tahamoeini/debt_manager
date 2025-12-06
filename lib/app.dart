import 'package:flutter/material.dart';
import 'app_shell.dart';
import 'core/settings/settings_repository.dart';

class DebtManagerApp extends StatefulWidget {
  const DebtManagerApp({super.key});

  @override
  State<DebtManagerApp> createState() => _DebtManagerAppState();
}

class _DebtManagerAppState extends State<DebtManagerApp> {
  final _settings = SettingsRepository();

  @override
  void initState() {
    super.initState();
    // Initialize notifier value from persisted preference
    _settings.getThemeMode().then((m) => SettingsRepository.themeModeNotifier.value = m);
  }

  @override
  Widget build(BuildContext context) {
    // Use ValueListenableBuilder so settings changes propagate immediately.
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: SettingsRepository.themeModeNotifier,
      builder: (context, themeMode, _) {
        // Seed colors: calming blue for primary
        const seed = Color(0xFF0D47A1);

        final lightScheme = ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light);
        final darkScheme = ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark);

        final baseTextTheme = Typography.material2021().black.apply(
          bodyColor: Colors.black87,
          displayColor: Colors.black87,
        );

        final lightTextTheme = baseTextTheme.copyWith(
          titleLarge: baseTextTheme.titleLarge?.copyWith(fontSize: 22, fontWeight: FontWeight.w700),
          titleMedium: baseTextTheme.titleMedium?.copyWith(fontSize: 18, fontWeight: FontWeight.w600),
          bodyMedium: baseTextTheme.bodyMedium?.copyWith(fontSize: 15),
          bodySmall: baseTextTheme.bodySmall?.copyWith(fontSize: 13),
        );

        final darkBase = Typography.material2021().white.apply(
          bodyColor: Colors.white70,
          displayColor: Colors.white70,
        );

        final darkTextTheme = darkBase.copyWith(
          titleLarge: darkBase.titleLarge?.copyWith(fontSize: 22, fontWeight: FontWeight.w700),
          titleMedium: darkBase.titleMedium?.copyWith(fontSize: 18, fontWeight: FontWeight.w600),
          bodyMedium: darkBase.bodyMedium?.copyWith(fontSize: 15),
          bodySmall: darkBase.bodySmall?.copyWith(fontSize: 13),
        );

        final lightTheme = ThemeData(
          useMaterial3: true,
          colorScheme: lightScheme,
          scaffoldBackgroundColor: lightScheme.background,
          textTheme: lightTextTheme,
          appBarTheme: AppBarTheme(backgroundColor: lightScheme.surface, foregroundColor: lightScheme.onSurface, elevation: 1),
          listTileTheme: const ListTileThemeData(contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: lightScheme.surfaceVariant,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            floatingLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0)),
          outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))),
          floatingActionButtonTheme: FloatingActionButtonThemeData(
            backgroundColor: lightScheme.secondaryContainer,
            foregroundColor: lightScheme.onSecondaryContainer,
          ),
        );

        final darkTheme = ThemeData(
          useMaterial3: true,
          colorScheme: darkScheme,
          scaffoldBackgroundColor: darkScheme.background,
          textTheme: darkTextTheme,
          appBarTheme: AppBarTheme(backgroundColor: darkScheme.surface, foregroundColor: darkScheme.onSurface, elevation: 1),
          listTileTheme: const ListTileThemeData(contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: darkScheme.surfaceVariant,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            floatingLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0)),
          outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))),
          floatingActionButtonTheme: FloatingActionButtonThemeData(
            backgroundColor: darkScheme.secondaryContainer,
            foregroundColor: darkScheme.onSecondaryContainer,
          ),
        );

        return MaterialApp(
          title: 'مدیریت اقساط و بدهی‌ها',
          debugShowCheckedModeBanner: false,
          themeMode: themeMode,
          theme: lightTheme,
          darkTheme: darkTheme,
          home: const AppShell(),
        );
      },
    );
  }
}
