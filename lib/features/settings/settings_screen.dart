import 'package:flutter/material.dart';
import '../../core/settings/settings_repository.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsRepository _settings = SettingsRepository();
  bool _ready = false;

  bool _reminders = true;
  bool _budgetAlerts = true;
  bool _monthlySummary = true;
  bool _smartInsights = true;
  int _offsetDays = 0;
  String _calendar = 'gregorian';
  String _language = 'en';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _settings.init();
    setState(() {
      _reminders = _settings.remindersEnabled;
      _budgetAlerts = _settings.budgetAlertsEnabled;
      _monthlySummary = _settings.monthlySummaryEnabled;
      _smartInsights = _settings.smartInsightsEnabled;
      _offsetDays = _settings.reminderOffsetDays;
      _calendar = _settings.calendarType == CalendarType.jalali ? 'jalali' : 'gregorian';
      _language = _settings.languageCode;
      _ready = true;
    });
  }

  Future<void> _save() async {
    await _settings.setRemindersEnabled(_reminders);
    await _settings.setBudgetAlertsEnabled(_budgetAlerts);
    await _settings.setMonthlySummaryEnabled(_monthlySummary);
    await _settings.setSmartInsightsEnabled(_smartInsights);
    await _settings.setReminderOffsetDays(_offsetDays);
    await _settings.setCalendarType(_calendar == 'jalali' ? CalendarType.jalali : CalendarType.gregorian);
    await _settings.setLanguageCode(_language);

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings saved')));
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          SwitchListTile(title: const Text('Reminders'), value: _reminders, onChanged: (v) => setState(() => _reminders = v)),
          SwitchListTile(title: const Text('Budget alerts'), value: _budgetAlerts, onChanged: (v) => setState(() => _budgetAlerts = v)),
          SwitchListTile(title: const Text('Monthly summary'), value: _monthlySummary, onChanged: (v) => setState(() => _monthlySummary = v)),
          SwitchListTile(title: const Text('Smart insights'), value: _smartInsights, onChanged: (v) => setState(() => _smartInsights = v)),
          const SizedBox(height: 12),
          Row(children: [const Text('Reminder offset (days): '), const SizedBox(width: 8), Expanded(child: TextFormField(initialValue: _offsetDays.toString(), keyboardType: TextInputType.number, onChanged: (v) => _offsetDays = int.tryParse(v) ?? 0))]),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(value: _calendar, decoration: const InputDecoration(labelText: 'Calendar'), items: const [DropdownMenuItem(value: 'gregorian', child: Text('Gregorian')), DropdownMenuItem(value: 'jalali', child: Text('Jalali'))], onChanged: (v) => setState(() => _calendar = v ?? 'gregorian')),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(value: _language, decoration: const InputDecoration(labelText: 'Language'), items: const [DropdownMenuItem(value: 'en', child: Text('English')), DropdownMenuItem(value: 'fa', child: Text('فارسی'))], onChanged: (v) => setState(() => _language = v ?? 'en')),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: _save, child: const Text('Save')),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () async {
              await _settings.replayOnboarding();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Onboarding will replay on next launch')));
            },
            child: const Text('Replay onboarding'),
          ),
        ],
      ),
    );
  }
}
