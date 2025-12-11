import 'package:flutter/material.dart';
import '../../core/settings/settings_repository.dart';
import '../../core/privacy/privacy_gateway.dart';
import '../../core/privacy/backup_service.dart';
import '../../core/notifications/notification_service.dart';
import '../data_transfer/qr_sender.dart';
import '../data_transfer/qr_receiver.dart';
import '../../core/security/local_auth_service.dart';
import '../../core/security/pin_service.dart';

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
  bool _hasPin = false;

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
      // Check for PIN stored
      _hasPin = false;
      // async check for stored PIN
      PinService().hasPin().then((v) => setState(() => _hasPin = v));
      _ready = true;
    });
  }

  Future<String?> _askForPin({bool verify = false}) async {
    final controller = TextEditingController();
    final ok = await showDialog<bool?>(context: context, builder: (ctx) {
      return AlertDialog(
        title: Text(verify ? 'Enter PIN' : 'Set PIN'),
        content: TextField(controller: controller, keyboardType: TextInputType.number, obscureText: true, maxLength: 8),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('OK')),
        ],
      );
    });
    if (ok == true) return controller.text;
    return null;
  }

  Future<String?> _askPassword() async {
    final controller = TextEditingController();
    final ok = await showDialog<bool?>(context: context, builder: (ctx) {
      return AlertDialog(
        title: const Text('Password'),
        content: TextField(controller: controller, obscureText: true),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('OK')),
        ],
      );
    });
    if (ok == true) return controller.text;
    return null;
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
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 12),
          const Text('Privacy & Security', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Data stored locally: loans, installments, counterparties, and backups.'),
          const SizedBox(height: 4),
          const Text('Encryption: backups are encrypted with a password-derived key; secrets are stored in platform secure storage.'),
          const SizedBox(height: 8),
          Row(children: [
            ElevatedButton(
              onPressed: () async {
                // set/remove PIN
                final pinSvc = PinService();
                if (await pinSvc.hasPin()) {
                  // remove
                  await pinSvc.removePin();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN removed')));
                } else {
                  final pin = await _askForPin();
                  if (pin != null && pin.length >= 4) {
                    await pinSvc.setPin(pin);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN set')));
                  }
                }
                setState(() {});
              },
              child: const Text('Set / Remove PIN'),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
              // Confirm and require PIN/biometric check. For now show a dialog and proceed to panic wipe.
                final ok = await showDialog<bool>(context: context, builder: (ctx) {
                  return AlertDialog(
                    title: const Text('Panic wipe'),
                    content: const Text('This will permanently delete all local data and backups. This action is irreversible. Are you sure?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                      TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Wipe')),
                    ],
                  );
                });

                if (ok == true) {
                  // Attempt biometric auth first
                  final la = LocalAuthService();
                  final didAuth = await la.authenticate(reason: 'Authenticate to perform panic wipe');
                  var pinOk = false;
                  if (!didAuth) {
                    // fallback to PIN
                    final pin = await _askForPin(verify: true);
                    if (pin != null) {
                      final pinSvc = PinService();
                      pinOk = await pinSvc.verifyPin(pin);
                    }
                  }

                  if (didAuth || pinOk) {
                    try {
                      final pg = PrivacyGateway();
                      await pg.panicWipe();
                      await pg.audit('panic_wipe', details: 'User initiated panic wipe via settings');
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All local data wiped')));
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to wipe data')));
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Authentication failed. Wipe aborted.')));
                  }
                }
            },
            child: const Text('Panic wipe (delete all local data)'),
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 12),
          const Text('Data Management', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ElevatedButton(onPressed: () async {
            // Export (encrypted) backup to file
            final la = LocalAuthService();
            final ok = await la.authenticate(reason: 'Authenticate to export backup');
            if (!ok) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Auth failed'))); return; }
            final pw = await _askPassword();
            if (pw == null) return;
            final jsonStr = await BackupService.exportFullJson();
            final path = await BackupService.encryptAndSave(jsonStr, pw, filename: 'backup_${DateTime.now().millisecondsSinceEpoch}.dm');
            final pg = PrivacyGateway();
            await pg.audit('export_backup', details: path);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Encrypted backup saved')));
          }, child: const Text('Export encrypted backup')),
          ElevatedButton(onPressed: () async {
            // Import backup from file: require auth and password
            final la = LocalAuthService();
            final ok = await la.authenticate(reason: 'Authenticate to import backup');
            if (!ok) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Auth failed'))); return; }
            final pw = await _askPassword();
            if (pw == null) return;
            // For simplicity, ask user to provide file path (or implement file picker)
            final controller = TextEditingController();
            final got = await showDialog<bool>(context: context, builder: (ctx) {
              return AlertDialog(
                title: const Text('Import - enter backup file path'),
                content: TextField(controller: controller),
                actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')), TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('OK'))],
              );
            });
            if (got != true) return;
            final path = controller.text.trim();
            try {
              final jsonStr = await BackupService.decryptFromFile(path, pw);
              final pg = PrivacyGateway();
              await pg.audit('import_backup', details: path);
              await pg.importJsonString(jsonStr);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Import completed')));
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to import backup')));
            }
          }, child: const Text('Import encrypted backup (from path)')),
          ElevatedButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const QrSenderScreen())), child: const Text('Offline Transfer - Send')), 
          ElevatedButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const QrReceiverScreen())), child: const Text('Offline Transfer - Receive')),
          ]),
        ],
      ),
    );
  }
}
