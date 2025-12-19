import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// A small widget that exposes Data Management actions:
// - Export (uses existing export flow in Settings elsewhere)
// - Import (relies on existing import flow)
// - Offline Transfer (send/receive via QR)
class DataManagementSection extends StatelessWidget {
  const DataManagementSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        ListTile(
          leading: const Icon(Icons.outbox),
          title: const Text('Offline Transfer — Send'),
          subtitle: const Text('Export encrypted backup as QR sequence'),
          onTap: () => context.pushNamed('qrSend'),
        ),
        ListTile(
          leading: const Icon(Icons.inbox),
          title: const Text('Offline Transfer — Receive'),
          subtitle: const Text('Scan QR sequence to import a backup'),
          onTap: () => context.pushNamed('qrReceive'),
        ),
      ],
    );
  }
}
