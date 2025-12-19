import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:intl/intl.dart';
import 'package:debt_manager/core/db/database_helper.dart';
import 'package:debt_manager/core/models/backup_payload.dart';
import 'package:debt_manager/features/loans/models/installment.dart';
import 'package:path_provider/path_provider.dart';
import 'package:debt_manager/core/privacy/backup_crypto.dart';
import 'package:debt_manager/features/loans/models/counterparty.dart';
import 'package:debt_manager/features/loans/models/loan.dart';

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
    String? password,
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

      // Gather transactions for export
      final transactions = await _db.getAllTransactions();

      // Create backup data structure
      final backupData = {
        'loans': loans.map((l) => l.toMap()).toList(),
        'installments': allInstallments.map((i) => i.toMap()).toList(),
        'counterparties': counterparties.map((c) => c.toMap()).toList(),
        'budgets': [], // Future: implement budgets export
        'transactions': transactions,
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
        transactionsCount: transactions.length,
        sizeBytes: utf8.encode(dataJson).length,
        netWorth: totalLent - totalBorrowed,
        totalBorrowed: totalBorrowed,
        totalLent: totalLent,
      );

      // Create backup payload
      final payload = BackupPayload(
        timestamp: now.toIso8601String(),
        appVersion: const String.fromEnvironment('APP_VERSION', defaultValue: '1.0.0'),
        checksum: checksum,
        name: backupName ??
            'Backup-${DateFormat('yyyy-MM-dd-HHmmss').format(now)}',
        data: backupData,
        metadata: metadata,
      );

      // Serialize payload
      final payloadJson = jsonEncode(payload.toJson());

      // Create zip archive with encrypted payload and separate metadata
      final archive = Archive();
      final metadataJson = jsonEncode(metadata.toJson());
      final metadataBytes = utf8.encode(metadataJson);

      if (password == null || password.isEmpty) {
        throw Exception('Password required for encrypted backup');
      }

      // Encrypt payload JSON using AES-GCM envelope
      final envelope =
          await BackupCrypto.encryptJsonAsync(payloadJson, password);
      final envelopeBytes = utf8.encode(jsonEncode(envelope));

      archive.addFile(
        ArchiveFile('backup.enc', envelopeBytes.length, envelopeBytes),
      );
      archive.addFile(
        ArchiveFile('metadata.json', metadataBytes.length, metadataBytes),
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
    String? password,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Backup file not found');
      }

      // Read and extract zip
      final zipBytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(zipBytes);

      // Find and read encrypted payload or fallback to legacy backup.json
      ArchiveFile? encFile;
      ArchiveFile? legacyJsonFile;
      for (final file in archive) {
        if (file.name == 'backup.enc') encFile = file;
        if (file.name == 'backup.json') legacyJsonFile = file;
      }
      if (encFile == null && legacyJsonFile == null) {
        throw Exception('Invalid backup file: no payload');
      }

      // Parse backup payload
      String payloadJson;
      if (encFile != null) {
        if (password == null || password.isEmpty) {
          throw Exception('Password required to import encrypted backup');
        }
        final envelopeMap = jsonDecode(
          utf8.decode(encFile.content as List<int>),
        ) as Map<String, dynamic>;
        payloadJson =
            await BackupCrypto.decryptJsonAsync(envelopeMap, password);
      } else {
        payloadJson = utf8.decode(legacyJsonFile!.content as List<int>);
      }
      final payloadMap = jsonDecode(payloadJson) as Map<String, dynamic>;
      final payload = BackupPayload.fromJson(payloadMap);

      // Validate checksum
      final dataJson = jsonEncode(payload.data);
      final calculatedChecksum =
          sha256.convert(utf8.encode(dataJson)).toString();
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

    // Validate payload structure: ensure required data sections exist
    final hasRequiredData = payload.data['loans'] is List &&
        payload.data['installments'] is List &&
        payload.data['counterparties'] is List;

    if (!hasRequiredData) {
      conflicts.add(
        BackupConflict(
          type: ConflictType.versionMismatch,
          message: 'Backup payload structure invalid or corrupted',
          resolution: 'Use a different backup file',
        ),
      );
      return conflicts;
    }

    // Compare timestamps
    try {
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
    } catch (e) {
      // If timestamp parsing fails, just continue without time-based conflict
    }

    return conflicts;
  }

  /// Replace all database data with backup data
  Future<void> _replaceAllData(BackupPayload payload) async {
    try {
      // Wipe tables
      final db = await _db.database;
      await db.delete('installments');
      await db.delete('loans');
      await db.delete('counterparties');

      // Insert counterparties and keep id mapping
      final cps = (payload.data['counterparties'] as List? ?? [])
          .cast<Map<String, dynamic>>();
      final cpIdMap = <int, int>{};
      for (final cp in cps) {
        final oldId = cp['id'] is int
            ? cp['id'] as int
            : int.tryParse('${cp['id']}') ?? 0;
        final counterparty = Counterparty.fromMap(cp);
        final newId = await _db.insertCounterparty(counterparty);
        cpIdMap[oldId] = newId;
      }

      // Insert loans and keep loan id mapping. Use direct DB inserts to avoid
      // triggering side-effects (notifications, insights) during restore.
      final loans =
          (payload.data['loans'] as List? ?? []).cast<Map<String, dynamic>>();
      final loanIdMap = <int, int>{};
      for (final l in loans) {
        final oldId =
            l['id'] is int ? l['id'] as int : int.tryParse('${l['id']}') ?? 0;
        final loan = Loan.fromMap(l);
        final remappedCp = cpIdMap[loan.counterpartyId] ?? loan.counterpartyId;
        final loanToInsert = loan.copyWith(counterpartyId: remappedCp);
        final loanMap = Map<String, dynamic>.from(loanToInsert.toMap());
        loanMap.remove('id');
        final filteredLoanMap =
            await _filterToExistingColumns(db, 'loans', loanMap);
        final newId = await db.insert('loans', filteredLoanMap);
        loanIdMap[oldId] = newId;
      }

      // Insert installments mapping loan ids and track id remapping
      final installments = (payload.data['installments'] as List? ?? [])
          .cast<Map<String, dynamic>>();
      final instIdMap = <int, int>{};
      for (final it in installments) {
        final instMap = Map<String, dynamic>.from(it);
        final oldInstId = instMap['id'] is int
            ? instMap['id'] as int
            : int.tryParse('${instMap['id']}') ?? 0;
        final oldLoanId = instMap['loan_id'] is int
            ? instMap['loan_id'] as int
            : int.tryParse('${instMap['loan_id']}') ?? 0;
        final newLoanId = loanIdMap[oldLoanId] ?? oldLoanId;
        instMap['loan_id'] = newLoanId;
        // Remove id to allow autoincrement on insert
        instMap.remove('id');
        final filteredInstMap =
            await _filterToExistingColumns(db, 'installments', instMap);
        final newId = await db.insert('installments', filteredInstMap);
        instIdMap[oldInstId] = newId;
      }

      // Insert transactions remapping related ids where necessary
      final txns = (payload.data['transactions'] as List? ?? [])
          .cast<Map<String, dynamic>>();
      for (final t in txns) {
        try {
          final m = Map<String, dynamic>.from(t);
          final oldRelatedId = m['related_id'] is int
              ? m['related_id'] as int
              : int.tryParse('${m['related_id']}') ?? 0;
          final relatedType = (m['related_type'] as String?) ?? '';
          if (relatedType == 'loan' && loanIdMap.containsKey(oldRelatedId)) {
            m['related_id'] = loanIdMap[oldRelatedId];
          } else if (relatedType == 'installment' && instIdMap.containsKey(oldRelatedId)) {
            m['related_id'] = instIdMap[oldRelatedId];
          }
          // Remove id to let DB assign new primary key
          m.remove('id');
          final filteredTxn = await _filterToExistingColumns(db, 'transactions', m);
          await db.insert('transactions', filteredTxn);
        } catch (_) {
          // Ignore failures inserting individual transactions
        }
      }
    } catch (e) {
      throw Exception('Failed to replace database data: $e');
    }
  }

  /// Return a new map containing only keys that exist as columns on [table].
  Future<Map<String, dynamic>> _filterToExistingColumns(
    dynamic db,
    String table,
    Map<String, dynamic> data,
  ) async {
    try {
      final pragma = await db.rawQuery("PRAGMA table_info('$table')");
      final cols = <String>{};
      for (final row in pragma) {
        final name = row['name'] as String?;
        if (name != null) cols.add(name);
      }
      final filtered = <String, dynamic>{};
      data.forEach((k, v) {
        // Map keys in our model to DB column names where needed
        final colName = _toColumnName(k);
        if (cols.contains(colName)) filtered[colName] = v;
      });
      return filtered;
    } catch (_) {
      return data;
    }
  }

  String _toColumnName(String key) {
    // Convert camelCase keys from model.toMap() to snake_case DB columns
    // Many maps already use snake_case; handle simple conversions.
    if (key.contains('_')) return key;
    final buffer = StringBuffer();
    for (final ch in key.runes) {
      final s = String.fromCharCode(ch);
      if (s.toUpperCase() == s &&
          buffer.isNotEmpty &&
          RegExp(r'[A-Za-z]').hasMatch(s)) {
        buffer.write('_');
        buffer.write(s.toLowerCase());
      } else {
        buffer.write(s.toLowerCase());
      }
    }
    return buffer.toString();
  }

  /// Merge backup data with existing database
  /// Merge backup data with existing database
  Future<void> _mergeData(BackupPayload payload, BackupMergeMode mode) async {
    try {
      final db = await _db.database;
      // Get existing data once (prefetch optimization)
      final existingLoans = await _db.getAllLoans();
      final existingCounterparties = await _db.getAllCounterparties();
      final existingLoanIds = existingLoans.map((l) => l.id).toSet();

      // Prefetch all installments grouped by loan_id to avoid N+1 queries
      final loanIds = existingLoanIds.isNotEmpty
          ? existingLoanIds.whereType<int>().toList()
          : <int>[];
      final existingInstallmentsByLoanId = loanIds.isNotEmpty
          ? await _db.getInstallmentsGroupedByLoanId(loanIds)
          : <int, List<Installment>>{};

      final backupCounterparties =
          payload.data['counterparties'] as List? ?? [];
      final backupLoans = payload.data['loans'] as List? ?? [];
      final backupInstallments = payload.data['installments'] as List? ?? [];

      // Merge counterparties
      final existingCpIds = existingCounterparties.map((c) => c.id).toSet();
      for (final cpData in backupCounterparties) {
        final cpId = cpData['id'];
        if (cpId != null && !existingCpIds.contains(cpId)) {
          // Insert directly to avoid any side-effects
          final m = Map<String, dynamic>.from(cpData);
          m.remove('id');
          final filtered =
              await _filterToExistingColumns(db, 'counterparties', m);
          await db.insert('counterparties', filtered);
        }
      }

      // Merge loans
      for (final loanData in backupLoans) {
        final loanId = loanData['id'];
        if (loanId != null && !existingLoanIds.contains(loanId)) {
          final m = Map<String, dynamic>.from(loanData);
          m.remove('id');
          final filtered = await _filterToExistingColumns(db, 'loans', m);
          await db.insert('loans', filtered);
        }
      }

      // Merge installments using prefetched data
      for (final instData in backupInstallments) {
        final instId = instData['id'];
        final loanId = instData['loan_id'];
        if (loanId != null && instId != null) {
          // Use prefetched installments map
          final existingIds =
              (existingInstallmentsByLoanId[loanId as int] ?? [])
                  .map((i) => i.id)
                  .toSet();

          if (!existingIds.contains(instId)) {
            final m = Map<String, dynamic>.from(instData);
            m.remove('id');
            final filtered =
                await _filterToExistingColumns(db, 'installments', m);
            await db.insert('installments', filtered);
          }
        }
      }

      // Merge transactions: insert any transactions not already present.
      final backupTxns = payload.data['transactions'] as List? ?? [];
      if (backupTxns.isNotEmpty) {
        // Simple heuristic: compare by related_type/related_id/timestamp/amount
        final existingTxns = await db.query('transactions');
        for (final t in backupTxns.cast<Map<String, dynamic>>()) {
          final ts = t['timestamp'];
          final relatedType = t['related_type'];
          final relatedId = t['related_id'];
          final amount = t['amount'];
          final match = existingTxns.any((e) =>
              e['timestamp'] == ts && e['related_type'] == relatedType && e['related_id'] == relatedId && e['amount'] == amount);
          if (!match) {
            final m = Map<String, dynamic>.from(t);
            m.remove('id');
            final filtered = await _filterToExistingColumns(db, 'transactions', m);
            try {
              await db.insert('transactions', filtered);
            } catch (_) {}
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
        if (file.name == 'metadata.json') {
          final metaJson = utf8.decode(file.content as List<int>);
          final metaMap = jsonDecode(metaJson) as Map<String, dynamic>;
          return BackupMetadata.fromJson(metaMap);
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
