import 'package:flutter/material.dart';

import '../../../core/settings/settings_repository.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _repo = SettingsRepository();
  int _offset = 3;
  bool _loading = true;

  final List<int> _options = const [0, 1, 3, 7];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final v = await _repo.getReminderOffsetDays();
    if (mounted) {
      setState(() {
        _offset = v;
        _loading = false;
      });
    }
  }

  Future<void> _save(int v) async {
    await _repo.setReminderOffsetDays(v);
    if (mounted) {
      setState(() {
        _offset = v;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تنظیمات')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('یادآوری اقساط', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text('فاصله زمانی ارسال یادآوری قبل از سررسید', style: Theme.of(context).textTheme.bodySmall),
                        const SizedBox(height: 12),
                        Column(
                          children: _options.map((opt) {
                            return RadioListTile<int>(
                              title: Text(opt == 0 ? 'روز سررسید' : '$opt روز قبل'),
                              value: opt,
                              groupValue: _offset,
                              onChanged: (v) async {
                                if (v == null) return;
                                await _save(v);
                              },
                            );
                          }).toList(),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
