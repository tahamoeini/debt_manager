// transfer_receive_screen.dart: QR code receiver for peer-to-peer data transfer

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:debt_manager/features/settings/transfer_service.dart';

/// State for transfer receive
class _TransferReceiveState {
  final TransferSessionManager sessionManager;
  final String? currentTransferId;
  final bool isScanning;
  final String? error;
  final List<String> scannedTransfersHistory;

  _TransferReceiveState({
    required this.sessionManager,
    this.currentTransferId,
    this.isScanning = false,
    this.error,
    this.scannedTransfersHistory = const [],
  });

  _TransferReceiveState copyWith({
    TransferSessionManager? sessionManager,
    String? currentTransferId,
    bool? isScanning,
    String? error,
    List<String>? scannedTransfersHistory,
  }) {
    return _TransferReceiveState(
      sessionManager: sessionManager ?? this.sessionManager,
      currentTransferId: currentTransferId ?? this.currentTransferId,
      isScanning: isScanning ?? this.isScanning,
      error: error,
      scannedTransfersHistory:
          scannedTransfersHistory ?? this.scannedTransfersHistory,
    );
  }

  TransferSession? get currentSession {
    if (currentTransferId == null) return null;
    return sessionManager.getSession(currentTransferId!);
  }
}

/// Notifier for transfer receive state
class _TransferReceiveNotifier extends StateNotifier<_TransferReceiveState> {
  _TransferReceiveNotifier()
      : super(_TransferReceiveState(
          sessionManager: TransferSessionManager(),
        ));

  void setScanning(bool scanning) {
    state = state.copyWith(isScanning: scanning);
  }

  void setCurrentTransferId(String? transferId) {
    state = state.copyWith(currentTransferId: transferId);
  }

  void setError(String? error) {
    state = state.copyWith(error: error);
  }

  void addFrame(TransferFrame frame) {
    try {
      state.sessionManager.addFrame(frame.frameId, frame);
      state = state.copyWith(currentTransferId: frame.frameId);
    } catch (e) {
      setError(e.toString());
    }
  }

  void reset() {
    state = state.copyWith(
      currentTransferId: null,
      error: null,
    );
  }
}

final _transferReceiveProvider =
    StateNotifierProvider<_TransferReceiveNotifier, _TransferReceiveState>(
        (ref) {
  return _TransferReceiveNotifier();
});

/// QR transfer receiver screen
class TransferReceiveScreen extends ConsumerStatefulWidget {
  const TransferReceiveScreen({super.key});

  @override
  ConsumerState<TransferReceiveScreen> createState() =>
      _TransferReceiveScreenState();
}

class _TransferReceiveScreenState extends ConsumerState<TransferReceiveScreen> {
  late MobileScannerController cameraController;

  @override
  void initState() {
    super.initState();
    cameraController = MobileScannerController();
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(_transferReceiveProvider);
    final notifier = ref.read(_transferReceiveProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('دریافت از طریق QR Code'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: state.currentSession == null
                  ? _buildCameraView(context, cameraController, notifier)
                  : _buildReceiveProgress(context, state, notifier),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraView(
    BuildContext context,
    MobileScannerController controller,
    _TransferReceiveNotifier notifier,
  ) {
    return Stack(
      children: [
        MobileScanner(
          controller: controller,
          onDetect: (capture) {
            final List<Barcode> barcodes = capture.barcodes;
            for (final barcode in barcodes) {
              final qrData = barcode.rawValue;
              if (qrData != null) {
                _handleQrScan(qrData, notifier);
              }
            }
          },
        ),
        // Overlay UI
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            color: Colors.black87,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'اسکن QR Code',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'قاب QR Code را در مقابل دوربین قرار دهید',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReceiveProgress(
    BuildContext context,
    _TransferReceiveState state,
    _TransferReceiveNotifier notifier,
  ) {
    final session = state.currentSession!;
    final missing = session.getMissingFrames();

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'دریافت در حال انجام...',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            // Progress bar
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'پیشرفت',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          '${(session.progress * 100).toStringAsFixed(1)}%',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: session.progress,
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Frame status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'وضعیت فریم‌ها',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatColumn(
                          label: 'دریافت‌شده',
                          value: '${session.receivedFrames.length}',
                          color: Colors.green,
                        ),
                        _StatColumn(
                          label: 'باقی‌مانده',
                          value: '${missing.length}',
                          color: Colors.orange,
                        ),
                        _StatColumn(
                          label: 'کل',
                          value: '${session.totalFrames}',
                          color: Colors.blue,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (missing.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                color: Colors.orange.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'فریم‌های باقی‌مانده:',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade900,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: missing
                            .take(10)
                            .map(
                              (idx) => Chip(
                                label: Text('$idx'),
                                backgroundColor: Colors.orange.shade100,
                              ),
                            )
                            .toList(),
                      ),
                      if (missing.length > 10)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '+${missing.length - 10} فریم دیگر',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => notifier.reset(),
                  icon: const Icon(Icons.clear),
                  label: const Text('لغو'),
                ),
                if (session.isComplete)
                  ElevatedButton.icon(
                    onPressed: () => _completeTransfer(context, session),
                    icon: const Icon(Icons.check_circle),
                    label: const Text('تأیید'),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: () => cameraController.start(),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('ادامه اسکن'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleQrScan(String qrData, _TransferReceiveNotifier notifier) {
    try {
      final frame = TransferFrame.fromQrString(qrData);
      notifier.addFrame(frame);
    } catch (e) {
      notifier.setError(e.toString());
    }
  }

  void _completeTransfer(BuildContext context, TransferSession session) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأیید دریافت'),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('تعداد فریم‌های دریافت‌شده: ${session.receivedFrames.length}'),
            Text('شناسه انتقال: ${session.transferId.substring(0, 8)}...'),
            const SizedBox(height: 16),
            Text(
              'آیا می‌خواهید این داده‌ها را وارد کنید؟',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('لغو'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // In a real implementation, process the transfer and import
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('داده‌ها با موفقیت وارد شد')),
              );
            },
            child: const Text('تأیید'),
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatColumn({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
