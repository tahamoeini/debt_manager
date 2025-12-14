// import_wizard_screen.dart: Multi-step import wizard for CSV/JSON data

// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:debt_manager/features/import_export/models/import_mapping.dart';

/// Multi-step import wizard state
class _ImportWizardState {
  int currentStep = 0;
  String? selectedFilePath;
  List<List<dynamic>> csvRows = [];
  List<ImportField> detectedFields = [];
  ImportMapping? mapping;
  ImportPreview? preview;
  ImportResult? result;

  _ImportWizardState copyWith({
    int? currentStep,
    String? selectedFilePath,
    List<List<dynamic>>? csvRows,
    List<ImportField>? detectedFields,
    ImportMapping? mapping,
    ImportPreview? preview,
    ImportResult? result,
  }) {
    return _ImportWizardState()
      ..currentStep = currentStep ?? this.currentStep
      ..selectedFilePath = selectedFilePath ?? this.selectedFilePath
      ..csvRows = csvRows ?? this.csvRows
      ..detectedFields = detectedFields ?? this.detectedFields
      ..mapping = mapping ?? this.mapping
      ..preview = preview ?? this.preview
      ..result = result ?? this.result;
  }
}

final _importWizardProvider =
    StateNotifierProvider<_ImportWizardNotifier, _ImportWizardState>((ref) {
      return _ImportWizardNotifier();
    });

class _ImportWizardNotifier extends StateNotifier<_ImportWizardState> {
  _ImportWizardNotifier() : super(_ImportWizardState());

  void setStep(int step) {
    state = state.copyWith(currentStep: step);
  }

  void setSelectedFile(String path) {
    state = state.copyWith(selectedFilePath: path);
  }

  void setCsvRows(List<List<dynamic>> rows) {
    state = state.copyWith(csvRows: rows);
  }

  void setDetectedFields(List<ImportField> fields) {
    state = state.copyWith(detectedFields: fields);
  }

  void setMapping(ImportMapping mapping) {
    state = state.copyWith(mapping: mapping);
  }

  void setPreview(ImportPreview preview) {
    state = state.copyWith(preview: preview);
  }

  void setResult(ImportResult result) {
    state = state.copyWith(result: result);
  }
}

/// Main import wizard screen
class ImportWizardScreen extends ConsumerWidget {
  const ImportWizardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wizardState = ref.watch(_importWizardProvider);
    final notifier = ref.read(_importWizardProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('درون‌ریز داده‌ها'), elevation: 0),
      body: SafeArea(child: _buildStep(context, ref, wizardState, notifier)),
    );
  }

  Widget _buildStep(
    BuildContext context,
    WidgetRef ref,
    _ImportWizardState state,
    _ImportWizardNotifier notifier,
  ) {
    switch (state.currentStep) {
      case 0:
        return _StepSelectFile(notifier: notifier, state: state);
      case 1:
        return _StepDetectFields(notifier: notifier, state: state);
      case 2:
        return _StepMapFields(notifier: notifier, state: state);
      case 3:
        return _StepPreview(notifier: notifier, state: state);
      case 4:
        return _StepConfirm(notifier: notifier, state: state);
      case 5:
        return _StepComplete(state: state);
      default:
        return _StepSelectFile(notifier: notifier, state: state);
    }
  }
}

/// Step 1: Select file
class _StepSelectFile extends ConsumerWidget {
  final _ImportWizardNotifier notifier;
  final _ImportWizardState state;

  const _StepSelectFile({required this.notifier, required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'مرحله‌ی 1: انتخاب فایل',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Text(
            'لطفا یک فایل CSV یا JSON حاوی داده‌های وام خود را انتخاب کنید.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 32),
          if (state.selectedFilePath == null)
            Column(
              children: [
                ElevatedButton.icon(
                  onPressed: () => _selectFile(context, ref),
                  icon: const Icon(Icons.upload_file),
                  label: const Text('انتخاب فایل'),
                ),
                const SizedBox(height: 16),
                Text(
                  'فرمت‌های پشتیبانی‌شده: CSV, JSON',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green),
                        const SizedBox(height: 8),
                        Text(
                          'فایل انتخاب‌شده:',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          state.selectedFilePath!.split('/').last,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _selectFile(context, ref),
                  child: const Text('تغییر فایل'),
                ),
              ],
            ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('لغو'),
              ),
              ElevatedButton(
                onPressed: state.selectedFilePath != null
                    ? () => _nextStep(context, ref)
                    : null,
                child: const Text('ادامه'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _selectFile(BuildContext context, WidgetRef ref) async {
    try {
      // TODO: Implement file picker integration when file_picker is added
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('انتخاب فایل هنوز پیاده‌سازی نشده است')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطا: $e')));
      }
    }
  }

  void _nextStep(BuildContext context, WidgetRef ref) {
    notifier.setStep(1);
  }

  // Removed: _readFileContent method (unused)
}

/// Step 2: Detect CSV headers
class _StepDetectFields extends ConsumerWidget {
  final _ImportWizardNotifier notifier;
  final _ImportWizardState state;

  const _StepDetectFields({required this.notifier, required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'مرحله‌ی 2: تشخیص ستون‌ها',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Text(
            'ستون‌های آشکار‌شده از فایل CSV:',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: state.detectedFields.isEmpty
                ? Center(
                    child: Text(
                      'در حال تشخیص ستون‌ها...',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  )
                : ListView.builder(
                    itemCount: state.detectedFields.length,
                    itemBuilder: (context, index) {
                      final field = state.detectedFields[index];
                      return ListTile(
                        title: Text(field.columnName),
                        subtitle: Text(field.fieldType.toString()),
                        trailing: field.isRequired
                            ? const Tooltip(
                                message: 'فیلد ضروری',
                                child: Icon(Icons.info, size: 16),
                              )
                            : null,
                      );
                    },
                  ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () => notifier.setStep(0),
                child: const Text('بازگشت'),
              ),
              ElevatedButton(
                onPressed: () => notifier.setStep(2),
                child: const Text('ادامه'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Step 3: Map fields
class _StepMapFields extends ConsumerWidget {
  final _ImportWizardNotifier notifier;
  final _ImportWizardState state;

  const _StepMapFields({required this.notifier, required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'مرحله‌ی 3: تنظیم نگاشت ستون‌ها',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Text(
            'هر ستون را به یک فیلد مناسب نسبت دهید:',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: state.detectedFields.length,
              itemBuilder: (context, index) {
                final field = state.detectedFields[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          field.columnName,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        DropdownButton<ImportFieldType>(
                          value: field.fieldType,
                          isExpanded: true,
                          items: ImportFieldType.values
                              .map(
                                (type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(type.toString().split('.').last),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            // Update field mapping
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () => notifier.setStep(1),
                child: const Text('بازگشت'),
              ),
              ElevatedButton(
                onPressed: () => notifier.setStep(3),
                child: const Text('ادامه'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Step 4: Preview data
class _StepPreview extends ConsumerWidget {
  final _ImportWizardNotifier notifier;
  final _ImportWizardState state;

  const _StepPreview({required this.notifier, required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'مرحله‌ی 4: پیش‌نمایش داده‌ها',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          if (state.preview == null)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'در حال تجزیه‌ی داده‌ها...',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PreviewCard(
                      title: 'طرف‌های معاملات',
                      count: state.preview!.counterpartiesToAdd.length,
                      icon: Icons.person,
                    ),
                    const SizedBox(height: 12),
                    _PreviewCard(
                      title: 'وام‌ها',
                      count: state.preview!.loansToAdd.length,
                      icon: Icons.assignment,
                    ),
                    const SizedBox(height: 12),
                    _PreviewCard(
                      title: 'اقساط',
                      count: state.preview!.installmentsToAdd.length,
                      icon: Icons.calendar_today,
                    ),
                    if (state.preview!.detectedConflicts.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Card(
                        color: Colors.orange.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'تعارض‌های شناسایی‌شده',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: Colors.orange.shade900,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${state.preview!.detectedConflicts.length} تعارض شناسایی شد',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () => notifier.setStep(2),
                child: const Text('بازگشت'),
              ),
              ElevatedButton(
                onPressed: state.preview != null
                    ? () => notifier.setStep(4)
                    : null,
                child: const Text('ادامه'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;

  const _PreviewCard({
    required this.title,
    required this.count,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: Colors.blue),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  '$count مورد',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Step 5: Confirm and import
class _StepConfirm extends ConsumerWidget {
  final _ImportWizardNotifier notifier;
  final _ImportWizardState state;

  const _StepConfirm({required this.notifier, required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'مرحله‌ی 5: تأیید درون‌ریز',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Text(
            'آیا اطلاعات درون‌ریز را تأیید می‌کنید؟',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ConfirmRow(
                      'طرف‌های معاملات:',
                      '${state.preview?.counterpartiesToAdd.length ?? 0}',
                    ),
                    const SizedBox(height: 8),
                    _ConfirmRow(
                      'وام‌ها:',
                      '${state.preview?.loansToAdd.length ?? 0}',
                    ),
                    const SizedBox(height: 8),
                    _ConfirmRow(
                      'اقساط:',
                      '${state.preview?.installmentsToAdd.length ?? 0}',
                    ),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(
                      'توجه: این عملیات قابل برگشت نیست. لطفا قبل از ادامه مطمئن شوید.',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.red),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () => notifier.setStep(3),
                child: const Text('بازگشت'),
              ),
              ElevatedButton.icon(
                onPressed: () => _performImport(context, ref),
                icon: const Icon(Icons.check),
                label: const Text('درون‌ریز'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _performImport(BuildContext context, WidgetRef ref) async {
    try {
      notifier.setStep(5);
      // Perform actual import here
      await Future.delayed(const Duration(seconds: 2)); // Simulate work
      final result = ImportResult(
        success: true,
        loansImported: state.preview?.loansToAdd.length ?? 0,
        counterpartiesImported: state.preview?.counterpartiesToAdd.length ?? 0,
        installmentsImported: state.preview?.installmentsToAdd.length ?? 0,
        completedAt: DateTime.now(),
      );
      notifier.setResult(result);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطا: $e')));
      }
    }
  }
}

class _ConfirmRow extends StatelessWidget {
  final String label;
  final String value;

  const _ConfirmRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
      ],
    );
  }
}

/// Step 6: Complete
class _StepComplete extends ConsumerWidget {
  final _ImportWizardState state;

  const _StepComplete({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = state.result;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            result?.success == true ? Icons.check_circle : Icons.error,
            color: result?.success == true ? Colors.green : Colors.red,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            result?.success == true ? 'درون‌ریز موفق‌آمیز' : 'درون‌ریز ناموفق',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: result?.success == true ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            result?.summary ?? '',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, result?.success),
            icon: const Icon(Icons.home),
            label: const Text('بازگشت به خانه'),
          ),
        ],
      ),
    );
  }
}
