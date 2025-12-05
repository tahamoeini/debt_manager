import 'package:flutter/material.dart';
import 'app_shell.dart';

class DebtManagerApp extends StatelessWidget {
  const DebtManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'مدیریت اقساط و بدهی‌ها',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4CAF50),
          brightness: Brightness.dark,
        ),
        // Card visuals: use consistent elevation and rely on Card widgets' padding
        // ListTile defaults
        listTileTheme: const ListTileThemeData(
          dense: false,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        inputDecorationTheme: InputDecorationTheme(
          floatingLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          labelStyle: const TextStyle(fontWeight: FontWeight.w500),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          errorStyle: const TextStyle(color: Colors.redAccent),
        ),
        // Slightly increase default text contrast for Farsi readability
        textTheme: ThemeData.dark().textTheme.apply(
          bodyColor: Colors.white70,
          displayColor: Colors.white,
        ),
      ),
      home: const AppShell(),
    );
  }
}
