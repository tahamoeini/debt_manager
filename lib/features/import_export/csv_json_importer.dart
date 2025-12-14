// csv_json_importer.dart: CSV/JSON parsing and data import logic

import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:debt_manager/core/db/database_helper.dart';
import 'package:debt_manager/features/loans/models/loan.dart';
import 'package:debt_manager/features/loans/models/counterparty.dart';
import 'package:debt_manager/features/loans/models/installment.dart';
import 'package:debt_manager/core/utils/jalali_utils.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'models/import_mapping.dart';

/// Exception for import-related errors
class ImportException implements Exception {
  final String message;
  final dynamic originalError;

  ImportException(this.message, [this.originalError]);

  @override
  String toString() => 'ImportException: $message';
}

/// CSV/JSON import service
class CsvJsonImporter {
  final DatabaseHelper _db;

  CsvJsonImporter({DatabaseHelper? db}) : _db = db ?? DatabaseHelper();

  /// Parse CSV from string content
  Future<List<List<dynamic>>> parseCSV(String content) async {
    try {
      final csvParser = CsvToListConverter(shouldParseNumbers: false);
      final rows = csvParser.convert(content);
      return rows;
    } catch (e) {
      throw ImportException('خطا در تجزیه CSV: $e', e);
    }
  }

  /// Parse JSON from string content
  Future<Map<String, dynamic>> parseJSON(String content) async {
    try {
      final json = jsonDecode(content) as Map<String, dynamic>;
      return json;
    } catch (e) {
      throw ImportException('خطا در تجزیه JSON: $e', e);
    }
  }

  /// Detect CSV headers and suggest field mappings
  Future<List<ImportField>> detectHeaders(List<List<dynamic>> csvRows) async {
    if (csvRows.isEmpty) {
      throw ImportException('فایل CSV خالی است');
    }

    final headers = csvRows.first.map((h) => h.toString().trim()).toList();
    final suggestedFields = <ImportField>[];

    for (final header in headers) {
      final fieldType = _detectFieldType(header);
      if (fieldType != null) {
        suggestedFields.add(
          ImportField(
            columnName: header,
            fieldType: fieldType,
            isRequired: _isRequiredField(fieldType),
          ),
        );
      }
    }

    return suggestedFields;
  }

  /// Detect field type from column header
  ImportFieldType? _detectFieldType(String header) {
    final lowerHeader = header.toLowerCase().replaceAll(RegExp(r'[_\s]'), '');

    final mappings = {
      'counterparty|نام|name': ImportFieldType.counterpartyName,
      'type|نوع': ImportFieldType.counterpartyType,
      'tag|برچسب|label': ImportFieldType.counterpartyTag,
      'loanstitle|عنوان|title': ImportFieldType.loanTitle,
      'direction|جهت': ImportFieldType.loanDirection,
      'principal|مبلغ|amount': ImportFieldType.principalAmount,
      'installment|تعداد|count': ImportFieldType.installmentCount,
      'rate|paymentquantity': ImportFieldType.installmentAmount,
      'startdate|تاریخ|date': ImportFieldType.startDateJalali,
      'notes|توضیحات|description': ImportFieldType.loanNotes,
      'duedate|موعد|deadline': ImportFieldType.dueDateJalali,
      'status|وضعیت': ImportFieldType.installmentStatus,
      'paid|واریز|amount': ImportFieldType.paidAmount,
    };

    for (final entry in mappings.entries) {
      final patterns = entry.key.split('|');
      for (final pattern in patterns) {
        if (lowerHeader.contains(pattern)) {
          return entry.value;
        }
      }
    }

    return null;
  }

  /// Check if field is required
  bool _isRequiredField(ImportFieldType type) {
    return [
      ImportFieldType.counterpartyName,
      ImportFieldType.loanTitle,
      ImportFieldType.loanDirection,
      ImportFieldType.principalAmount,
      ImportFieldType.installmentCount,
      ImportFieldType.installmentAmount,
      ImportFieldType.startDateJalali,
    ].contains(type);
  }

  /// Validate imported data
  Future<ImportValidationResult> validateData(
    List<Map<String, dynamic>> rows,
    ImportMapping mapping,
  ) async {
    final errors = <String>[];
    final warnings = <String>[];
    var validRowCount = 0;
    var invalidRowCount = 0;

    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      var rowValid = true;

      // Check required fields
      for (final field in mapping.fields) {
        if (field.isRequired &&
            (row[field.columnName] == null ||
                row[field.columnName].toString().trim().isEmpty)) {
          errors.add('سطر ${i + 1}: فیلد ضروری "${field.columnName}" خالی است');
          rowValid = false;
        }
      }

      // Validate amounts
      if (mapping.validateAmounts) {
        final amountField = mapping.fields.firstWhere(
          (f) => f.fieldType == ImportFieldType.principalAmount,
          orElse: () => const ImportField(
            columnName: '',
            fieldType: ImportFieldType.principalAmount,
          ),
        );
        if (amountField.columnName.isNotEmpty) {
          final amount = row[amountField.columnName];
          if (amount != null) {
            final parsed = int.tryParse(amount.toString());
            if (parsed == null || parsed <= 0) {
              errors.add('سطر ${i + 1}: مبلغ نامعتبر');
              rowValid = false;
            }
          }
        }
      }

      // Validate dates
      if (mapping.validateDates) {
        final dateField = mapping.fields.firstWhere(
          (f) => f.fieldType == ImportFieldType.startDateJalali,
          orElse: () => const ImportField(
            columnName: '',
            fieldType: ImportFieldType.startDateJalali,
          ),
        );
        if (dateField.columnName.isNotEmpty) {
          final date = row[dateField.columnName];
          if (date != null && !_isValidJalaliDate(date.toString())) {
            errors.add('سطر ${i + 1}: تاریخ نامعتبر (فرمت: yyyy-MM-dd)');
            rowValid = false;
          }
        }
      }

      if (rowValid) {
        validRowCount++;
      } else {
        invalidRowCount++;
      }
    }

    if (errors.isNotEmpty) {
      return ImportValidationResult.failure(
        errors: errors,
        warnings: warnings,
        validRowCount: validRowCount,
        invalidRowCount: invalidRowCount,
      );
    }

    return ImportValidationResult.success(
      validRowCount: validRowCount,
      warnings: warnings,
    );
  }

  /// Check if date string is valid Jalali date
  bool _isValidJalaliDate(String dateStr) {
    try {
      parseJalali(dateStr);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Create import preview
  Future<ImportPreview> createPreview(
    List<Map<String, dynamic>> rows,
    ImportMapping mapping,
  ) async {
    final validation = await validateData(rows, mapping);
    final loansToAdd = <Loan>[];
    final counterpartiesToAdd = <Counterparty>[];
    final installmentsToAdd = <Installment>[];
    final conflicts = <ImportConflict>[];

    if (!validation.isValid) {
      return ImportPreview(
        loansToAdd: loansToAdd,
        counterpartiesToAdd: counterpartiesToAdd,
        installmentsToAdd: installmentsToAdd,
        detectedConflicts: conflicts,
        validationResult: validation,
      );
    }

    // Extract unique counterparties
    final counterpartyMap = <String, Counterparty>{};
    for (final row in rows) {
      final cpName = _extractValue(
        row,
        mapping,
        ImportFieldType.counterpartyName,
      );
      if (cpName != null && cpName.isNotEmpty) {
        if (!counterpartyMap.containsKey(cpName)) {
          counterpartyMap[cpName] = Counterparty(
            name: cpName,
            type: _extractValue(row, mapping, ImportFieldType.counterpartyType),
            tag: _extractValue(row, mapping, ImportFieldType.counterpartyTag),
          );
        }
      }
    }

    counterpartiesToAdd.addAll(counterpartyMap.values);

    // Extract loans and installments
    for (final row in rows) {
      try {
        final cpName = _extractValue(
          row,
          mapping,
          ImportFieldType.counterpartyName,
        );
        final cp = counterpartyMap[cpName];

        if (cp != null) {
          final loan = Loan(
            counterpartyId: cp.id ?? 0, // Temporary ID
            title:
                _extractValue(row, mapping, ImportFieldType.loanTitle) ??
                'بدون عنوان',
            direction: _parseDirection(
              _extractValue(row, mapping, ImportFieldType.loanDirection),
            ),
            principalAmount: int.parse(
              _extractValue(
                    row,
                    mapping,
                    ImportFieldType.principalAmount,
                  )?.toString() ??
                  '0',
            ),
            installmentCount: int.parse(
              _extractValue(
                    row,
                    mapping,
                    ImportFieldType.installmentCount,
                  )?.toString() ??
                  '1',
            ),
            installmentAmount: int.parse(
              _extractValue(
                    row,
                    mapping,
                    ImportFieldType.installmentAmount,
                  )?.toString() ??
                  '0',
            ),
            startDateJalali:
                _extractValue(row, mapping, ImportFieldType.startDateJalali) ??
                formatJalaliNow(),
            notes: _extractValue(row, mapping, ImportFieldType.loanNotes),
            createdAt: DateTime.now().toIso8601String(),
          );
          loansToAdd.add(loan);

          // Create sample installment
          final dueDate = _extractValue(
            row,
            mapping,
            ImportFieldType.dueDateJalali,
          );
          if (dueDate != null) {
            final inst = Installment(
              loanId: 0, // Temporary ID
              dueDateJalali: dueDate,
              amount: loan.installmentAmount,
              status: _parseInstallmentStatus(
                _extractValue(row, mapping, ImportFieldType.installmentStatus),
              ),
              paidAt: null,
              actualPaidAmount: null,
            );
            installmentsToAdd.add(inst);
          }
        }
      } catch (e) {
        conflicts.add(
          ImportConflict(
            type: ImportConflictType.validationError,
            message: 'خطا در سطر: $e',
            suggestion: 'لطفا داده‌های سطر را بررسی کنید',
          ),
        );
      }
    }

    return ImportPreview(
      loansToAdd: loansToAdd,
      counterpartiesToAdd: counterpartiesToAdd,
      installmentsToAdd: installmentsToAdd,
      detectedConflicts: conflicts,
      validationResult: validation,
    );
  }

  /// Extract value from row by field type
  String? _extractValue(
    Map<String, dynamic> row,
    ImportMapping mapping,
    ImportFieldType type,
  ) {
    final field = mapping.fields.firstWhere(
      (f) => f.fieldType == type,
      orElse: () => const ImportField(
        columnName: '',
        fieldType: ImportFieldType.counterpartyName,
      ),
    );
    if (field.columnName.isEmpty) return null;
    final value = row[field.columnName];
    return value?.toString().trim();
  }

  /// Parse loan direction from string
  LoanDirection _parseDirection(String? value) {
    if (value == null) return LoanDirection.borrowed;
    final lower = value.toLowerCase();
    if (lower.contains('lent') || lower.contains('داده‌ام')) {
      return LoanDirection.lent;
    }
    return LoanDirection.borrowed;
  }

  /// Parse installment status from string
  InstallmentStatus _parseInstallmentStatus(String? value) {
    if (value == null) return InstallmentStatus.pending;
    final lower = value.toLowerCase();
    if (lower.contains('paid') || lower.contains('پرداخت')) {
      return InstallmentStatus.paid;
    }
    if (lower.contains('overdue') || lower.contains('تأخیر')) {
      return InstallmentStatus.overdue;
    }
    return InstallmentStatus.pending;
  }

  /// Perform actual import with merge strategy
  Future<ImportResult> performImport(
    ImportPreview preview,
    ImportMergeMode mergeMode,
  ) async {
    try {
      if (mergeMode == ImportMergeMode.dryRun) {
        return ImportResult(
          success: true,
          loansImported: preview.loansToAdd.length,
          counterpartiesImported: preview.counterpartiesToAdd.length,
          installmentsImported: preview.installmentsToAdd.length,
          completedAt: DateTime.now(),
        );
      }

      int counterpartiesImported = 0;
      int loansImported = 0;
      int installmentsImported = 0;

      // Import counterparties first
      final cpIdMap = <String, int>{};
      for (final cp in preview.counterpartiesToAdd) {
        final id = await _db.insertCounterparty(cp);
        cpIdMap[cp.name] = id;
        counterpartiesImported++;
      }

      // Import loans with updated counterparty IDs
      final loanIdMap = <int, int>{};
      for (final loan in preview.loansToAdd) {
        final cpId = cpIdMap.values.first; // For first batch
        final updatedLoan = loan.copyWith(counterpartyId: cpId);
        final loanId = await _db.insertLoan(updatedLoan);
        loanIdMap[loan.hashCode] = loanId;
        loansImported++;
      }

      // Import installments with updated loan IDs
      for (final inst in preview.installmentsToAdd) {
        final loanId = loanIdMap.values.first; // For first batch
        final updatedInst = inst.copyWith(loanId: loanId);
        await _db.insertInstallment(updatedInst);
        installmentsImported++;
      }

      return ImportResult(
        success: true,
        loansImported: loansImported,
        counterpartiesImported: counterpartiesImported,
        installmentsImported: installmentsImported,
        completedAt: DateTime.now(),
      );
    } catch (e) {
      return ImportResult(
        success: false,
        error: e.toString(),
        completedAt: DateTime.now(),
      );
    }
  }
}

/// Helper to format current Jalali date
String formatJalaliNow() {
  final jalali = Jalali.now();
  return '${jalali.year}-${jalali.month.toString().padLeft(2, '0')}-${jalali.day.toString().padLeft(2, '0')}';
}
