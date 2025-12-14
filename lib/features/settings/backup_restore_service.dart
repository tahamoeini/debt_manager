import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:intl/intl.dart';
import 'package:debt_manager/core/db/database_helper.dart';
import 'package:debt_manager/core/models/backup_payload.dart';
import 'package:debt_manager/features/loans/models/installment.dart';
import 'package:path_provider/path_provider.dart';

/// Service for backing up and restoring database data
class BackupRestoreService {
  static final BackupRestoreService _instance =
      BackupRestoreService._internal();

  factory BackupRestoreService() {
    return _instance;
  }

  BackupRestoreService._internal();

  final _db = DatabaseHelper.instance;

  /// Export all database data as a compressed JSON file
  /// Returns path to the created backup file
  Future<String> exportData({
    String? backupName,
    String? backupDirectory,
  }) async {
    try {
      // Get all data from database
      final loans = await _db.getAllLoans();
      final counterparties = await _db.getAllCounterparties();

      // Get all installments
      final loanIds = loans.map((l) => l.id).whereType<int>().toList();
      final installmentsMap = loanIds.isNotEmpty
          ? await _db.getInstallmentsGroupedByLoanId(loanIds)
          : <int, List<Installment>>{};
      final allInstallments = installmentsMap.values.expand((l) => l).toList();

      // Get financial summary
      final totalBorrowed = await _db.getTotalOutstandingBorrowed();
      final totalLent = await _db.getTotalOutstandingLent();

      // Create backup data structure
      final backupData = {
        'loans': loans.map((l) => l.toMap()).toList(),
        'installments': allInstallments.map((i) => i.toMap()).toList(),
        'counterparties': counterparties.map((c) => c.toMap()).toList(),
        'budgets': [], // Future: implement budgets export
        'transactions': [], // Future: implement transactions export
      };

      // Calculate checksum
      final dataJson = jsonEncode(backupData);
      final checksum = sha256.convert(utf8.encode(dataJson)).toString();

      // Create metadata
      final now = DateTime.now();
      final metadata = BackupMetadata(
        loansCount: loans.length,
        installmentsCount: allInstallments.length,
        counterpartiesCount: counterparties.length,
        budgetsCount: 0,
        transactionsCount: 0,
        sizeBytes: utf8.encode(dataJson).length,
        netWorth: totalLent - totalBorrowed,
        totalBorrowed: totalBorrowed,
        totalLent: totalLent,
      );

      // Create backup payload
      final payload = BackupPayload(
        timestamp: now.toIso8601String(),
        appVersion: '1.0.0', // TODO: Get from pubspec or constants
        checksum: checksum,
        name:
            backupName ??
            'Backup-${DateFormat('yyyy-MM-dd-HHmmss').format(now)}',
        data: backupData,
        metadata: metadata,
      );

      // Serialize payload
      final payloadJson = jsonEncode(payload.toJson());
      final payloadBytes = utf8.encode(payloadJson);

      // Create zip archive
      final archive = Archive();
      archive.addFile(
        ArchiveFile('backup.json', payloadBytes.length, payloadBytes),
      );

      // Get directory to save backup
      final saveDir =
          backupDirectory ?? (await getApplicationDocumentsDirectory()).path;
      final backupFilePath = '$saveDir/${payload.name}.backup.zip';

      // Write zip file
      final zipEncoder = ZipEncoder();
      final zipBytes = zipEncoder.encode(archive);
      if (zipBytes.isEmpty) {
        throw Exception('Failed to encode backup');
      }

      final file = File(backupFilePath);
      await file.writeAsBytes(zipBytes);

      return backupFilePath;
    } catch (e) {
      throw Exception('Failed to export backup: $e');
    }
  }

  /// Import backup data from a file
  /// [filePath] - path to backup file
  /// [mode] - how to merge the backup data
  /// [conflictCallback] - optional callback for conflict resolution
  /// Returns list of conflicts (if any)
  Future<List<BackupConflict>> importData(
    String filePath, {
    BackupMergeMode mode = BackupMergeMode.dryRun,
    Function(List<BackupConflict> conflicts)? conflictCallback,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Backup file not found');
      }

      // Read and extract zip
      final zipBytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(zipBytes);

      // Find and read backup.json
      ArchiveFile? backupFile;
      for (final file in archive) {
        if (file.name == 'backup.json') {
          backupFile = file;
          break;
        }
      }

      if (backupFile == null) {
        throw Exception('Invalid backup file: backup.json not found');
      }

      // Parse backup payload
      final payloadJson = utf8.decode(backupFile.content as List<int>);
      final payloadMap = jsonDecode(payloadJson) as Map<String, dynamic>;
      final payload = BackupPayload.fromJson(payloadMap);

      // Validate checksum
      final dataJson = jsonEncode(payload.data);
      final calculatedChecksum = sha256
          .convert(utf8.encode(dataJson))
          .toString();
      if (calculatedChecksum != payload.checksum) {
        throw BackupIntegrityException(
          'Backup checksum mismatch. File may be corrupted.',
        );
      }

      // Check for conflicts
      final conflicts = await _checkForConflicts(payload);

      if (conflicts.isNotEmpty) {
        conflictCallback?.call(conflicts);

        // In dryRun mode, only report conflicts
        if (mode == BackupMergeMode.dryRun) {
          return conflicts;
        }
      }

      // Apply import based on mode
      if (mode == BackupMergeMode.replace) {
        await _replaceAllData(payload);
      } else if (mode == BackupMergeMode.merge) {
        await _mergeData(payload, mode);
      } else if (mode == BackupMergeMode.mergeWithNewerWins) {
        await _mergeData(payload, mode);
      } else if (mode == BackupMergeMode.mergeWithExistingWins) {
        await _mergeData(payload, mode);
      }

      return conflicts;
    } catch (e) {
      throw Exception('Failed to import backup: $e');
    }
  }

  /// Check for conflicts between backup and current database
  Future<List<BackupConflict>> _checkForConflicts(BackupPayload payload) async {
    final conflicts = <BackupConflict>[];

    // Check version compatibility
    if (payload.version > 1) {
      conflicts.add(
        BackupConflict(
          type: ConflictType.versionMismatch,
          message: 'Backup was created with a newer app version',
          resolution: 'Update the app or use the original version',
        ),
      );
    }

    // Compare timestamps
    final backupTime = DateTime.parse(payload.timestamp);
    final currentLoans = await _db.getAllLoans();

    if (currentLoans.isNotEmpty && backupTime.isBefore(DateTime.now())) {
      // Backup is older
      conflicts.add(
        BackupConflict(
          type: ConflictType.newerDatabase,
          message: 'Current database has newer data than backup',
          resolution: 'Review carefully before importing',
        ),
      );
    }

    return conflicts;
  }

  /// Replace all database data with backup data
  Future<void> _replaceAllData(BackupPayload payload) async {
    try {
      // Get existing data to delete
      final existingLoans = await _db.getAllLoans();

      // Delete all loans (which cascades to installments)
      for (final loan in existingLoans) {
        if (loan.id != null) {
          await _db.deleteLoanWithInstallments(loan.id!);
        }
      }

      // Delete counterparties
      final existingCounterparties = await _db.getAllCounterparties();
      for (final cp in existingCounterparties) {
        if (cp.id != null) {
          // Note: deleteLoan cascade should handle this, but if counterparties
          // are orphaned, we need a delete method for them
          // TODO: Add deleteCounterparty method to DatabaseHelper
        }
      }

      // Import counterparties first (foreign key dependency)
      final counterparties = payload.data['counterparties'] as List? ?? [];
      for (final _ in counterparties) {
        // TODO: Create Counterparty from map and insert
      }

      // Import loans (depends on counterparties)
      final loans = payload.data['loans'] as List? ?? [];
      for (final _ in loans) {
        // TODO: Create Loan from map and insert
      }

      // Import installments (depends on loans)
      final installments = payload.data['installments'] as List? ?? [];
      for (final _ in installments) {
        // TODO: Create Installment from map and insert
      }
    } catch (e) {
      throw Exception('Failed to replace database data: $e');
    }
  }

  /// Merge backup data with existing database
  Future<void> _mergeData(BackupPayload payload, BackupMergeMode mode) async {
    try {
      // Get existing data
      final existingLoans = await _db.getAllLoans();
      final existingCounterparties = await _db.getAllCounterparties();

      final backupCounterparties =
          payload.data['counterparties'] as List? ?? [];
      final backupLoans = payload.data['loans'] as List? ?? [];
      final backupInstallments = payload.data['installments'] as List? ?? [];

      // Merge counterparties
      final existingCpIds = existingCounterparties.map((c) => c.id).toSet();
      for (final cpData in backupCounterparties) {
        final cpId = cpData['id'];
        if (cpId != null && !existingCpIds.contains(cpId)) {
          // Insert new counterparty only if it doesn't exist
          // TODO: Create Counterparty from map and insert
        }
      }

      // Merge loans
      final existingLoanIds = existingLoans.map((l) => l.id).toSet();
      for (final loanData in backupLoans) {
        final loanId = loanData['id'];
        if (loanId != null && !existingLoanIds.contains(loanId)) {
          // Insert new loan only if it doesn't exist
          // TODO: Create Loan from map and insert
        }
      }

      // Merge installments
      for (final instData in backupInstallments) {
        final instId = instData['id'];
        // Check if installment already exists
        final loanId = instData['loan_id'];
        if (loanId != null) {
          final existingInstallments = await _db.getInstallmentsByLoanId(
            loanId as int,
          );
          final existingIds = existingInstallments.map((i) => i.id).toSet();

          if (instId != null && !existingIds.contains(instId)) {
            // Insert new installment
            // TODO: Create Installment from map and insert
          }
        }
      }
    } catch (e) {
      throw Exception('Failed to merge data: $e');
    }
  }

  /// Get list of available backups in directory
  Future<List<File>> getAvailableBackups({String? directory}) async {
    try {
      final backupDir =
          directory ?? (await getApplicationDocumentsDirectory()).path;
      final dir = Directory(backupDir);

      if (!await dir.exists()) {
        return [];
      }

      final backups = <File>[];
      await for (final entity in dir.list()) {
        if (entity is File && entity.path.endsWith('.backup.zip')) {
          backups.add(entity);
        }
      }

      // Sort by modification time (newest first)
      backups.sort(
        (a, b) => b.statSync().modified.compareTo(a.statSync().modified),
      );

      return backups;
    } catch (e) {
      return [];
    }
  }

  /// Get metadata from a backup file without fully loading it
  Future<BackupMetadata?> getBackupMetadata(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return null;
      }

      final zipBytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(zipBytes);

      for (final file in archive) {
        if (file.name == 'backup.json') {
          final payloadJson = utf8.decode(file.content as List<int>);
          final payloadMap = jsonDecode(payloadJson) as Map<String, dynamic>;
          return BackupMetadata.fromJson(
            payloadMap['metadata'] as Map<String, dynamic>,
          );
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Delete a backup file
  Future<bool> deleteBackup(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Get size of a backup file in human readable format
  String getBackupSize(String filePath) {
    try {
      final file = File(filePath);
      final size = file.lengthSync();
      return _formatBytes(size);
    } catch (e) {
      return 'Unknown';
    }
  }

  String _formatBytes(int bytes) {
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var size = bytes.toDouble();
    var suffixIndex = 0;

    while (size > 1024 && suffixIndex < suffixes.length - 1) {
      size /= 1024;
      suffixIndex++;
    }

    return '${size.toStringAsFixed(2)} ${suffixes[suffixIndex]}';
  }
}

/// Custom exception for backup integrity errors
class BackupIntegrityException implements Exception {
  final String message;

  BackupIntegrityException(this.message);

  @override
  String toString() => 'BackupIntegrityException: $message';
}
