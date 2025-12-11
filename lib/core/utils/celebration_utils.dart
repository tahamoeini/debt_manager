// Celebration utilities: animations for achievements and milestones
import 'package:flutter/material.dart';
import 'dart:math' as math;

// Duration for auto-dismissing celebration dialogs
const Duration _autoDismissDuration = Duration(seconds: 3);

/// Shows a celebration animation when a debt is fully paid off
Future<void> showDebtCompletionCelebration(BuildContext context) async {
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => const _CelebrationDialog(),
  );
}

class _CelebrationDialog extends StatefulWidget {
  const _CelebrationDialog();

  @override
  State<_CelebrationDialog> createState() => _CelebrationDialogState();
}

class _CelebrationDialogState extends State<_CelebrationDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );

    _controller.forward();

    // Auto-dismiss after configured duration
    Future.delayed(_autoDismissDuration, () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ConfettiAnimation(controller: _controller),
                const SizedBox(height: 16),
                Icon(
                  Icons.celebration_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  '🎉 تبریک! 🎉',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'بدهی شما کامل شد!',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('عالی!'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ConfettiAnimation extends StatelessWidget {
  const _ConfettiAnimation({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          return CustomPaint(
            size: const Size(200, 100),
            painter: _ConfettiPainter(controller.value),
          );
        },
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.progress);

  final double progress;
  final _random = math.Random(42); // Fixed seed for consistent animation

  @override
  void paint(Canvas canvas, Size size) {
    const confettiCount = 20;
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.purple,
      Colors.orange,
    ];

    for (var i = 0; i < confettiCount; i++) {
      final x = size.width * (i / confettiCount);
      final y = size.height * progress * (0.5 + _random.nextDouble() * 0.5);
      final rotation = progress * math.pi * 2 * (1 + i % 3);
      final color = colors[i % colors.length];

      final paint = Paint()
        ..color = color.withValues(alpha: 1.0 - progress * 0.5)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);
      canvas.drawRect(
        const Rect.fromLTWH(-4, -8, 8, 16),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Shows a simple success animation for achieving a goal
Future<void> showSuccessAnimation(
  BuildContext context, {
  required String title,
  required String message,
}) async {
  await showDialog(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => AlertDialog(
      icon:
          const Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
      title: Text(title, textAlign: TextAlign.center),
      content: Text(message, textAlign: TextAlign.center),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('تایید'),
        ),
      ],
    ),
  );
}

/// Show an achievement dialog with badge-like appearance.
Future<void> showAchievementDialog(BuildContext context,
    {required String title, required String message, IconData? icon}) async {
  await showDialog(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon ?? Icons.emoji_events_outlined,
                size: 64, color: Theme.of(ctx).colorScheme.primary),
            const SizedBox(height: 12),
            Text(title,
                style: Theme.of(ctx).textTheme.titleLarge,
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('تبریک'),
            ),
          ],
        ),
      ),
    ),
  );
}
