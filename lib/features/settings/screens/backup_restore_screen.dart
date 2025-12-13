import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart' as share;
import 'package:intl/intl.dart';
import 'package:debt_manager/features/settings/backup_restore_service.dart';
import 'package:debt_manager/core/models/backup_payload.dart';

class BackupRestoreScreen extends StatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  final _service = BackupRestoreService();
  bool _isLoading = false;
  List<File> _availableBackups = [];

  @override
  void initState() {
    super.initState();
    _loadAvailableBackups();
  }

  Future<void> _loadAvailableBackups() async {
    setState(() => _isLoading = true);
    try {
      final backups = await _service.getAvailableBackups();
      setState(() => _availableBackups = backups);
    } catch (e) {
      _showErrorSnackBar('خطا در بارگذاری نسخه‌های پشتیبان: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createBackup() async {
    final nameController = TextEditingController();
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ایجاد نسخه‌ی پشتیبان'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                hintText: 'نام نسخه‌ی پشتیبان (اختیاری)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('لغو'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ایجاد'),
          ),
        ],
      ),
    ) ?? false;

    if (!confirmed) return;

    setState(() => _isLoading = true);
    try {
      final backupPath = await _service.exportData(
        backupName: nameController.text.isNotEmpty
            ? nameController.text
            : null,
      );

      if (!mounted) return;

      _showSuccessSnackBar('نسخه‌ی پشتیبان با موفقیت ایجاد شد');
      await _loadAvailableBackups();

      // Ask to share
      final shareConfirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('اشتراک‌گذاری نسخه‌ی پشتیبان'),
          content: const Text('آیا می‌خواهید این نسخه‌ی پشتیبان را با دیگران به اشتراک بگذارید؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('خیر'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('بله'),
            ),
          ],
        ),
      ) ?? false;

      if (shareConfirmed) {
        await share.SharePlus.instance.share(share.ShareParams(
          files: [share.XFile(backupPath)],
          text: 'نسخه‌ی پشتیبان از Debt Manager',
        ));
      }
    } catch (e) {
      _showErrorSnackBar('خطا در ایجاد نسخه‌ی پشتیبان: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }


  Future<void> _deleteBackup(String filePath) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف نسخه‌ی پشتیبان'),
        content: const Text('آیا مطمئن هستید؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('لغو'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    ) ?? false;

    if (!confirmed) return;

    final success = await _service.deleteBackup(filePath);
    if (success) {
      _showSuccessSnackBar('نسخه‌ی پشتیبان حذف شد');
      await _loadAvailableBackups();
    } else {
      _showErrorSnackBar('خطا در حذف نسخه‌ی پشتیبان');
    }
  }


  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade600,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('نسخه‌ی پشتیبان و بازیابی'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _isLoading ? null : _createBackup,
                    icon: const Icon(Icons.backup),
                    label: const Text('ایجاد نسخه‌ی پشتیبان'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Information card
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'اطلاعات',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '• نسخه‌های پشتیبان شامل تمام وام‌ها، قبوض و مشاهیر است',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• فایل‌های نسخه‌ی پشتیبان رمزگذاری شده و فشرده‌سازی‌شده هستند',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• می‌توانید نسخه‌های پشتیبان را اشتراک‌گذاری کنید یا خود را در ابزارهای ذخیره‌سازی ابری ذخیره کنید',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Available backups
            Text(
              'نسخه‌های پشتیبان موجود',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_availableBackups.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.backup_outlined,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'هیچ نسخه‌ی پشتیبانی موجود نیست',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              Column(
                children: _availableBackups.map((backup) {
                  final fileName = backup.path.split('/').last;
                  final fileSize = _service.getBackupSize(backup.path);
                  final modifiedTime = backup.statSync().modified;
                  final formattedTime =
                      DateFormat('yyyy-MM-dd HH:mm').format(modifiedTime);

                  return FutureBuilder<BackupMetadata?>(
                    future: _service.getBackupMetadata(backup.path),
                    builder: (context, snapshot) {
                      final metadata = snapshot.data;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Icon(
                            Icons.backup,
                            color: Colors.blue.shade600,
                          ),
                          title: Text(
                            fileName.replaceAll('.backup.zip', ''),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                '$formattedTime • $fileSize',
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                              if (metadata != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  '${metadata.loansCount} وام، ${metadata.installmentsCount} قسط',
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          trailing: PopupMenuButton(
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                child: const Text('بازیابی'),
                                onTap: () {
                                  // TODO: Implement restore with this specific backup
                                },
                              ),
                              PopupMenuItem(
                                child: const Text('اشتراک‌گذاری'),
                                onTap: () {
                                  share.SharePlus.instance.share(share.ShareParams(
                                    files: [share.XFile(backup.path)],
                                  ));
                                },
                              ),
                              PopupMenuItem(
                                child: const Text(
                                  'حذف',
                                  style: TextStyle(color: Colors.red),
                                ),
                                onTap: () => _deleteBackup(backup.path),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}
