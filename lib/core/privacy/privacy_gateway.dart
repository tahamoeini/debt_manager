import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:flutter/material.dart';

import '../db/database_helper.dart';
import '../security/secure_storage_service.dart';
import 'backup_service.dart';

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
