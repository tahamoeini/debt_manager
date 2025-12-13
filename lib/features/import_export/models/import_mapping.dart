// import_mapping.dart: DTOs for CSV/JSON import configuration and validation

import 'package:flutter/foundation.dart';
import 'package:debt_manager/features/loans/models/loan.dart';
import 'package:debt_manager/features/loans/models/counterparty.dart';
import 'package:debt_manager/features/loans/models/installment.dart';

/// Represents a field that can be imported from CSV/JSON
enum ImportFieldType {
  counterpartyName,
  counterpartyType,
  counterpartyTag,
  loanTitle,
  loanDirection,
  principalAmount,
  installmentCount,
  installmentAmount,
  startDateJalali,
  loanNotes,
  dueDateJalali,
  installmentStatus,
  paidAmount,
  installmentNotes,
}

/// Maps a CSV column to an importable field
@immutable
class ImportField {
  final String columnName;
  final ImportFieldType fieldType;
  final bool isRequired;
  final String? description;

  const ImportField({
    required this.columnName,
    required this.fieldType,
    this.isRequired = false,
    this.description,
  });

  @override
  String toString() => 'ImportField($columnName -> $fieldType)';
}

/// Complete mapping configuration for an import session
@immutable
class ImportMapping {
  final List<ImportField> fields;
  final ImportMergeMode mergeMode;
  final bool skipDuplicates;
  final bool validateAmounts;
  final bool validateDates;
  final String? description;

  const ImportMapping({
    required this.fields,
    this.mergeMode = ImportMergeMode.merge,
    this.skipDuplicates = true,
    this.validateAmounts = true,
    this.validateDates = true,
    this.description,
  });

  ImportMapping copyWith({
    List<ImportField>? fields,
    ImportMergeMode? mergeMode,
    bool? skipDuplicates,
    bool? validateAmounts,
    bool? validateDates,
    String? description,
  }) {
    return ImportMapping(
      fields: fields ?? this.fields,
      mergeMode: mergeMode ?? this.mergeMode,
      skipDuplicates: skipDuplicates ?? this.skipDuplicates,
      validateAmounts: validateAmounts ?? this.validateAmounts,
      validateDates: validateDates ?? this.validateDates,
      description: description ?? this.description,
    );
  }
}

/// Strategy for handling conflicts during merge
enum ImportMergeMode {
  /// Replace all existing data
  replace,

  /// Only add new items (skip duplicates)
  merge,

  /// Keep newer items (by timestamp)
  mergeWithNewerWins,

  /// Keep existing items
  mergeWithExistingWins,

  /// Check without importing
  dryRun,
}

/// Result of validating imported data
@immutable
class ImportValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;
  final int validRowCount;
  final int invalidRowCount;

  const ImportValidationResult({
    required this.isValid,
    this.errors = const [],
    this.warnings = const [],
    this.validRowCount = 0,
    this.invalidRowCount = 0,
  });

  factory ImportValidationResult.success({
    required int validRowCount,
    List<String> warnings = const [],
  }) {
    return ImportValidationResult(
      isValid: true,
      errors: const [],
      warnings: warnings,
      validRowCount: validRowCount,
      invalidRowCount: 0,
    );
  }

  factory ImportValidationResult.failure({
    required List<String> errors,
    List<String> warnings = const [],
    int validRowCount = 0,
    int invalidRowCount = 0,
  }) {
    return ImportValidationResult(
      isValid: false,
      errors: errors,
      warnings: warnings,
      validRowCount: validRowCount,
      invalidRowCount: invalidRowCount,
    );
  }

  String get summary {
    if (isValid) {
      return 'معتبر: $validRowCount سطر';
    } else {
      return 'نامعتبر: ${errors.length} خطا';
    }
  }
}

/// Progress tracking for import operations
@immutable
class ImportProgress {
  final int totalRows;
  final int processedRows;
  final int successfulRows;
  final int failedRows;
  final String? currentMessage;
  final bool isComplete;

  const ImportProgress({
    required this.totalRows,
    this.processedRows = 0,
    this.successfulRows = 0,
    this.failedRows = 0,
    this.currentMessage,
    this.isComplete = false,
  });

  double get progress =>
      totalRows <= 0 ? 0.0 : processedRows / totalRows.toDouble();

  ImportProgress copyWith({
    int? totalRows,
    int? processedRows,
    int? successfulRows,
    int? failedRows,
    String? currentMessage,
    bool? isComplete,
  }) {
    return ImportProgress(
      totalRows: totalRows ?? this.totalRows,
      processedRows: processedRows ?? this.processedRows,
      successfulRows: successfulRows ?? this.successfulRows,
      failedRows: failedRows ?? this.failedRows,
      currentMessage: currentMessage ?? this.currentMessage,
      isComplete: isComplete ?? this.isComplete,
    );
  }

  @override
  String toString() =>
      'ImportProgress($processedRows/$totalRows, success: $successfulRows, failed: $failedRows)';
}

/// Represents a conflict detected during import
@immutable
class ImportConflict {
  final ImportConflictType type;
  final String message;
  final dynamic originalValue;
  final dynamic importedValue;
  final String? suggestion;

  const ImportConflict({
    required this.type,
    required this.message,
    this.originalValue,
    this.importedValue,
    this.suggestion,
  });

  @override
  String toString() => 'ImportConflict($type: $message)';
}

/// Types of conflicts that can occur
enum ImportConflictType {
  /// Loan with same counterparty and dates
  duplicateLoan,

  /// Counterparty already exists with different details
  duplicateCounterparty,

  /// Installment already marked as paid
  duplicateInstallment,

  /// Data validation failed
  validationError,

  /// Missing required field
  missingField,

  /// Invalid date format
  invalidDate,

  /// Invalid amount
  invalidAmount,

  /// Unknown counterparty reference
  unknownCounterparty,
}

/// Preview of what will be imported
@immutable
class ImportPreview {
  final List<Loan> loansToAdd;
  final List<Counterparty> counterpartiesToAdd;
  final List<Installment> installmentsToAdd;
  final List<ImportConflict> detectedConflicts;
  final ImportValidationResult validationResult;

  const ImportPreview({
    required this.loansToAdd,
    required this.counterpartiesToAdd,
    required this.installmentsToAdd,
    required this.detectedConflicts,
    required this.validationResult,
  });

  int get totalItemsToImport =>
      loansToAdd.length + counterpartiesToAdd.length + installmentsToAdd.length;

  @override
  String toString() =>
      'ImportPreview(loans: ${loansToAdd.length}, counterparties: ${counterpartiesToAdd.length}, installments: ${installmentsToAdd.length}, conflicts: ${detectedConflicts.length})';
}

/// Summary of an import operation
@immutable
class ImportResult {
  final bool success;
  final int loansImported;
  final int counterpartiesImported;
  final int installmentsImported;
  final List<ImportConflict> unresolvedConflicts;
  final String? error;
  final DateTime completedAt;

  ImportResult({
    required this.success,
    this.loansImported = 0,
    this.counterpartiesImported = 0,
    this.installmentsImported = 0,
    this.unresolvedConflicts = const [],
    this.error,
    DateTime? completedAt,
  }) : completedAt = completedAt ?? DateTime(2000, 1, 1);

  int get totalImported =>
      loansImported + counterpartiesImported + installmentsImported;

  String get summary {
    if (success) {
      return 'موفقیت‌آمیز: $totalImported آیتم وارد شد';
    } else {
      return 'ناموفق: $error';
    }
  }

  @override
  String toString() =>
      'ImportResult(success: $success, loans: $loansImported, counterparties: $counterpartiesImported, installments: $installmentsImported)';
}
