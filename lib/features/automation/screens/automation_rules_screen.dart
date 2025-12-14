// Automation rules screen: manage categorization rules
import 'package:flutter/material.dart';
import 'package:debt_manager/features/automation/automation_rules_repository.dart';
import 'package:debt_manager/features/automation/models/automation_rule.dart';
import 'package:debt_manager/core/utils/ui_utils.dart';

class AutomationRulesScreen extends StatefulWidget {
  const AutomationRulesScreen({super.key});

  @override
  State<AutomationRulesScreen> createState() => _AutomationRulesScreenState();
}

class _AutomationRulesScreenState extends State<AutomationRulesScreen> {
  final _repo = AutomationRulesRepository();
  late Future<List<AutomationRule>> _rulesFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _rulesFuture = _repo.getAllRules();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('قوانین خودکارسازی')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddRuleDialog(context),
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<AutomationRule>>(
        future: _rulesFuture,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return UIUtils.centeredLoading();
          }
          if (snap.hasError) {
            return UIUtils.asyncErrorWidget(snap.error);
          }
          final rules = snap.data ?? [];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                color: Theme.of(context).colorScheme.tertiaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Theme.of(
                              context,
                            ).colorScheme.onTertiaryContainer,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'درباره قوانین خودکار',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onTertiaryContainer,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'برنامه به طور خودکار از یک فرهنگ لغت داخلی برای شناسایی دسته‌های رایج استفاده می‌کند. قوانین سفارشی را می‌توانید در نسخه‌های بعدی اضافه کنید.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onTertiaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'دسته‌های داخلی',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...BuiltInCategories.payeePatterns.entries.map(
                (entry) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.rule_outlined),
                    title: Text('اگر شامل "${entry.key}" باشد'),
                    subtitle: Text('دسته: ${entry.value}'),
                    dense: true,
                  ),
                ),
              ),
              if (rules.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'قوانین سفارشی',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ...rules.map(
                  (rule) => Card(
                    child: ListTile(
                      leading: Icon(
                        rule.enabled ? Icons.check_circle : Icons.cancel,
                        color: rule.enabled ? Colors.green : Colors.grey,
                      ),
                      title: Text(rule.name),
                      subtitle: Text(
                        '${_getRuleTypeLabel(rule.ruleType)}: ${rule.pattern} → ${rule.actionValue}',
                      ),
                      trailing: Switch(
                        value: rule.enabled,
                        onChanged: (v) async {
                          final updated = rule.copyWith(enabled: v);
                          await _repo.updateRule(updated);
                          _refresh();
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  void _showAddRuleDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final patternCtrl = TextEditingController();
    final actionValueCtrl = TextEditingController();
    String ruleType = 'payee_contains';
    String action = 'set_category';
    bool enabled = true;

    String samplePayee = '';
    String sampleDesc = '';
    int? sampleAmount;
    Map<String, String?> preview = {'category': null, 'tag': null};

    Future<void> recomputePreview() async {
      final repo = AutomationRulesRepository();
      final res = await repo.applyRules(samplePayee, sampleDesc, sampleAmount);
      preview = res;
      setState(() {});
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (c, setState) {
          return AlertDialog(
            title: const Text('افزودن قانون جدید'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'نام'),
                  ),
                  const SizedBox(height: 8),
                  DropdownButton<String>(
                    value: ruleType,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(
                        value: 'payee_contains',
                        child: Text('پرداخت‌گیرنده شامل'),
                      ),
                      DropdownMenuItem(
                        value: 'description_contains',
                        child: Text('توضیحات شامل'),
                      ),
                      DropdownMenuItem(
                        value: 'amount_equals',
                        child: Text('مبلغ برابر'),
                      ),
                    ],
                    onChanged: (v) => setState(() => ruleType = v ?? ruleType),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: patternCtrl,
                    decoration: const InputDecoration(
                      labelText: 'الگو (مثلا Uber یا 199000)',
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButton<String>(
                    value: action,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(
                        value: 'set_category',
                        child: Text('تنظیم دسته'),
                      ),
                      DropdownMenuItem(
                        value: 'set_tag',
                        child: Text('تنظیم برچسب'),
                      ),
                    ],
                    onChanged: (v) => setState(() => action = v ?? action),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: actionValueCtrl,
                    decoration: const InputDecoration(
                      labelText: 'مقدار اقدام (مثلا Transport یا Subscription)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text('پیش‌نمایش (Dry-run)'),
                  const SizedBox(height: 8),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'نمونه پرداخت‌گیرنده',
                    ),
                    onChanged: (v) async {
                      samplePayee = v;
                      await recomputePreview();
                    },
                  ),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'نمونه توضیحات',
                    ),
                    onChanged: (v) async {
                      sampleDesc = v;
                      await recomputePreview();
                    },
                  ),
                  TextField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'نمونه مبلغ'),
                    onChanged: (v) async {
                      sampleAmount = int.tryParse(v);
                      await recomputePreview();
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('پیشنهاد دسته:'),
                      const SizedBox(width: 8),
                      Text(preview['category'] ?? '-'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Text('پیشنهاد برچسب:'),
                      const SizedBox(width: 8),
                      Text(preview['tag'] ?? '-'),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('لغو'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final now = DateTime.now().toIso8601String();
                  final rule = AutomationRule(
                    id: null,
                    name: nameCtrl.text.trim().isEmpty
                        ? 'قانون جدید'
                        : nameCtrl.text.trim(),
                    ruleType: ruleType,
                    pattern: patternCtrl.text.trim(),
                    action: action,
                    actionValue: actionValueCtrl.text.trim(),
                    enabled: enabled,
                    createdAt: now,
                  );
                  await _repo.insertRule(rule);
                  if (!mounted) return;
                  Navigator.of(this.context).pop();
                  _refresh();
                },
                child: const Text('ذخیره'),
              ),
            ],
          );
        },
      ),
    );
  }

  String _getRuleTypeLabel(String type) {
    switch (type) {
      case 'payee_contains':
        return 'پرداخت‌گیرنده شامل';
      case 'description_contains':
        return 'توضیحات شامل';
      case 'amount_equals':
        return 'مبلغ برابر';
      default:
        return type;
    }
  }
}
