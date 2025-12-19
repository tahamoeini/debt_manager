// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import '../settings/transfer_service.dart';
import 'package:debt_manager/core/backup/backup_facade.dart';
import '../../core/security/local_auth_service.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrSenderScreen extends StatefulWidget {
  const QrSenderScreen({super.key});

  @override
  State<QrSenderScreen> createState() => _QrSenderScreenState();
}

class _QrSenderScreenState extends State<QrSenderScreen> {
  List<String> _chunks = [];
  int _index = 0;
  bool _loading = false;

  Future<void> _prepare(String password) async {
    setState(() => _loading = true);
    final la = LocalAuthService();
    final ok = await la.authenticate(reason: 'Authenticate to export via QR');
    if (!ok) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Authentication failed')));
      return;
    }

    final bytes = await BackupFacade.instance.exportQrBytes(password);

    // Use TransferService to chunk into robust frames with checksum + metadata
    final transferId = DateTime.now().millisecondsSinceEpoch.toString();
    final frames = TransferService().chunkDataForTransfer(bytes, transferId);
    final wrapped = frames.map((f) => f.toQrString()).toList();
    setState(() {
      _chunks = wrapped;
      _index = 0;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Offline Transfer - Send')),
      body: SafeArea(
        child: Center(
          child: _loading
              ? const CircularProgressIndicator()
              : _chunks.isEmpty
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(8),
                          child: Text(
                            'Enter password to encrypt export and generate QR sequence',
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            final pw = await _askPassword();
                            if (pw != null) await _prepare(pw);
                          },
                          child: const Text('Generate QR Sequence'),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Page ${_index + 1} / ${_chunks.length}'),
                        const SizedBox(height: 12),
                        // Render QR using qr_flutter (data contains framed JSON)
                        Container(
                          width: 320,
                          height: 320,
                          color: Colors.white,
                          child: QrImageView(data: _chunks[_index], size: 320),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ElevatedButton(
                              onPressed: _index > 0
                                  ? () => setState(() => _index--)
                                  : null,
                              child: const Text('Prev'),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: _index < _chunks.length - 1
                                  ? () => setState(() => _index++)
                                  : null,
                              child: const Text('Next'),
                            ),
                          ],
                        ),
                      ],
                    ),
        ),
      ),
    );
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
}
