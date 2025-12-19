import 'dart:typed_data';

import 'package:debt_manager/core/backup/backup_service.dart' as plain_backup;
import 'package:debt_manager/core/privacy/backup_service.dart' as qr_backup;
import 'package:debt_manager/core/privacy/privacy_gateway.dart';
import 'package:debt_manager/features/settings/backup_restore_service.dart';
import 'package:debt_manager/core/models/backup_payload.dart';

/// Facade exposing a single backup API surface over multiple implementations.
class BackupFacade {
  BackupFacade._();
  static final BackupFacade instance = BackupFacade._();

  // -------- Plain JSON (Developer Tools) --------
  Future<String> exportPlainJson() async {
    return await plain_backup.BackupService.instance.exportAll();
  }

  Future<void> importPlainJson(String jsonString,
      {bool clearBefore = true}) async {
    await plain_backup.BackupService.instance
        .importFromJsonString(jsonString, clearBefore: clearBefore);
  }

  // -------- Encrypted ZIP (File backup) --------
  Future<String> exportEncryptedZip({
    required String password,
    String? backupName,
    String? directory,
  }) async {
    final svc = BackupRestoreService();
    return await svc.exportData(
      backupName: backupName,
      backupDirectory: directory,
      password: password,
    );
  }

  Future<List<BackupConflict>> importEncryptedZip({
    required String filePath,
    required String password,
    BackupMergeMode mode = BackupMergeMode.dryRun,
    Function(List<BackupConflict>)? onConflicts,
  }) async {
    final svc = BackupRestoreService();
    return await svc.importData(
      filePath,
      mode: mode,
      conflictCallback: onConflicts,
      password: password,
    );
  }

  // -------- QR Bytes (encrypted+compressed) --------
  Future<Uint8List> exportQrBytes(String password) async {
    return await qr_backup.BackupService.exportEncryptedCompressedBytes(
        password);
  }

  /// Decrypt QR wrapper bytes to a JSON string (without importing).
  Future<String> decryptQrBytesToJson(
      Uint8List wrapperBytes, String password) async {
    return await qr_backup.BackupService.decryptCompressedBytes(
        wrapperBytes, password);
  }

  /// Convenience: decrypt QR wrapper and import the contained JSON.
  Future<void> importQrBytes(Uint8List wrapperBytes, String password) async {
    final jsonStr = await decryptQrBytesToJson(wrapperBytes, password);
    await PrivacyGateway.instance.importJsonString(jsonStr);
  }
}
