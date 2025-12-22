import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:debt_manager/core/security/security_service.dart';
import 'package:debt_manager/core/db/database_helper.dart';
import 'package:flutter/services.dart';
import 'package:debt_manager/core/providers/core_providers.dart';

// A full-screen modal that requests biometric authentication and only
// dismisses when authentication succeeds. Useful for locking the app on
// launch/resume.
class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  bool _authenticating = false;
  String? _error;
  bool _showPin = false;
  final _pinCtrl = TextEditingController();
  int _dbFailureCount = 0;

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
    // If database is encrypted, require PIN entry (biometric can't derive key).
    final dbEncrypted = await DatabaseHelper.instance.isDatabaseEncrypted();
    if (dbEncrypted) {
      final hasPin = await SecurityService.instance.hasPin();
      if (!mounted) return;
      if (hasPin) {
        setState(() {
          _authenticating = false;
          _showPin = true;
        });
        return;
      }
      setState(() {
        _authenticating = false;
        _error = 'پین برای باز کردن پایگاه داده تنظیم نشده است.';
      });
      return;
    }

    // Try biometric first. If unavailable or authentication fails,
    // fall back to PIN entry if a PIN exists.
    final avail = await SecurityService.instance.isBiometricAvailable();
    if (avail) {
      final ok = await SecurityService.instance.authenticate();
      if (!mounted) return;
      if (ok) {
        ref.read(authNotifierProvider).unlock();
        Navigator.of(context).pop(true);
        return;
      }
    }

    // If biometric not available or failed, check if PIN exists.
    final hasPin = await SecurityService.instance.hasPin();
    if (!mounted) return;
    if (hasPin) {
      setState(() {
        _authenticating = false;
        _showPin = true;
      });
      return;
    }

    setState(() {
      _authenticating = false;
      _error = 'احراز هویت ناموفق بود. لطفاً دوباره تلاش کنید.';
    });
  }

  Future<void> _verifyPin() async {
    setState(() {
      _authenticating = true;
      _error = null;
    });
    final pin = _pinCtrl.text.trim();
    final ok = await SecurityService.instance.verifyPin(pin);
    if (!mounted) return;
    if (ok) {
      // Derive DB key from PIN and attempt to open encrypted DB if present.
      final key = await SecurityService.instance.deriveKeyFromPin(pin);
      if (key != null) {
        try {
          await DatabaseHelper.instance.openWithKey(key);
        } catch (e) {
          // DB open failed - do NOT unlock the app
          debugPrint('Failed to open encrypted database with derived key: $e');
          _dbFailureCount++;
          setState(() {
            _authenticating = false;
            _error = 'باز کردن پایگاه داده با مشکل مواجه شد.\n'
                'اگر این خطا تکرار شد، برنامه را بسته و دوباره باز کنید. '
                'در صورت ادامهٔ مشکل، احتمال خرابی داده‌ها یا اشتباه بودن پین/رمز وجود دارد.';
          });
          return;
        }
      }
      // Only unlock if DB opened successfully (or no DB encryption)
      ref.read(authNotifierProvider).unlock();
      if (!mounted) return;
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _authenticating = false;
      _error = 'PIN نامعتبر است.';
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
                  Icon(
                    Icons.fingerprint,
                    size: 96,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'برای ادامه احراز هویت کنید',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  if (_authenticating) const CircularProgressIndicator(),
                  if (_showPin) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: 200,
                      child: TextField(
                        controller: _pinCtrl,
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        decoration: const InputDecoration(hintText: 'PIN'),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _authenticating ? null : _verifyPin,
                      child: const Text('بازکردن با PIN'),
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.red),
                    ),
                  ],
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _authenticating ? null : _authenticate,
                    child: const Text('تلاش مجدد'),
                  ),
                  if (_dbFailureCount >= 2) ...[
                    const SizedBox(height: 12),
                    Text(
                      'اگر مشکل ادامه داشت، ممکن است نیاز به بازیابی نسخه پشتیبان یا نصب مجدد برنامه باشد.',
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () => SystemNavigator.pop(),
                      child: const Text('خروج از برنامه'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
