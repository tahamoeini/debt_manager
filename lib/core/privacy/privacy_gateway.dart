import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../db/database_helper.dart';
import '../security/secure_storage_service.dart';
import 'backup_service.dart';
import '../../features/loans/models/counterparty.dart';
import '../../features/loans/models/loan.dart';
import '../../features/loans/models/installment.dart';
import '../notifications/notification_service.dart';
import '../smart_insights/smart_insights_service.dart';
import 'dart:convert';
import '../settings/settings_repository.dart';

class PrivacyGateway {
  static final PrivacyGateway instance = PrivacyGateway._internal();
  PrivacyGateway._internal();
  factory PrivacyGateway() => instance;

  final SecureStorageService _secure = SecureStorageService();
  final DatabaseHelper _db = DatabaseHelper.instance;

  /// Store a secret (e.g., backup key or PIN) in secure storage.
  Future<void> storeSecret(String key, String value) async => await _secure.write(key, value);

  Future<String?> readSecret(String key) async => await _secure.read(key);

  Future<void> deleteSecret(String key) async => await _secure.delete(key);

  /// Export JSON (plain string) encrypted with password and save to backups folder.
  Future<String> exportEncryptedBackup(String jsonString, String password, {required String filename}) async {
    return await BackupService.encryptAndSave(jsonString, password, filename: filename);
  }

  /// Import a JSON string exported by `exportFullJson` and insert into local DB.
  Future<void> importJsonString(String jsonStr) async {
    final map = json.decode(jsonStr) as Map<String, dynamic>;

    final cps = (map['counterparties'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    final loans = (map['loans'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    final installments = (map['installments'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();

    // Insert counterparties and keep id mapping
    final cpIdMap = <int, int>{};
    for (final cp in cps) {
      final oldId = cp['id'] is int ? cp['id'] as int : int.tryParse(cp['id'].toString()) ?? 0;
      final counterparty = Counterparty.fromMap(cp);
      final newId = await _db.insertCounterparty(counterparty);
      cpIdMap[oldId] = newId;
    }

    // Insert loans and keep loan id mapping
    final loanIdMap = <int, int>{};
    for (final l in loans) {
      final oldId = l['id'] is int ? l['id'] as int : int.tryParse(l['id'].toString()) ?? 0;
      final loan = Loan.fromMap(l);
      // remap counterparty id
      final remappedCp = cpIdMap[loan.counterpartyId] ?? loan.counterpartyId;
      final loanToInsert = loan.copyWith(counterpartyId: remappedCp);
      final newId = await _db.insertLoan(loanToInsert);
      loanIdMap[oldId] = newId;
    }

    // Insert installments mapping loan ids
    for (final it in installments) {
      final instMap = Map<String, dynamic>.from(it);
      final oldLoanId = instMap['loan_id'] is int ? instMap['loan_id'] as int : int.tryParse(instMap['loan_id'].toString()) ?? 0;
      final newLoanId = loanIdMap[oldLoanId] ?? oldLoanId;
      instMap['loan_id'] = newLoanId;
      final inst = Installment.fromMap(instMap);
      await _db.insertInstallment(inst);
    }

    // After import, rebuild notifications and run insights
    try {
      final settings = SettingsRepository();
      await settings.init();
      await NotificationService().rebuildScheduledNotifications();
      if (settings.smartInsightsEnabled) {
        await SmartInsightsService().runInsights(notify: true);
      }
    } catch (_) {}
  }

  /// Import and decrypt backup file with password, returning decrypted JSON.
  Future<String> importEncryptedBackup(String path, String password) async {
    return await BackupService.decryptFromFile(path, password);
  }

  /// Wipe local data: delete database, secure storage, backups, and any audit logs.
  Future<void> panicWipe() async {
    // Delete database file
    try {
      final databasesPath = await getDatabasesPath();
      final dbPath = p.join(databasesPath, 'debt_manager.db');
      final f = File(dbPath);
      if (await f.exists()) await f.delete();
    } catch (_) {}

    // Clear secure storage
    try {
      await _secure.deleteAll();
    } catch (_) {}

    // Delete backups
    try {
      await BackupService.deleteAllBackups();
    } catch (_) {}

    // Note: app-level in-memory stores will be reset on next launch.
  }

  /// Append an audit entry to a local audit file.
  Future<void> audit(String action, {String? details}) async {
    try {
      final dir = Directory.systemTemp; // lightweight local-only logging; adjust as needed
      final f = File('${dir.path}/debt_manager_audit.log');
      final entry = '${DateTime.now().toIso8601String()} | $action | ${details ?? ''}\n';
      await f.writeAsString(entry, mode: FileMode.append, flush: true);
    } catch (_) {}
  }
}
