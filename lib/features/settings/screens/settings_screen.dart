// ignore_for_file: deprecated_member_use, use_build_context_synchronously

// Settings screen: adjust local app settings like reminder offsets.
import 'package:flutter/material.dart';

import 'package:debt_manager/core/settings/settings_repository.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:io';

import 'package:debt_manager/core/backup/backup_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _repo = SettingsRepository();
  int _offset = 3;
  ThemeMode _themeMode = ThemeMode.system;
  bool _loading = true;

  final List<int> _options = const [0, 1, 3, 7];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final v = await _repo.getReminderOffsetDays();
    final tm = await _repo.getThemeMode();
    if (mounted) {
      setState(() {
        _offset = v;
        _themeMode = tm;
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

  Future<void> _saveTheme(ThemeMode m) async {
    await _repo.setThemeMode(m);
    if (mounted) {
      setState(() {
        _themeMode = m;
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
                        Text(
                          'یادآوری اقساط',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'فاصله زمانی ارسال یادآوری قبل از سررسید',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 12),
                        Column(
                          children: _options.map((opt) {
                            return RadioListTile<int>(
                              title: Text(
                                opt == 0 ? 'روز سررسید' : '$opt روز قبل',
                              ),
                              value: opt,
                              groupValue: _offset,
                              onChanged: (v) async {
                                if (v == null) return;
                                await _save(v);
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'نمایش و رنگ‌ها',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'حالت تم برنامه را انتخاب کنید',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 12),
                        RadioListTile<ThemeMode>(
                          title: const Text('Auto (پیش‌فرض سیستم)'),
                          value: ThemeMode.system,
                          groupValue: _themeMode,
                          onChanged: (v) async {
                            if (v == null) return;
                            await _saveTheme(v);
                          },
                        ),
                        RadioListTile<ThemeMode>(
                          title: const Text('Light'),
                          value: ThemeMode.light,
                          groupValue: _themeMode,
                          onChanged: (v) async {
                            if (v == null) return;
                            await _saveTheme(v);
                          },
                        ),
                        RadioListTile<ThemeMode>(
                          title: const Text('Dark'),
                          value: ThemeMode.dark,
                          groupValue: _themeMode,
                          onChanged: (v) async {
                            if (v == null) return;
                            await _saveTheme(v);
                          },
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'پشتیبان‌گیری و بازیابی',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'می‌توانید داده‌ها را به صورت JSON صادر یا وارد کنید. این عملیات محلی است.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            FilledButton(
                              onPressed: () async {
                                final messenger = ScaffoldMessenger.of(context);
                                try {
                                  final jsonStr = await BackupService.instance
                                      .exportAll();
                                  await showDialog<void>(
                                    context: context,
                                    builder: (ctx) => Dialog(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(12.0),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                const Text('Exported JSON'),
                                                IconButton(
                                                  icon: const Icon(Icons.copy_outlined),
                                                  onPressed: () async {
                                                    final messenger =
                                                        ScaffoldMessenger.of(
                                                          context,
                                                        );
                                                    await Clipboard.setData(
                                                      ClipboardData(
                                                        text: jsonStr,
                                                      ),
                                                    );
                                                    if (!mounted) return;
                                                    messenger.showSnackBar(
                                                      const SnackBar(
                                                        content: Text('کپی شد'),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(
                                            height:
                                                MediaQuery.of(
                                                  context,
                                                ).size.height *
                                                0.6,
                                            width: double.maxFinite,
                                            child: SingleChildScrollView(
                                              padding: const EdgeInsets.all(12),
                                              child: SelectableText(jsonStr),
                                            ),
                                          ),
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: TextButton(
                                              onPressed: () =>
                                                  Navigator.of(ctx).pop(),
                                              child: const Text('بستن'),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                } catch (e) {
                                  if (mounted) {
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text('خطا در صادرات: $e'),
                                      ),
                                    );
                                  }
                                }
                              },
                              child: const Text('Export data (JSON)'),
                            ),
                            const SizedBox(width: 12),
                            FilledButton.icon(
                              onPressed: () async {
                                final messenger = ScaffoldMessenger.of(context);
                                try {
                                  final jsonStr = await BackupService.instance.exportAll();
                                  
                                  // Save to file
                                  final directory = await getApplicationDocumentsDirectory();
                                  final timestamp = DateTime.now().millisecondsSinceEpoch;
                                  final filePath = '${directory.path}/backup_$timestamp.json';
                                  final file = File(filePath);
                                  await file.writeAsString(jsonStr);
                                  
                                  // Share the file
                                  if (!mounted) return;
                                  await Share.shareXFiles(
                                    [XFile(filePath)],
                                    text: 'پشتیبان داده‌های برنامه',
                                  );
                                  
                                  if (!mounted) return;
                                  messenger.showSnackBar(
                                    const SnackBar(content: Text('فایل پشتیبان ایجاد و اشتراک‌گذاری شد')),
                                  );
                                } catch (e) {
                                  if (mounted) {
                                    messenger.showSnackBar(
                                      SnackBar(content: Text('خطا در ایجاد پشتیبان: $e')),
                                    );
                                  }
                                }
                              },
                              icon: const Icon(Icons.share),
                              child: const Text('اشتراک‌گذاری پشتیبان'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            FilledButton(
                              onPressed: () async {
                                final messenger = ScaffoldMessenger.of(context);
                                try {
                                  final jsonStr = await BackupService.instance
                                      .exportAll();
                                  await showDialog<void>(
                                    context: context,
                                    builder: (ctx) => Dialog(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(12.0),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                const Text('Exported JSON'),
                                                IconButton(
                                                  icon: const Icon(Icons.copy_outlined),
                                                  onPressed: () async {
                                                    final messenger =
                                                        ScaffoldMessenger.of(
                                                          context,
                                                        );
                                                    await Clipboard.setData(
                                                      ClipboardData(
                                                        text: jsonStr,
                                                      ),
                                                    );
                                                    if (!mounted) return;
                                                    messenger.showSnackBar(
                                                      const SnackBar(
                                                        content: Text('کپی شد'),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(
                                            height:
                                                MediaQuery.of(
                                                  context,
                                                ).size.height *
                                                0.6,
                                            width: double.maxFinite,
                                            child: SingleChildScrollView(
                                              padding: const EdgeInsets.all(12),
                                              child: SelectableText(jsonStr),
                                            ),
                                          ),
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: TextButton(
                                              onPressed: () =>
                                                  Navigator.of(ctx).pop(),
                                              child: const Text('بستن'),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                } catch (e) {
                                  if (mounted) {
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text('خطا در صادرات: $e'),
                                      ),
                                    );
                                  }
                                }
                              },
                              child: const Text('Export data (JSON)'),
                            ),
                            const SizedBox(width: 12),
                            FilledButton(
                              onPressed: () async {
                                // Show a dialog with a multiline TextField to paste JSON
                                final controller = TextEditingController();
                                await showDialog<void>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Import data (JSON)'),
                                    content: SizedBox(
                                      height: 300,
                                      width: 600,
                                      child: Column(
                                        children: [
                                          Expanded(
                                            child: TextField(
                                              controller: controller,
                                              maxLines: null,
                                              decoration: const InputDecoration(
                                                hintText:
                                                    '{ "counterparties": [...], "loans": [...], "installments": [...] }',
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              TextButton(
                                                onPressed: () async {
                                                  final data =
                                                      await Clipboard.getData(
                                                        'text/plain',
                                                      );
                                                  if (data != null &&
                                                      data.text != null) {
                                                    controller.text =
                                                        data.text!;
                                                  }
                                                },
                                                child: const Text(
                                                  'Paste from clipboard',
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              TextButton(
                                                onPressed: () {
                                                  controller.text = '';
                                                },
                                                child: const Text('Clear'),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(ctx).pop(),
                                        child: const Text('Cancel'),
                                      ),
                                      FilledButton(
                                        onPressed: () async {
                                          final messenger =
                                              ScaffoldMessenger.of(context);
                                          final txt = controller.text.trim();
                                          if (txt.isEmpty) return;
                                          try {
                                            final parsed =
                                                json.decode(txt)
                                                    as Map<String, dynamic>;
                                            await BackupService.instance
                                                .importFromMap(
                                                  parsed,
                                                  clearBefore: true,
                                                );
                                            if (!mounted) return;
                                            messenger.showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'بازیابی با موفقیت انجام شد',
                                                ),
                                              ),
                                            );
                                            Navigator.of(ctx).pop();
                                          } catch (e) {
                                            if (!mounted) return;
                                            messenger.showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'خطا در واردسازی: $e',
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                        child: const Text('Import'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              child: const Text('Import data (JSON)'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),
                        Text(
                          'مدیریت داده‌ها',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'با احتیاط استفاده کنید! این عملیات غیرقابل بازگشت است.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('پاک کردن تمام داده‌ها'),
                                content: const Text(
                                  'آیا مطمئن هستید که می‌خواهید تمام داده‌های برنامه را پاک کنید؟ این عملیات غیرقابل بازگشت است و تمام وام‌ها، اقساط و بودجه‌ها حذف خواهند شد.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(false),
                                    child: const Text('لغو'),
                                  ),
                                  FilledButton(
                                    onPressed: () => Navigator.of(ctx).pop(true),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: Theme.of(context).colorScheme.error,
                                    ),
                                    child: const Text('بله، پاک کن'),
                                  ),
                                ],
                              ),
                            );
                            
                            if (confirmed == true) {
                              final messenger = ScaffoldMessenger.of(context);
                              try {
                                // Delete all loans (which also deletes installments)
                                final loans = await BackupService.instance._db.getAllLoans();
                                for (final loan in loans) {
                                  if (loan.id != null) {
                                    await BackupService.instance._db.deleteLoanWithInstallments(loan.id!);
                                  }
                                }
                                
                                // Delete all budgets
                                final db = await BackupService.instance._db.database;
                                await db.delete('budgets');
                                
                                if (!mounted) return;
                                messenger.showSnackBar(
                                  const SnackBar(content: Text('تمام داده‌ها با موفقیت پاک شدند')),
                                );
                              } catch (e) {
                                if (!mounted) return;
                                messenger.showSnackBar(
                                  SnackBar(content: Text('خطا در پاک کردن داده‌ها: $e')),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.delete_forever),
                          style: FilledButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.error,
                          ),
                          child: const Text('پاک کردن تمام داده‌ها'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
