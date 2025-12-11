import 'package:flutter/material.dart';
import '../../core/settings/settings_repository.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _page = 0;

  // temporary selections
  String _language = 'en';
  String _theme = 'system';
  String _calendar = 'gregorian';
  bool _reminders = true;
  bool _budgetAlerts = true;
  bool _monthlySummary = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _complete() async {
    final settings = SettingsRepository();
    await settings.init();
    await settings.setLanguageCode(_language);
    final themeMode = _theme == 'light' ? ThemeMode.light : _theme == 'dark' ? ThemeMode.dark : ThemeMode.system;
    await settings.setThemeMode(themeMode);
    await settings.setCalendarType(_calendar == 'jalali' ? CalendarType.jalali : CalendarType.gregorian);
    await settings.setRemindersEnabled(_reminders);
    await settings.setBudgetAlertsEnabled(_budgetAlerts);
    await settings.setMonthlySummaryEnabled(_monthlySummary);
    await settings.setOnboardingComplete(true);

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Welcome')),
      body: SafeArea(
        child: Column(
          children: [
          Expanded(
            child: PageView(
              controller: _controller,
              onPageChanged: (p) => setState(() => _page = p),
              children: [
                _buildExplainer(),
                _buildPreferences(),
                _buildNotifications(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                TextButton(
                  onPressed: _page == 0 ? null : () => _controller.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.ease),
                  child: const Text('Back'),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _page == 2 ? _complete : () => _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.ease),
                  child: Text(_page == 2 ? 'Done' : 'Next'),
                ),
              ],
            ),
          ),
          ],
        ),
      ),
    );
  }

  Widget _buildExplainer() {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 24),
          Text('Debt Manager', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
          Text('Track loans, installments and budgets. Privacy-first, offline-friendly.'),
        ],
      ),
    );
  }

  Widget _buildPreferences() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          const Text('Preferences', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _language,
            decoration: const InputDecoration(labelText: 'Language'),
            items: const [DropdownMenuItem(value: 'en', child: Text('English')), DropdownMenuItem(value: 'fa', child: Text('فارسی'))],
            onChanged: (v) => setState(() => _language = v ?? 'en'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _theme,
            decoration: const InputDecoration(labelText: 'Theme'),
            items: const [DropdownMenuItem(value: 'system', child: Text('System')), DropdownMenuItem(value: 'light', child: Text('Light')), DropdownMenuItem(value: 'dark', child: Text('Dark'))],
            onChanged: (v) => setState(() => _theme = v ?? 'system'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _calendar,
            decoration: const InputDecoration(labelText: 'Calendar'),
            items: const [DropdownMenuItem(value: 'gregorian', child: Text('Gregorian')), DropdownMenuItem(value: 'jalali', child: Text('Jalali'))],
            onChanged: (v) => setState(() => _calendar = v ?? 'gregorian'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotifications() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          const Text('Notifications', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Reminders'),
            value: _reminders,
            onChanged: (v) => setState(() => _reminders = v),
          ),
          SwitchListTile(
            title: const Text('Budget alerts'),
            value: _budgetAlerts,
            onChanged: (v) => setState(() => _budgetAlerts = v),
          ),
          SwitchListTile(
            title: const Text('Monthly summary'),
            value: _monthlySummary,
            onChanged: (v) => setState(() => _monthlySummary = v),
          ),
        ],
      ),
    );
  }
}
