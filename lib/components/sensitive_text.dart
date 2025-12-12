import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:debt_manager/core/settings/settings_repository.dart';

class SensitiveText extends ConsumerWidget {
  final String text;
  final TextStyle? style;

  const SensitiveText(this.text, {this.style, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ValueListenableBuilder<bool>(
      valueListenable: SettingsRepository.privacyModeNotifier,
      builder: (context, privacy, _) {
        if (!privacy) return Text(text, style: style);
        return GestureDetector(
          onTap: () {
            // Reveal temporarily by toggling the notifier off then on is
            // managed by callers (settings). For now, simple reveal on tap.
            SettingsRepository.privacyModeNotifier.value = false;
          },
          child: ClipRect(
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Text(text, style: style?.copyWith(color: Colors.transparent) ?? const TextStyle(color: Colors.transparent)),
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.2),
                    padding: EdgeInsets.zero,
                  ),
                ),
                Positioned.fill(
                  child: Center(
                    child: Icon(Icons.visibility_off, size: 16, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
