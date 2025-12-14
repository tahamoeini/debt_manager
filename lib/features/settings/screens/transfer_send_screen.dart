// transfer_send_screen.dart: QR code sender for peer-to-peer data transfer

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:debt_manager/features/settings/transfer_service.dart';

/// State for transfer send
class _TransferSendState {
  final List<TransferFrame>? frames;
  final int currentFrameIndex;
  final bool isPlaying;
  final String? error;
  final String transferId;
  final DateTime? startedAt;

  _TransferSendState({
    this.frames,
    this.currentFrameIndex = 0,
    this.isPlaying = false,
    this.error,
    required this.transferId,
    this.startedAt,
  });

  _TransferSendState copyWith({
    List<TransferFrame>? frames,
    int? currentFrameIndex,
    bool? isPlaying,
    String? error,
    String? transferId,
    DateTime? startedAt,
  }) {
    return _TransferSendState(
      frames: frames ?? this.frames,
      currentFrameIndex: currentFrameIndex ?? this.currentFrameIndex,
      isPlaying: isPlaying ?? this.isPlaying,
      error: error ?? this.error,
      transferId: transferId ?? this.transferId,
      startedAt: startedAt ?? this.startedAt,
    );
  }

  double get progress => frames == null
      ? 0.0
      : (currentFrameIndex + 1) / frames!.length.toDouble();
}

/// Notifier for transfer send state
class _TransferSendNotifier extends StateNotifier<_TransferSendState> {
  _TransferSendNotifier()
    : super(_TransferSendState(transferId: _generateTransferId()));

  static String _generateTransferId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  void setFrames(List<TransferFrame> frames) {
    state = state.copyWith(frames: frames);
  }

  void setCurrentFrame(int index) {
    state = state.copyWith(currentFrameIndex: index);
  }

  void setIsPlaying(bool playing) {
    state = state.copyWith(isPlaying: playing);
  }

  void setError(String error) {
    state = state.copyWith(error: error);
  }

  void nextFrame() {
    if (state.frames != null &&
        state.currentFrameIndex < state.frames!.length - 1) {
      state = state.copyWith(currentFrameIndex: state.currentFrameIndex + 1);
    }
  }

  void reset() {
    state = _TransferSendState(transferId: _generateTransferId());
  }
}

final _transferSendProvider =
    StateNotifierProvider<_TransferSendNotifier, _TransferSendState>((ref) {
      return _TransferSendNotifier();
    });

/// QR transfer sender screen
class TransferSendScreen extends ConsumerStatefulWidget {
  const TransferSendScreen({super.key});

  @override
  ConsumerState<TransferSendScreen> createState() => _TransferSendScreenState();
}

class _TransferSendScreenState extends ConsumerState<TransferSendScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _frameController;
  final TransferService _transferService = TransferService();

  @override
  void initState() {
    super.initState();
    _frameController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _frameController.addStatusListener(_onAnimationStatusChanged);
  }

  @override
  void dispose() {
    _frameController.dispose();
    super.dispose();
  }

  void _onAnimationStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      final notifier = ref.read(_transferSendProvider.notifier);
      final state = ref.read(_transferSendProvider);

      if (state.frames != null &&
          state.currentFrameIndex < state.frames!.length - 1) {
        notifier.nextFrame();
        _frameController.reset();
        _frameController.forward();
      } else if (state.isPlaying && state.frames != null) {
        // Reached last frame, stop playing
        notifier.setIsPlaying(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(_transferSendProvider);
    final notifier = ref.read(_transferSendProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('انتقال از طریق QR Code'), elevation: 0),
      body: SafeArea(
        child: state.frames == null
            ? _buildEmptyState(context, notifier)
            : _buildSenderState(context, state, notifier),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    _TransferSendNotifier notifier,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('انتقال داده‌ها', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Text(
            'برای شروع انتقال داده‌ها از طریق QR Code، یک نسخه‌ی پشتیبان یا داده‌ی موجود را انتخاب کنید.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () async {
              // In a real implementation, this would select backup data
              // For now, we'll create sample frames
              try {
                final sampleData = List<int>.generate(1000, (i) => i % 256);
                final frames = _transferService.chunkDataForTransfer(
                  _bytesListToUint8List(sampleData),
                  'sample_transfer',
                );
                notifier.setFrames(frames);
              } catch (e) {
                notifier.setError(e.toString());
              }
            },
            icon: const Icon(Icons.backup),
            label: const Text('انتخاب داده برای انتقال'),
          ),
        ],
      ),
    );
  }

  Widget _buildSenderState(
    BuildContext context,
    _TransferSendState state,
    _TransferSendNotifier notifier,
  ) {
    final frames = state.frames!;
    final currentFrame = frames[state.currentFrameIndex];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'فریم ${state.currentFrameIndex + 1} از ${frames.length}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(value: state.progress, minHeight: 8),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // QR Code
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: _buildQrCode(currentFrame.toQrString()),
                    ),
                    const SizedBox(height: 16),
                    // Frame info
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            _InfoRow(
                              'حجم:',
                              '${currentFrame.data.length} بایت',
                            ),
                            _InfoRow(
                              'چک‌سام:',
                              '${currentFrame.checksum.substring(0, 16)}...',
                            ),
                            _InfoRow(
                              'زمان:',
                              _formatTimestamp(currentFrame.timestamp),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton.icon(
                onPressed: state.currentFrameIndex > 0
                    ? () {
                        notifier.setCurrentFrame(state.currentFrameIndex - 1);
                        _frameController.reset();
                        if (state.isPlaying) {
                          _frameController.forward();
                        }
                      }
                    : null,
                icon: const Icon(Icons.arrow_back),
                label: const Text('قبلی'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  if (state.isPlaying) {
                    notifier.setIsPlaying(false);
                    _frameController.stop();
                  } else {
                    notifier.setIsPlaying(true);
                    _frameController.forward();
                  }
                },
                icon: Icon(state.isPlaying ? Icons.pause : Icons.play_arrow),
                label: Text(state.isPlaying ? 'مکث' : 'پخش'),
              ),
              ElevatedButton.icon(
                onPressed: state.currentFrameIndex < frames.length - 1
                    ? () {
                        notifier.setCurrentFrame(state.currentFrameIndex + 1);
                        _frameController.reset();
                        if (state.isPlaying) {
                          _frameController.forward();
                        }
                      }
                    : null,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('بعدی'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Info
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.info, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'اسکن کنید QR Code را برای دریافت داده‌ها. می‌توانید برای مشاهده‌ی فریم‌های بعدی کدهای دیگر را اسکن کنید.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(int ms) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(ms);
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
  }

  Widget _buildQrCode(String data) {
    // QR Code placeholder - displays the data
    return Container(
      width: 300,
      height: 300,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
        color: Colors.white,
      ),
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              data,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 8, fontFamily: 'monospace'),
              maxLines: 50,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

Uint8List _bytesListToUint8List(List<int> list) {
  return Uint8List.fromList(list);
}
