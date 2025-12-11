import 'package:flutter/material.dart';
import 'package:debt_manager/core/security/security_service.dart';

/// A full-screen modal that requests biometric authentication and only
/// dismisses when authentication succeeds. Useful for locking the app on
/// launch/resume.
class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  bool _authenticating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _authenticate());
  }

  Future<void> _authenticate() async {
    setState(() {
      _authenticating = true;
      _error = null;
    });

    final ok = await SecurityService.instance.authenticate();

    if (!mounted) return;

    if (ok) {
      Navigator.of(context).pop(true);
      return;
    }

    setState(() {
      _authenticating = false;
      _error = 'احراز هویت ناموفق بود. لطفاً دوباره تلاش کنید.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.fingerprint,
                      size: 96, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 16),
                  Text('برای ادامه احراز هویت کنید',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  if (_authenticating) const CircularProgressIndicator(),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Colors.red)),
                  ],
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _authenticating ? null : _authenticate,
                    child: const Text('تلاش مجدد'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
