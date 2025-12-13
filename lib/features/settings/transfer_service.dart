// transfer_service.dart: QR code transfer service for peer-to-peer data sharing

import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

/// Exception for transfer-related errors
class TransferException implements Exception {
  final String message;
  final dynamic originalError;

  TransferException(this.message, [this.originalError]);

  @override
  String toString() => 'TransferException: $message';
}

/// Metadata for a transfer frame
class TransferFrame {
  final int frameIndex;
  final int totalFrames;
  final String frameId;
  final Uint8List data;
  final String checksum;
  final int timestamp;

  TransferFrame({
    required this.frameIndex,
    required this.totalFrames,
    required this.frameId,
    required this.data,
    required this.checksum,
    required this.timestamp,
  });

  /// Convert frame to QR-encodable string
  String toQrString() {
    final payload = {
      'v': 1, // Version
      'id': frameId,
      'idx': frameIndex,
      'total': totalFrames,
      'data': base64Encode(data).replaceAll(RegExp(r'[/+=]'), ''), // URL-safe base64
      'chk': checksum,
      'ts': timestamp,
    };
    return jsonEncode(payload);
  }

  /// Parse QR string back to frame
  factory TransferFrame.fromQrString(String qrString) {
    try {
      final json = jsonDecode(qrString) as Map<String, dynamic>;
      return TransferFrame(
        frameIndex: json['idx'] as int,
        totalFrames: json['total'] as int,
        frameId: json['id'] as String,
        data: base64Decode(_urlSafeBase64Decode(json['data'] as String)),
        checksum: json['chk'] as String,
        timestamp: json['ts'] as int,
      );
    } catch (e) {
      throw TransferException('خطا در تجزیه فریم QR: $e', e);
    }
  }

  @override
  String toString() =>
      'TransferFrame($frameIndex/$totalFrames, ${data.length} bytes)';
}

/// Manages QR code chunking and transfer
class TransferService {
  static const int maxQrDataSize = 2953; // Max alphanumeric QR data
  static const int maxPayloadSize = maxQrDataSize - 200; // Safety margin for metadata

  /// Chunk data into frames for QR transmission
  List<TransferFrame> chunkDataForTransfer(
    Uint8List data,
    String transferId,
  ) {
    try {
      if (data.isEmpty) {
        throw TransferException('داده‌ی خالی برای انتقال');
      }

      final frames = <TransferFrame>[];
      final totalFrames = (data.length / maxPayloadSize).ceil();

      for (var i = 0; i < totalFrames; i++) {
        final startIndex = i * maxPayloadSize;
        final endIndex = (i + 1) * maxPayloadSize;
        final chunkData = data.sublist(
          startIndex,
          endIndex > data.length ? data.length : endIndex,
        );

        final checksum = sha256.convert(chunkData).toString();
        final frame = TransferFrame(
          frameIndex: i,
          totalFrames: totalFrames,
          frameId: transferId,
          data: chunkData,
          checksum: checksum,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        );

        frames.add(frame);
      }

      return frames;
    } catch (e) {
      throw TransferException('خطا در تقسیم داده: $e', e);
    }
  }

  /// Reassemble frames back into original data
  Uint8List reassembleFrames(List<TransferFrame> frames) {
    try {
      if (frames.isEmpty) {
        throw TransferException('هیچ فریمی برای بازسازی وجود ندارد');
      }

      // Sort by frame index
      final sortedFrames = List<TransferFrame>.from(frames);
      sortedFrames.sort((a, b) => a.frameIndex.compareTo(b.frameIndex));

      // Verify frame sequence
      for (var i = 0; i < sortedFrames.length; i++) {
        if (sortedFrames[i].frameIndex != i) {
          throw TransferException(
            'توالی فریم نادرست: انتظار $i، دریافت ${sortedFrames[i].frameIndex}',
          );
        }
      }

      // Verify all frames have same transferId
      final firstId = sortedFrames[0].frameId;
      if (sortedFrames.any((f) => f.frameId != firstId)) {
        throw TransferException('شناسه‌ی انتقال مطابقت ندارد');
      }

      // Reassemble
      final result = BytesBuilder();
      for (final frame in sortedFrames) {
        result.add(frame.data);
      }

      return result.toBytes();
    } catch (e) {
      throw TransferException('خطا در بازسازی فریم‌ها: $e', e);
    }
  }

  /// Validate transfer checksum
  bool validateFrameChecksum(TransferFrame frame) {
    final calculatedChecksum = sha256.convert(frame.data).toString();
    return calculatedChecksum == frame.checksum;
  }

  /// Validate complete transfer
  bool validateTransfer(List<TransferFrame> frames, Uint8List originalData) {
    try {
      // Check all frames valid individually
      for (final frame in frames) {
        if (!validateFrameChecksum(frame)) {
          return false;
        }
      }

      // Reassemble and verify size
      final reassembled = reassembleFrames(frames);
      return reassembled.length == originalData.length;
    } catch (_) {
      return false;
    }
  }

  /// Calculate transfer completion percentage
  double calculateProgress(int receivedFrames, int totalFrames) {
    if (totalFrames <= 0) return 0.0;
    return (receivedFrames / totalFrames).clamp(0.0, 1.0);
  }

  /// Get human-readable transfer size
  String formatTransferSize(Uint8List data) {
    return _formatBytes(data.length);
  }

  /// Get estimated QR count
  int estimateQrCount(Uint8List data) {
    return (data.length / maxPayloadSize).ceil();
  }

  /// Format bytes to human-readable string
  String _formatBytes(int bytes) {
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var size = bytes.toDouble();
    var suffixIndex = 0;

    while (size > 1024 && suffixIndex < suffixes.length - 1) {
      size /= 1024;
      suffixIndex++;
    }

    return '${size.toStringAsFixed(2)} ${suffixes[suffixIndex]}';
  }
}

/// Helper to convert URL-safe base64 back to standard base64
String _urlSafeBase64Decode(String input) {
  // Replace URL-safe characters with standard base64
  var output = input.replaceAll('-', '+').replaceAll('_', '/');

  // Add padding if needed
  switch (output.length % 4) {
    case 2:
      output += '==';
      break;
    case 3:
      output += '=';
      break;
  }

  return output;
}

/// Transfer session for tracking ongoing transfers
class TransferSession {
  final String transferId;
  final int totalFrames;
  final int createdAt;
  final Map<int, TransferFrame> receivedFrames = {};

  TransferSession({
    required this.transferId,
    required this.totalFrames,
    DateTime? createdAt,
  }) : createdAt = (createdAt ?? DateTime.now()).millisecondsSinceEpoch;

  /// Add a received frame to the session
  void addFrame(TransferFrame frame) {
    if (frame.frameId != transferId) {
      throw TransferException('شناسه‌ی انتقال مطابقت ندارد');
    }
    if (frame.frameIndex >= totalFrames) {
      throw TransferException('شاخص فریم نامعتبر');
    }
    receivedFrames[frame.frameIndex] = frame;
  }

  /// Check if transfer is complete
  bool get isComplete => receivedFrames.length == totalFrames;

  /// Get progress percentage
  double get progress => receivedFrames.length / totalFrames;

  /// Get missing frame indices
  List<int> getMissingFrames() {
    final missing = <int>[];
    for (var i = 0; i < totalFrames; i++) {
      if (!receivedFrames.containsKey(i)) {
        missing.add(i);
      }
    }
    return missing;
  }

  /// Get all frames in order
  List<TransferFrame> getOrderedFrames() {
    final frames = <TransferFrame>[];
    for (var i = 0; i < totalFrames; i++) {
      if (receivedFrames.containsKey(i)) {
        frames.add(receivedFrames[i]!);
      }
    }
    return frames;
  }

  /// Check if session expired (>10 minutes)
  bool get isExpired {
    final ageMs = DateTime.now().millisecondsSinceEpoch - createdAt;
    return ageMs > 10 * 60 * 1000; // 10 minutes
  }

  @override
  String toString() =>
      'TransferSession($transferId, $progress complete, ${getMissingFrames().length} missing)';
}

/// Manager for multiple transfer sessions
class TransferSessionManager {
  final Map<String, TransferSession> _sessions = {};

  /// Create new transfer session
  TransferSession createSession(String transferId, int totalFrames) {
    if (_sessions.containsKey(transferId)) {
      throw TransferException('جلسه‌ی انتقال از قبل وجود دارد');
    }
    final session = TransferSession(transferId: transferId, totalFrames: totalFrames);
    _sessions[transferId] = session;
    return session;
  }

  /// Get existing session
  TransferSession? getSession(String transferId) {
    return _sessions[transferId];
  }

  /// Add frame to session
  void addFrame(String transferId, TransferFrame frame) {
    var session = _sessions[transferId];
    if (session == null) {
      // Auto-create session if receiving first frame
      session = createSession(transferId, frame.totalFrames);
    }
    session.addFrame(frame);
  }

  /// Complete and remove session
  TransferSession? completeSession(String transferId) {
    return _sessions.remove(transferId);
  }

  /// Clean up expired sessions
  void cleanupExpiredSessions() {
    _sessions.removeWhere((_, session) => session.isExpired);
  }

  /// Get all active sessions
  List<TransferSession> getActiveSessions() {
    cleanupExpiredSessions();
    return _sessions.values.toList();
  }
}
