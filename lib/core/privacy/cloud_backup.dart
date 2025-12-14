abstract class CloudBackupProvider {
  // Upload encrypted blob and return a version id / remote path.
  Future<String> uploadEncryptedBlob(
    List<int> bytes, {
    required String filename,
  });

  // Download encrypted blob by version id / path. Returns bytes.
  Future<List<int>> downloadEncryptedBlob(String id);

  // List available backups (version ids or metadata).
  Future<List<String>> listBackups();
}

// Example placeholder implementation that can be implemented later.
class NoopCloudBackupProvider implements CloudBackupProvider {
  @override
  Future<List<int>> downloadEncryptedBlob(String id) async =>
      throw UnimplementedError();

  @override
  Future<List<String>> listBackups() async => [];

  @override
  Future<String> uploadEncryptedBlob(
    List<int> bytes, {
    required String filename,
  }) async => throw UnimplementedError();
}
