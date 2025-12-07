// ignore_for_file: use_build_context_synchronously, deprecated_member_use

// Settings screen: adjust local app settings like reminder offsets.
import 'package:flutter/material.dart';

import 'package:debt_manager/core/settings/settings_repository.dart';
import 'package:debt_manager/core/notifications/notification_service.dart';
import 'package:debt_manager/features/categories/screens/manage_categories_screen.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

import 'package:debt_manager/core/backup/backup_service.dart';
import 'package:debt_manager/features/help/help_screen.dart';
import 'package:debt_manager/features/automation/screens/automation_rules_screen.dart';
import 'package:debt_manager/core/db/database_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _repo = SettingsRepository();
  int _offset = 3;
  ThemeMode _themeMode = ThemeMode.system;
  FontSizeOption _fontSize = FontSizeOption.defaultSize;
  CalendarType _calendarType = CalendarType.jalali;
  LanguageOption _language = LanguageOption.persian;
  bool _notificationsEnabled = true;
  bool _billReminders = true;
  bool _budgetAlerts = true;
  bool _loading = true;
  bool _smartSuggestions = true;
  bool _financeCoach = true;
  bool _monthEndSummary = true;

  final List<int> _options = const [0, 1, 3, 7];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final v = await _repo.getReminderOffsetDays();
    final tm = await _repo.getThemeMode();
    final fs = await _repo.getFontSize();
    final ct = await _repo.getCalendarType();
    final lang = await _repo.getLanguage();
    final notif = await _repo.getNotificationsEnabled();
    final bills = await _repo.getBillRemindersEnabled();
    final budget = await _repo.getBudgetAlertsEnabled();
    final ba = await _repo.getBudgetAlertsEnabled();
    final ss = await _repo.getSmartSuggestionsEnabled();
    final fc = await _repo.getFinanceCoachEnabled();
    final mes = await _repo.getMonthEndSummaryEnabled();
    if (mounted) {
      setState(() {
        _offset = v;
        _themeMode = tm;
        _fontSize = fs;
        _calendarType = ct;
        _language = lang;
        _notificationsEnabled = notif;
        _billReminders = bills;
        _budgetAlerts = budget;
        _budgetAlerts = ba;
        _smartSuggestions = ss;
        _financeCoach = fc;
        _monthEndSummary = mes;
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

  Future<void> _saveFontSize(FontSizeOption size) async {
    await _repo.setFontSize(size);
    if (mounted) {
      setState(() {
        _fontSize = size;
      });
    }
  }

  Future<void> _saveCalendarType(CalendarType type) async {
    await _repo.setCalendarType(type);
    if (mounted) {
      setState(() {
        _calendarType = type;
      });
    }
  }

  Future<void> _saveLanguage(LanguageOption lang) async {
    await _repo.setLanguage(lang);
    if (mounted) {
      setState(() {
        _language = lang;
      });
    }
  }

  Future<void> _saveNotificationsEnabled(bool enabled) async {
    await _repo.setNotificationsEnabled(enabled);
    if (!enabled) {
      // Show loading indicator while canceling all notifications
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('در حال لغو اعلان‌ها...'),
            duration: Duration(seconds: 1),
          ),
        );
      }
      // Cancel all notifications when master toggle is turned off
      await NotificationService.instance.cancelAllNotifications();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تمام اعلان‌ها لغو شدند')),
        );
      }
    }
    if (mounted) {
      setState(() {
        _notificationsEnabled = enabled;
      });
    }
  }

  Future<void> _saveBillReminders(bool enabled) async {
    await _repo.setBillRemindersEnabled(enabled);
    if (mounted) {
      setState(() {
        _billReminders = enabled;
      });
    }
  }

  Future<void> _saveBudgetAlerts(bool enabled) async {
    await _repo.setBudgetAlertsEnabled(enabled);
    if (mounted) {
      setState(() {
        _budgetAlerts = enabled;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تنظیمات'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Appearance Settings Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'نمایش و ظاهر',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        const Divider(),
                        const SizedBox(height: 8),
                        Text(
                          'حالت تم',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 8),
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
                        const Divider(),
                        const SizedBox(height: 8),
                        Text(
                          'اندازه فونت',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        RadioListTile<FontSizeOption>(
                          title: const Text('کوچک'),
                          value: FontSizeOption.small,
                          groupValue: _fontSize,
                          onChanged: (v) async {
                            if (v == null) return;
                            await _saveFontSize(v);
                          },
                        ),
                        RadioListTile<FontSizeOption>(
                          title: const Text('متوسط (پیش‌فرض)'),
                          value: FontSizeOption.defaultSize,
                          groupValue: _fontSize,
                          onChanged: (v) async {
                            if (v == null) return;
                            await _saveFontSize(v);
                          },
                        ),
                        RadioListTile<FontSizeOption>(
                          title: const Text('بزرگ'),
                          value: FontSizeOption.large,
                          groupValue: _fontSize,
                          onChanged: (v) async {
                            if (v == null) return;
                            await _saveFontSize(v);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Localization Settings Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'زبان و تقویم',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        const Divider(),
                        const SizedBox(height: 8),
                        Text(
                          'زبان برنامه',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        RadioListTile<LanguageOption>(
                          title: const Text('فارسی'),
                          value: LanguageOption.persian,
                          groupValue: _language,
                          onChanged: (v) async {
                            if (v == null) return;
                            await _saveLanguage(v);
                          },
                        ),
                        RadioListTile<LanguageOption>(
                          title: const Text('English'),
                          value: LanguageOption.english,
                          groupValue: _language,
                          onChanged: (v) async {
                            if (v == null) return;
                            await _saveLanguage(v);
                          },
                        ),
                        const Divider(),
                        const SizedBox(height: 8),
                        Text(
                          'نوع تقویم',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        RadioListTile<CalendarType>(
                          title: const Text('تقویم شمسی (جلالی)'),
                          value: CalendarType.jalali,
                          groupValue: _calendarType,
                          onChanged: (v) async {
                            if (v == null) return;
                            await _saveCalendarType(v);
                          },
                        ),
                        RadioListTile<CalendarType>(
                          title: const Text('Gregorian Calendar'),
                          value: CalendarType.gregorian,
                          groupValue: _calendarType,
                          onChanged: (v) async {
                            if (v == null) return;
                            await _saveCalendarType(v);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Notifications Settings Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'اعلان‌ها',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'مدیریت اعلان‌های برنامه',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 12),
                        SwitchListTile(
                          title: const Text('فعال‌سازی کلیه اعلان‌ها'),
                          subtitle: const Text(
                            'غیرفعال کردن این گزینه تمام اعلان‌ها را متوقف می‌کند',
                          ),
                          value: _notificationsEnabled,
                          onChanged: (v) async {
                            await _saveNotificationsEnabled(v);
                          },
                        ),
                        const Divider(),
                        SwitchListTile(
                          title: const Text('یادآوری قبوض و اقساط'),
                          subtitle: const Text(
                            'اعلان برای سررسید اقساط و پرداخت‌ها',
                          ),
                          value: _billReminders,
                          onChanged: _notificationsEnabled ? (v) async {
                            await _saveBillReminders(v);
                          } : null,
                        ),
                        SwitchListTile(
                          title: const Text('هشدارهای بودجه'),
                          subtitle: const Text(
                            'اعلان هنگام نزدیک شدن به محدودیت بودجه',
                          ),
                          value: _budgetAlerts,
                          onChanged: _notificationsEnabled ? (v) async {
                            await _saveBudgetAlerts(v);
                          } : null,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Reminder Timing Card
                Card(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  child: ListTile(
                    leading: Icon(
                      Icons.help_outline,
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                    title: Text(
                      'راهنمای ویژگی‌های هوشمند',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      'درباره یادآورها، هشدارها و پیشنهادهای هوشمند بیشتر بدانید',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                      size: 16,
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const HelpScreen()),
                      );
                    },
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
                // Category Management Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'مدیریت دسته‌بندی‌ها',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'افزودن، ویرایش یا حذف دسته‌بندی‌های سفارشی',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ManageCategoriesScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.category_outlined),
                          label: const Text('مدیریت دسته‌بندی‌ها'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Backup and Restore Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'هوش مالی و پیشنهادها',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'تنظیمات مربوط به یادآورها و پیشنهادهای هوشمند',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 12),
                        SwitchListTile(
                          title: const Text('هشدارهای بودجه'),
                          subtitle: const Text('اطلاع‌رسانی وقتی بودجه به حد آستانه رسید'),
                          value: _budgetAlerts,
                          onChanged: (v) async {
                            await _repo.setBudgetAlertsEnabled(v);
                            if (mounted) {
                              setState(() {
                                _budgetAlerts = v;
                              });
                            }
                          },
                        ),
                        SwitchListTile(
                          title: const Text('پیشنهادهای هوشمند'),
                          subtitle: const Text('تشخیص اشتراک‌ها و تغییرات قبوض'),
                          value: _smartSuggestions,
                          onChanged: (v) async {
                            await _repo.setSmartSuggestionsEnabled(v);
                            if (mounted) {
                              setState(() {
                                _smartSuggestions = v;
                              });
                            }
                          },
                        ),
                        SwitchListTile(
                          title: const Text('مشاور مالی'),
                          subtitle: const Text('نکات و راهنمایی‌های مالی در برنامه'),
                          value: _financeCoach,
                          onChanged: (v) async {
                            await _repo.setFinanceCoachEnabled(v);
                            if (mounted) {
                              setState(() {
                                _financeCoach = v;
                              });
                            }
                          },
                        ),
                        SwitchListTile(
                          title: const Text('خلاصه پایان ماه'),
                          subtitle: const Text('گزارش عملکرد بودجه در پایان ماه'),
                          value: _monthEndSummary,
                          onChanged: (v) async {
                            await _repo.setMonthEndSummaryEnabled(v);
                            if (mounted) {
                              setState(() {
                                _monthEndSummary = v;
                              });
                            }
                          },
                        ),
                        const Divider(height: 24),
                        ListTile(
                          leading: const Icon(Icons.rule_outlined),
                          title: const Text('قوانین خودکارسازی'),
                          subtitle: const Text('مدیریت دسته‌بندی خودکار تراکنش‌ها'),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const AutomationRulesScreen(),
                              ),
                            );
                          },
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
                            Expanded(
                              child: FilledButton.icon(
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
                                                    tooltip: 'Copy to clipboard',
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
                                icon: const Icon(Icons.upload_outlined),
                                label: const Text('Export'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            FilledButton.icon(
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
                              icon: const Icon(Icons.upload_outlined),
                              label: const Text('Export data (JSON)'),
                            ),
                            const SizedBox(width: 12),
                            FilledButton.icon(
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
                              icon: const Icon(Icons.download_outlined),
                              label: const Text('Import'),
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
                                final loans = await DatabaseHelper.instance.getAllLoans();
                                for (final loan in loans) {
                                  if (loan.id != null) {
                                    await DatabaseHelper.instance.deleteLoanWithInstallments(loan.id!);
                                  }
                                }
                                
                                // Delete all budgets
                                final db = await DatabaseHelper.instance.database;
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
                          label: const Text('پاک کردن تمام داده‌ها'),
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
