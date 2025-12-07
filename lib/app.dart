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
    // Initialize notifier values from persisted preferences
    _settings.getThemeMode().then((m) => SettingsRepository.themeModeNotifier.value = m);
    _settings.getFontSize().then((f) => SettingsRepository.fontSizeNotifier.value = f);
    _settings.getCalendarType().then((c) => SettingsRepository.calendarTypeNotifier.value = c);
    _settings.getLanguage().then((l) => SettingsRepository.languageNotifier.value = l);
  }

  @override
  Widget build(BuildContext context) {
    // Use ValueListenableBuilder for both theme and font size changes.
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: SettingsRepository.themeModeNotifier,
      builder: (context, themeMode, _) {
        return ValueListenableBuilder<FontSizeOption>(
          valueListenable: SettingsRepository.fontSizeNotifier,
          builder: (context, fontSize, _) {
            final fontScale = _settings.getFontScale(fontSize);
            
            // Seed colors: calming blue for primary
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
              // Ensure minimum touch target size for accessibility (48dp)
              materialTapTargetSize: MaterialTapTargetSize.padded,
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: lightScheme.surfaceContainerHighest,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                floatingLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                  minimumSize: const Size(48, 48),
                ),
              ),
              outlinedButtonTheme: OutlinedButtonThemeData(
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  minimumSize: const Size(48, 48),
                ),
              ),
              filledButtonTheme: FilledButtonThemeData(
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  minimumSize: const Size(48, 48),
                ),
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  minimumSize: const Size(48, 48),
                ),
              ),
              iconButtonTheme: IconButtonThemeData(
                style: IconButton.styleFrom(
                  minimumSize: const Size(48, 48),
                ),
              ),
              floatingActionButtonTheme: FloatingActionButtonThemeData(
                backgroundColor: lightScheme.secondaryContainer,
                foregroundColor: lightScheme.onSecondaryContainer,
              ),
            );

            final darkTheme = ThemeData(
              useMaterial3: true,
              colorScheme: darkScheme,
              scaffoldBackgroundColor: darkScheme.surface,
              textTheme: darkTextTheme,
              appBarTheme: AppBarTheme(backgroundColor: darkScheme.surface, foregroundColor: darkScheme.onSurface, elevation: 1),
              listTileTheme: const ListTileThemeData(contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
              // Ensure minimum touch target size for accessibility (48dp)
              materialTapTargetSize: MaterialTapTargetSize.padded,
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: darkScheme.surfaceContainerHighest,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                floatingLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                  minimumSize: const Size(48, 48),
                ),
              ),
              outlinedButtonTheme: OutlinedButtonThemeData(
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  minimumSize: const Size(48, 48),
                ),
              ),
              filledButtonTheme: FilledButtonThemeData(
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  minimumSize: const Size(48, 48),
                ),
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  minimumSize: const Size(48, 48),
                ),
              ),
              iconButtonTheme: IconButtonThemeData(
                style: IconButton.styleFrom(
                  minimumSize: const Size(48, 48),
                ),
              ),
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
      },
    );
  }
}
