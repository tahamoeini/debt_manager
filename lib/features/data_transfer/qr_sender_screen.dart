import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/privacy/secure_backup_service.dart';

class QrSenderScreen extends StatefulWidget {
  const QrSenderScreen({super.key});

  @override
  State<QrSenderScreen> createState() => _QrSenderScreenState();
}

class _QrSenderScreenState extends State<QrSenderScreen> {
  List<String> _pages = [];
  int _index = 0;
  bool _loading = false;
  bool _autoPlay = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _buildBackupAndChunks();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _buildBackupAndChunks() async {
    setState(() => _loading = true);
    try {
      // Create encrypted+compressed bytes (prompts auth)
      final bytes = await SecureBackupService.instance.createEncryptedBackup(password: null, requireAuth: true);

      // Base64 encode and chunk into QR-friendly sizes.
      // Tune chunk size to be QR-friendly (payload per QR depends on version/error-corr).
      const int chunkSize = 800; // conservative character size
      final b64 = base64Encode(bytes);
      final total = (b64.length / chunkSize).ceil();
      final pages = <String>[];
      for (var i = 0; i < total; i++) {
        final start = i * chunkSize;
        final end = (start + chunkSize).clamp(0, b64.length);
        final part = b64.substring(start, end);
        final wrapper = jsonEncode({'idx': i, 'total': total, 'data': part});
        pages.add(wrapper);
      }

      setState(() {
        _pages = pages;
        _index = 0;
      });

      if (_autoPlay) _startAutoPlay();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  void _startAutoPlay() {
    _timer?.cancel();
    if (_pages.isEmpty) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _index = (_index + 1) % _pages.length;
      });
    });
  }

  void _stopAutoPlay() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Offline Transfer — Send')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _pages.isEmpty
              ? Center(child: ElevatedButton(onPressed: _buildBackupAndChunks, child: const Text('Retry export')))
              : Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: QrImage(
                          data: _pages[_index],
                          version: QrVersions.auto,
                          size: 320,
                          errorStateBuilder: (c, err) => const Text('QR error'),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${_index + 1} / ${_pages.length}'),
                          Row(children: [
                            IconButton(
                                onPressed: () {
                                  setState(() => _index = (_index - 1 + _pages.length) % _pages.length);
                                },
                                icon: const Icon(Icons.arrow_back)),
                            IconButton(
                                onPressed: () {
                                  setState(() => _index = (_index + 1) % _pages.length);
                                },
                                icon: const Icon(Icons.arrow_forward)),
                            IconButton(
                                onPressed: () {
                                  setState(() => _autoPlay = !_autoPlay);
                                  if (_autoPlay) {
                                    _startAutoPlay();
                                  } else {
                                    _stopAutoPlay();
                                  }
                                },
                                icon: Icon(_autoPlay ? Icons.pause : Icons.play_arrow)),
                          ])
                        ],
                      ),
                    )
                  ],
                ),
    );
  }
}
