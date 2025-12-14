import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'debug_logger.dart';
import 'package:flutter/scheduler.dart';

class _BoundsPainter extends CustomPainter {
  final List<Rect> rects;
  _BoundsPainter(this.rects);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0xFFFFC107).withValues(alpha: 0.9);
    for (final r in rects) {
      canvas.drawRect(r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BoundsPainter oldDelegate) =>
      !listEquals(oldDelegate.rects, rects);
}

// Simple overlay that highlights safe area insets and shows their values.
class DebugOverlay extends StatelessWidget {
  final Widget child;
  const DebugOverlay({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return child;
    return ValueListenableBuilder<bool>(
      valueListenable: DebugLogger.overlayEnabled,
      builder: (context, enabled, _) {
        final mq = MediaQuery.of(context);
        final top = mq.padding.top;
        final bottom = mq.padding.bottom;
        final left = mq.padding.left;
        final right = mq.padding.right;

        return Stack(
          children: [
            child,
            if (enabled) ...[
              // Top inset
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: top,
                child: Container(
                  color: Colors.red.withValues(alpha: 0.25),
                  child: Center(
                    child: Text('statusBar: ${top.toStringAsFixed(1)}'),
                  ),
                ),
              ),
              // Bottom inset
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: bottom,
                child: Container(
                  color: Colors.green.withValues(alpha: 0.25),
                  child: Center(
                    child: Text('bottomInset: ${bottom.toStringAsFixed(1)}'),
                  ),
                ),
              ),
              // Left
              Positioned(
                top: top,
                bottom: bottom,
                left: 0,
                width: left,
                child: Container(
                  color: Colors.blue.withValues(alpha: 0.12),
                  child: RotatedBox(
                    quarterTurns: 3,
                    child: Text('left: ${left.toStringAsFixed(1)}'),
                  ),
                ),
              ),
              // Right
              Positioned(
                top: top,
                bottom: bottom,
                right: 0,
                width: right,
                child: Container(
                  color: Colors.orange.withValues(alpha: 0.12),
                  child: RotatedBox(
                    quarterTurns: 1,
                    child: Text('right: ${right.toStringAsFixed(1)}'),
                  ),
                ),
              ),
            ],
            // Bounds overlay
            if (kDebugMode)
              ValueListenableBuilder<bool>(
                valueListenable: DebugLogger.showBoundsEnabled,
                builder: (context, show, _) {
                  if (!show) return const SizedBox.shrink();
                  return _BoundsOverlay();
                },
              ),
          ],
        );
      },
    );
  }
}

class _BoundsOverlay extends StatefulWidget {
  @override
  State<_BoundsOverlay> createState() => _BoundsOverlayState();
}

class _BoundsOverlayState extends State<_BoundsOverlay> {
  List<Rect> _rects = [];

  void _collectRects() {
    final root = WidgetsBinding.instance.rootElement;
    final rects = <Rect>[];
    void visit(Element? e) {
      if (e == null) return;
      final ro = e.renderObject;
      if (ro is RenderBox && ro.hasSize) {
        try {
          final topLeft = ro.localToGlobal(Offset.zero);
          rects.add(topLeft & ro.size);
        } catch (_) {}
      }
      e.visitChildren(visit);
    }

    visit(root);
    setState(() => _rects = rects);
  }

  @override
  void initState() {
    super.initState();
    // refresh after each frame while enabled
    SchedulerBinding.instance.addPersistentFrameCallback((_) {
      if (DebugLogger.showBoundsEnabled.value) _collectRects();
    });
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        size: MediaQuery.of(context).size,
        painter: _BoundsPainter(_rects),
      ),
    );
  }
}
