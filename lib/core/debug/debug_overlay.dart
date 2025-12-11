import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'debug_logger.dart';

/// Simple overlay that highlights safe area insets and shows their values.
class DebugOverlay extends StatelessWidget {
  final Widget child;
  const DebugOverlay({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return child;
    return ValueListenableBuilder<bool>(
      valueListenable: DebugLogger.overlayEnabled,
      builder: (context, enabled, _) {
        if (!enabled) return child;
        final mq = MediaQuery.of(context);
        final top = mq.padding.top;
        final bottom = mq.padding.bottom;
        final left = mq.padding.left;
        final right = mq.padding.right;

        return Stack(children: [
          child,
          // Top inset
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: top,
            child: Container(color: Colors.red.withOpacity(0.25), child: Center(child: Text('statusBar: ${top.toStringAsFixed(1)}'))),
          ),
          // Bottom inset
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: bottom,
            child: Container(color: Colors.green.withOpacity(0.25), child: Center(child: Text('bottomInset: ${bottom.toStringAsFixed(1)}'))),
          ),
          // Left
          Positioned(
            top: top,
            bottom: bottom,
            left: 0,
            width: left,
            child: Container(color: Colors.blue.withOpacity(0.12), child: RotatedBox(quarterTurns: 3, child: Text('left: ${left.toStringAsFixed(1)}'))),
          ),
          // Right
          Positioned(
            top: top,
            bottom: bottom,
            right: 0,
            width: right,
            child: Container(color: Colors.orange.withOpacity(0.12), child: RotatedBox(quarterTurns: 1, child: Text('right: ${right.toStringAsFixed(1)}'))),
          ),
        ]);
      },
    );
  }
}
