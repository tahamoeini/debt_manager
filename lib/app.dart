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
      ),
      home: const AppShell(),
    );
  }
}
