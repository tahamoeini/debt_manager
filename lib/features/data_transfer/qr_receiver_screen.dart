import 'dart:convert';
import 'dart:typed_data';

// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/privacy/secure_backup_service.dart';

class QrReceiverScreen extends StatefulWidget {
  const QrReceiverScreen({super.key});

  @override
  State<QrReceiverScreen> createState() => _QrReceiverScreenState();
}

class _QrReceiverScreenState extends State<QrReceiverScreen> {
  final Map<int, String> _chunks = {};
  int _expectedTotal = -1;
  bool _scanning = true;
  String? _status;

  void _onScan(String raw) async {
    try {
      final Map<String, dynamic> parsed = jsonDecode(raw);
      final idx = parsed['idx'] as int;
      final total = parsed['total'] as int;
      final data = parsed['data'] as String;
      setState(() {
        _chunks[idx] = data;
        _expectedTotal = total;
        _status = 'Received ${_chunks.length} / $total chunks';
      });

      if (_chunks.length == _expectedTotal) {
        // stop scanning
        setState(() => _scanning = false);

        // assemble
        final buffer = StringBuffer();
        for (var i = 0; i < _expectedTotal; i++) {
          buffer.write(_chunks[i]);
        }
        final allB64 = buffer.toString();
        final bytes = base64Decode(allB64);

        // ask for password (optional)
        final password = await _askForPassword();
        if (password == null) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Password required to continue')));
          return;
        }

        // import
        try {
          await SecureBackupService.instance.importEncryptedBackup(
              Uint8List.fromList(bytes),
              password: password,
              requireAuth: true);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Import completed')));
          }
          Navigator.of(context).pop();
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text('Import failed: $e')));
          }
          setState(() => _scanning = true);
        }
      }
    } catch (e) {
      // ignore invalid scans
    }
  }

  Future<String?> _askForPassword() async {
    String? password;
    await showDialog<void>(
        context: context,
        builder: (ctx) {
          final ctrl = TextEditingController();
          return AlertDialog(
            title: const Text('Backup password'),
            content: TextField(
                controller: ctrl,
                obscureText: true,
                decoration:
                    const InputDecoration(hintText: 'Enter password (if set)')),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel')),
              TextButton(
                  onPressed: () {
                    password = ctrl.text;
                    Navigator.of(ctx).pop();
                  },
                  child: const Text('OK'))
            ],
          );
        });
    return password;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Offline Transfer — Receive')),
      body: SafeArea(
        child: Column(children: [
          Expanded(
            child: _scanning
                ? MobileScanner(
                    onDetect: (capture) {
                      for (final s in capture.barcodes) {
                        if (s.rawValue != null) _onScan(s.rawValue!);
                      }
                    },
                  )
                : Center(child: Text(_status ?? 'Completed')),
          ),
          Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(_status ?? 'Waiting...'))
        ]),
      ),
    );
  }
}
