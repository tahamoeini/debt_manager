// Backup service: export/import app data as JSON (counterparties, loans, installments).
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:debt_manager/core/db/database_helper.dart';
import 'package:debt_manager/features/loans/models/counterparty.dart';
import 'package:debt_manager/features/loans/models/loan.dart';
import 'package:debt_manager/features/loans/models/installment.dart';
import 'package:debt_manager/core/notifications/notification_service.dart';

class BackupService {
  static final BackupService instance = BackupService._internal();
  BackupService._internal();

  final _db = DatabaseHelper.instance;

  void _assertDebugAllowed() {
    if (!kDebugMode) {
      throw StateError('Plaintext backup is only available in debug builds.');
    }
  }

  // Export all data as a JSON string with three arrays: counterparties, loans, installments.
  Future<String> exportAll() async {
    _assertDebugAllowed();
    final cps = await _db.getAllCounterparties();
    final loans = await _db.getAllLoans();

    final List<Map<String, dynamic>> cpMaps =
        cps.map((c) => c.toMap()).toList();

    final List<Map<String, dynamic>> loanMaps =
        loans.map((l) => l.toMap()).toList();

    final List<Map<String, dynamic>> instMaps = [];
    for (final loan in loans) {
      if (loan.id == null) continue;
      final insts = await _db.getInstallmentsByLoanId(loan.id!);
      instMaps.addAll(insts.map((i) => i.toMap()));
    }

    final out = {
      'counterparties': cpMaps,
      'loans': loanMaps,
      'installments': instMaps,
    };

    return const JsonEncoder.withIndent('  ').convert(out);
  }

  // Import JSON data. By default clears existing data and inserts everything
  // from the provided map. Expects the same structure produced by [exportAll].
  Future<void> importFromMap(
    Map<String, dynamic> json, {
    bool clearBefore = true,
  }) async {
    _assertDebugAllowed();
    // Basic validation
    if (!json.containsKey('counterparties') ||
        !json.containsKey('loans') ||
        !json.containsKey('installments')) {
      throw ArgumentError('Invalid backup format: missing top-level keys');
    }

    final cps = (json['counterparties'] as List).cast<Map<String, dynamic>>();
    final loans = (json['loans'] as List).cast<Map<String, dynamic>>();
    final insts = (json['installments'] as List).cast<Map<String, dynamic>>();

    // Clear existing data if requested. We delete loans via helper which also
    // cancels and deletes installments.
    if (clearBefore) {
      final existing = await _db.getAllLoans();
      for (final l in existing) {
        if (l.id != null) {
          await _db.deleteLoanWithInstallments(l.id!);
        }
      }
    }

    // Insert counterparties first
    for (final cpMap in cps) {
      final cp = Counterparty.fromMap(cpMap);
      await _db.insertCounterparty(cp);
    }

    // Insert loans
    for (final loanMap in loans) {
      final loan = Loan.fromMap(loanMap);
      await _db.insertLoan(loan);
    }

    // Insert installments
    for (final instMap in insts) {
      final inst = Installment.fromMap(instMap);
      await _db.insertInstallment(inst);
    }

    // Rebuild notifications after import to ensure future installments have reminders
    try {
      await NotificationService.instance.rebuildScheduledNotifications();
    } catch (e) {
      debugPrint('Failed to rebuild notifications after import: $e');
    }
  }

  // Convenience: import from a JSON string.
  Future<void> importFromJsonString(
    String jsonString, {
    bool clearBefore = true,
  }) async {
    _assertDebugAllowed();
    final parsed = json.decode(jsonString) as Map<String, dynamic>;
    await importFromMap(parsed, clearBefore: clearBefore);
  }
}
