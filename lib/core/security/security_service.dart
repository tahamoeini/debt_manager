import 'package:local_auth/local_auth.dart';
import 'package:debt_manager/core/security/secure_storage_service.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

// SecurityService wraps the `local_auth` APIs and exposes a small,
// testable surface for the app to perform biometric authentication.
class SecurityService {
  SecurityService._internal();
  static final SecurityService instance = SecurityService._internal();

  final LocalAuthentication _auth = LocalAuthentication();
  static const _pinKey = 'app_pin_hash';

  // Whether biometrics are available on this device and enrolled.
  Future<bool> isBiometricAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      if (!canCheck) return false;
      final available = await _auth.getAvailableBiometrics();
      return available.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // Perform biometric authentication with a platform-provided prompt.
  // Returns true on success, false otherwise.
  Future<bool> authenticate(
      {String reason = 'Authenticate to continue'}) async {
    try {
      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: reason,
      );
      return didAuthenticate;
    } catch (_) {
      return false;
    }
  }

  // PIN management using secure storage. PINs are hashed with SHA256
  // before persisting in secure storage.
  Future<void> setPin(String pin) async {
    final hash = sha256.convert(utf8.encode(pin)).toString();
    await SecureStorageService.instance.write(_pinKey, hash);
  }

  Future<bool> verifyPin(String pin) async {
    final stored = await SecureStorageService.instance.read(_pinKey);
    if (stored == null) return false;
    final hash = sha256.convert(utf8.encode(pin)).toString();
    return stored == hash;
  }

  Future<bool> hasPin() async {
    final stored = await SecureStorageService.instance.read(_pinKey);
    return stored != null;
  }

  Future<void> deletePin() async {
    await SecureStorageService.instance.delete(_pinKey);
  }
}
