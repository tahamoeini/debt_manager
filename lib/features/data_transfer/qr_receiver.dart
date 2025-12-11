import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/privacy/backup_service.dart';
import '../../core/privacy/privacy_gateway.dart';
import 'dart:convert';
 

class QrReceiverScreen extends StatefulWidget {
  const QrReceiverScreen({super.key});

  @override
  State<QrReceiverScreen> createState() => _QrReceiverScreenState();
}

class _QrReceiverScreenState extends State<QrReceiverScreen> {
  final Map<int, String> _chunks = {};
  int? _total;
  bool _scanning = true;

  void _onDetect(BarcodeCapture capture) async {
    if (!_scanning) return;
    for (final b in capture.barcodes) {
      final data = b.rawValue;
      if (data == null) continue;
      // Expect chunk payload in form {"idx":n,"total":t,"data":"..."}
      try {
        final map = json.decode(data) as Map<String, dynamic>;
        final idx = map['idx'] as int;
        final total = map['total'] as int;
        final chunkData = map['data'] as String;
        _chunks[idx] = chunkData;
        _total = total;
        setState(() {});
        if (_total != null && _chunks.length == _total) {
          // assembled
          setState(() => _scanning = false);
          final list = List<String>.filled(_total!, '');
          for (var i = 0; i < _total!; i++) {
            list[i] = _chunks[i]!;
          }
          final bytes = BackupService.assembleFromChunks(list);
          final pw = await _askPassword();
          if (pw == null) return;
          // decrypt and import
          try {
            final jsonStr = await BackupService.decryptCompressedBytes(bytes, pw);
            final pg = PrivacyGateway();
            await pg.audit('import_qr', details: 'Imported data via QR');
            await pg.importJsonString(jsonStr);
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Import completed')));
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to decrypt/import data')));
          }
        }
      } catch (_) {}
    }
  }

  Future<String?> _askPassword() async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (ctx) {
      return AlertDialog(
        title: const Text('Password'),
        content: TextField(controller: controller, obscureText: true),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('OK')),
        ],
      );
    });
    if (ok == true) return controller.text;
    return null;
  }

  // helper removed - import is now done directly from JSON string

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Offline Transfer - Receive')),
      body: Column(children: [
        Expanded(
          child: MobileScanner(
            onDetect: _onDetect,
          ),
        ),
        Padding(padding: const EdgeInsets.all(8), child: Text('Chunks received: ${_chunks.length}${_total != null ? ' / $_total' : ''}')),
        if (!_scanning) ElevatedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Done'))
      ]),
    );
  }
}
