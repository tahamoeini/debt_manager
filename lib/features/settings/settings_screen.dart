// Minimal, syntactically-correct settings screen to restore analyzer state.
import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _ready = true;

  @override
  Widget build(BuildContext context) {
    if (!_ready)
      return const Scaffold(
          body: SafeArea(child: Center(child: CircularProgressIndicator())));

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: const SafeArea(
        child: Center(
          child: Text('Settings (minimal placeholder)'),
        ),
      ),
    );
  }
}
