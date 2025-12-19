import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:debt_manager/core/backup/backup_facade.dart';
import '../../core/privacy/privacy_gateway.dart';
import '../settings/transfer_service.dart';

class QrReceiverScreen extends StatefulWidget {
  const QrReceiverScreen({super.key});

  @override
  State<QrReceiverScreen> createState() => _QrReceiverScreenState();
}

class _QrReceiverScreenState extends State<QrReceiverScreen> {
  final TransferSessionManager _sessionManager = TransferSessionManager();
  TransferSession? _session;
  bool _scanning = true;

  void _onDetect(BarcodeCapture capture) async {
    if (!_scanning) return;
    for (final b in capture.barcodes) {
      final data = b.rawValue;
      if (data == null) continue;
      // Expect framed payload created by TransferService
      try {
        final frame = TransferFrame.fromQrString(data);
        _session ??=
            _sessionManager.createSession(frame.frameId, frame.totalFrames);
        _sessionManager.addFrame(frame.frameId, frame);
        setState(() {});

        final session = _sessionManager.getSession(frame.frameId);
        if (session != null && session.isComplete) {
          // All frames received, reassemble and import
          setState(() => _scanning = false);
          final ordered = session.getOrderedFrames();
          final bytes = TransferService().reassembleFrames(ordered);
          final pw = await _askPassword();
          if (pw == null) return;
          try {
            final jsonStr =
                await BackupFacade.instance.decryptQrBytesToJson(bytes, pw);
            final pg = PrivacyGateway();
            await pg.audit('import_qr', details: 'Imported data via QR');
            await pg.importJsonString(jsonStr);
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Import completed')));
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to decrypt/import data')),
            );
          } finally {
            _sessionManager.completeSession(frame.frameId);
          }
        }
      } catch (_) {}
    }
  }

  Future<String?> _askPassword() async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Password'),
          content: TextField(controller: controller, obscureText: true),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
    if (ok == true) return controller.text;
    return null;
  }

  // helper removed - import is now done directly from JSON string

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Offline Transfer - Receive')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: MobileScanner(onDetect: _onDetect)),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                _session == null
                    ? 'Waiting for first frame...'
                    : 'Frames: ${_session!.receivedFrames.length} / ${_session!.totalFrames}',
              ),
            ),
            if (!_scanning)
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Done'),
              ),
          ],
        ),
      ),
    );
  }
}
