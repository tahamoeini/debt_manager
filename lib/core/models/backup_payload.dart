/// DTO for backup data payload
/// Contains all serializable data for backup/restore operations
class BackupPayload {
  /// Version of the backup format
  final int version = 1;

  /// Timestamp when backup was created (ISO 8601 format)
  final String timestamp;

  /// Application version at time of backup
  final String appVersion;

  /// Checksum of the backup data (SHA-256)
  final String checksum;

  /// User-provided backup name/description
  final String name;

  /// Complete database export as JSON
  /// Structure: {
  ///   "loans": [...],
  ///   "installments": [...],
  ///   "counterparties": [...],
  ///   "budgets": [...],
  ///   "transactions": [...]
  /// }
  final Map<String, dynamic> data;

  /// Metadata about what was backed up
  final BackupMetadata metadata;

  BackupPayload({
    required this.timestamp,
    required this.appVersion,
    required this.checksum,
    required this.name,
    required this.data,
    required this.metadata,
  });

  /// Convert to JSON-serializable map
  Map<String, dynamic> toJson() => {
    'version': version,
    'timestamp': timestamp,
    'appVersion': appVersion,
    'checksum': checksum,
    'name': name,
    'data': data,
    'metadata': metadata.toJson(),
  };

  /// Create from JSON map
  factory BackupPayload.fromJson(Map<String, dynamic> json) {
    return BackupPayload(
      timestamp: json['timestamp'] as String,
      appVersion: json['appVersion'] as String,
      checksum: json['checksum'] as String,
      name: json['name'] as String,
      data: Map<String, dynamic>.from(json['data'] as Map),
      metadata: BackupMetadata.fromJson(json['metadata'] as Map<String, dynamic>),
    );
  }

  /// Create a summary representation
  @override
  String toString() {
    return '''BackupPayload(
    name: $name,
    timestamp: $timestamp,
    version: $version,
    appVersion: $appVersion,
    ${metadata.loansCount} loans,
    ${metadata.installmentsCount} installments,
    ${metadata.counterpartiesCount} counterparties
  )''';
  }
}

/// Metadata about a backup
class BackupMetadata {
  /// Number of loans backed up
  final int loansCount;

  /// Number of installments backed up
  final int installmentsCount;

  /// Number of counterparties backed up
  final int counterpartiesCount;

  /// Number of budgets backed up
  final int budgetsCount;

  /// Total transactions backed up
  final int transactionsCount;

  /// Size of backup in bytes
  final int sizeBytes;

  /// Net worth at time of backup (lent - borrowed)
  final int netWorth;

  /// Total borrowed at time of backup
  final int totalBorrowed;

  /// Total lent at time of backup
  final int totalLent;

  BackupMetadata({
    required this.loansCount,
    required this.installmentsCount,
    required this.counterpartiesCount,
    required this.budgetsCount,
    required this.transactionsCount,
    required this.sizeBytes,
    required this.netWorth,
    required this.totalBorrowed,
    required this.totalLent,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
    'loansCount': loansCount,
    'installmentsCount': installmentsCount,
    'counterpartiesCount': counterpartiesCount,
    'budgetsCount': budgetsCount,
    'transactionsCount': transactionsCount,
    'sizeBytes': sizeBytes,
    'netWorth': netWorth,
    'totalBorrowed': totalBorrowed,
    'totalLent': totalLent,
  };

  /// Create from JSON
  factory BackupMetadata.fromJson(Map<String, dynamic> json) {
    return BackupMetadata(
      loansCount: json['loansCount'] as int? ?? 0,
      installmentsCount: json['installmentsCount'] as int? ?? 0,
      counterpartiesCount: json['counterpartiesCount'] as int? ?? 0,
      budgetsCount: json['budgetsCount'] as int? ?? 0,
      transactionsCount: json['transactionsCount'] as int? ?? 0,
      sizeBytes: json['sizeBytes'] as int? ?? 0,
      netWorth: json['netWorth'] as int? ?? 0,
      totalBorrowed: json['totalBorrowed'] as int? ?? 0,
      totalLent: json['totalLent'] as int? ?? 0,
    );
  }
}

/// Merge conflict information
class BackupConflict {
  /// Type of conflict
  final ConflictType type;

  /// Description of the conflict
  final String message;

  /// Suggestion for resolution
  final String resolution;

  BackupConflict({
    required this.type,
    required this.message,
    required this.resolution,
  });
}

enum ConflictType {
  /// Backup contains newer data than current database
  newerBackup,

  /// Current database has newer data than backup
  newerDatabase,

  /// Checksums don't match
  checksumMismatch,

  /// Incompatible app version
  versionMismatch,

  /// ID conflicts (same ID with different data)
  idConflict,

  /// Data structure changed
  structureChange,
}

/// Merge mode for importing backups
enum BackupMergeMode {
  /// Replace all data with backup data
  replace,

  /// Merge backup data with current data (new items only)
  merge,

  /// Merge with conflict resolution (newer wins)
  mergeWithNewerWins,

  /// Merge with conflict resolution (existing wins)
  mergeWithExistingWins,

  /// Dry run - check for conflicts without applying
  dryRun,
}
