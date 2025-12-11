// Core: Cloud backup provider interface
/// Defines the interface for a zero-knowledge, client-side-encrypted
/// cloud backup provider. Implementations should not hold any user
/// encryption keys; encryption/decryption is performed on the client.

import 'dart:typed_data';

class CloudBackupEntry {
  /// A stable id for this entry (e.g. GUID)
  final String id;

  /// Human-friendly label (e.g. "backup-2025-12-11")
  final String label;

  /// ISO 8601 timestamp
  final String createdAt;

  /// Optional user-provided metadata
  final Map<String, String>? metadata;

  /// Size in bytes
  final int size;

  CloudBackupEntry(
      {required this.id,
      required this.label,
      required this.createdAt,
      required this.size,
      this.metadata});
}

abstract class CloudBackupProvider {
  /// Upload an encrypted blob. The provider returns an entry representing
  /// the saved version. Implementations should be able to store bytes
  /// and index metadata for listing.
  Future<CloudBackupEntry> uploadEncryptedBackup(Uint8List encryptedBytes,
      {String? label, Map<String, String>? metadata});

  /// Download a specific backup by id. Returns the previously-uploaded
  /// encrypted bytes.
  Future<Uint8List> downloadEncryptedBackup(String id);

  /// List available backups (with pagination if necessary).
  Future<List<CloudBackupEntry>> listBackups({int limit = 50, String? cursor});

  /// Delete a backup entry.
  Future<void> deleteBackup(String id);
}

// Example: a future concrete implementation can wrap AWS S3, GCS, Dropbox,
// or a custom endpoint. IMPORTANT: never send plain JSON; providers
// receive only already-encrypted bytes. The client is responsible for
// encrypting/decrypting and for key management (password-derived keys
// or user secret stored in secure storage).
