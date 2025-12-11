import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/settings/settings_repository.dart';
import 'core/router/app_router.dart';
import 'core/providers/core_providers.dart';

/// App root wired to GoRouter (via Riverpod provider).

class DebtManagerApp extends ConsumerStatefulWidget {
  const DebtManagerApp({super.key});

  @override
  ConsumerState<DebtManagerApp> createState() => _DebtManagerAppState();
=======
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/localization/app_localizations.dart';
import 'app_shell.dart';
import 'core/settings/settings_repository.dart';
import 'features/onboarding/onboarding_screen.dart';

class DebtManagerApp extends StatefulWidget {
	const DebtManagerApp({super.key});

	@override
	State<DebtManagerApp> createState() => _DebtManagerAppState();
}

class _DebtManagerAppState extends State<DebtManagerApp> {
	final SettingsRepository _settings = SettingsRepository();
	bool _ready = false;

	@override
	void initState() {
		super.initState();
		_init();
	}

	Future<void> _init() async {
		await _settings.init();
		setState(() => _ready = true);
	}

	@override
	Widget build(BuildContext context) {
		if (!_ready) return const SizedBox.shrink();

		final locale = Locale(_settings.languageCode);
		final themeMode = _settings.themeMode == 'light'
				? ThemeMode.light
				: (_settings.themeMode == 'dark' ? ThemeMode.dark : ThemeMode.system);

		return MaterialApp(
			title: 'Debt Manager',
			debugShowCheckedModeBanner: false,
			themeMode: themeMode,
			theme: ThemeData(
				useMaterial3: true,
				colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4CAF50), brightness: Brightness.light),
			),
			darkTheme: ThemeData(
				useMaterial3: true,
				colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4CAF50), brightness: Brightness.dark),
			),
			locale: locale,
			localizationsDelegates: const [
				AppLocalizations.delegate,
				GlobalMaterialLocalizations.delegate,
				GlobalWidgetsLocalizations.delegate,
				GlobalCupertinoLocalizations.delegate,
			],
			supportedLocales: const [Locale('en'), Locale('fa')],
			home: _settings.onboardingComplete ? const AppShell() : const OnboardingScreen(),
		);
	}
>>>>>>> 6b5512b (Implement localization support, onboarding flow, and notification enhancements; refactor app structure for improved settings management)
}

class _DebtManagerAppState extends ConsumerState<DebtManagerApp> with WidgetsBindingObserver {
  final _settings = SettingsRepository();

  @override
  void initState() {
    import 'package:flutter/material.dart';
    import 'package:flutter_riverpod/flutter_riverpod.dart';
    import 'package:go_router/go_router.dart';
    import 'core/providers/core_providers.dart';
    import 'core/settings/settings_repository.dart';
    import 'core/router/app_router.dart';

    /// App root wired to GoRouter (via Riverpod provider).

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
        // Initialize biometric enabled notifier and try unlock via auth provider
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
          // lock on resume; auth notifier controls unlock flow
          ref.read(authNotifierProvider).lock();
          // try to unlock again (this will show LockScreen when router redirects to /lock)
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
                );
              },
            );
          },
        );
      }
    }
              elevatedButtonTheme: ElevatedButtonThemeData(
