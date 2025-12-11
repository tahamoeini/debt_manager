import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../security/local_auth_service.dart';
import 'backup_service.dart';
import '../privacy/privacy_gateway.dart';
import '../../notifications/notification_service.dart';
import '../../smart_insights/smart_insights_service.dart';

/// A small wrapper that enforces authentication and coordinates
/// export/import flows using the existing `BackupService` and
/// `PrivacyGateway` implementations.
class SecureBackupService {
  SecureBackupService._private();
  static final SecureBackupService instance = SecureBackupService._private();

  final _localAuth = LocalAuthService.instance;

  /// Create an encrypted (optionally password-protected) compressed
  /// backup and return the bytes ready to save or chunk for QR.
  /// If [requireAuth] is true, performs biometric/PIN authentication
  /// before exporting.
  Future<Uint8List> createEncryptedBackup({String? password, bool requireAuth = true}) async {
    if (requireAuth) {
      final ok = await _localAuth.authenticate(reason: 'Authenticate to export backup');
      if (!ok) throw Exception('Authentication required');
    }

    // Delegate to existing BackupService which already supports
    // compressed+encrypted exports. This keeps compatibility.
    return await BackupService.instance.exportEncryptedCompressedBytes(password: password);
  }

  /// Import encrypted/compressed bytes produced by `createEncryptedBackup`.
  /// If [requireAuth] is true, authenticate first. After successful
  /// import, rebuild notifications and re-run smart insights (non-notifying).
  Future<void> importEncryptedBackup(Uint8List encryptedCompressed, {String? password, bool requireAuth = true}) async {
    if (requireAuth) {
      final ok = await _localAuth.authenticate(reason: 'Authenticate to import backup');
      if (!ok) throw Exception('Authentication required');
    }

    // Decrypt and decompress to JSON string
    final json = await BackupService.instance.decryptCompressedBytes(encryptedCompressed, password: password);

    // Import via PrivacyGateway which handles remapping and DB insertion
    await PrivacyGateway.instance.importJsonString(json);

    // Rebuild notifications and insights
    await NotificationService.instance.rebuildScheduledNotifications();
    await SmartInsightsService.instance.runInsights(notify: false);
  }
}
