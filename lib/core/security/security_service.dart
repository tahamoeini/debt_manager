import 'dart:convert';
import 'dart:math';
import 'package:local_auth/local_auth.dart';
import 'package:debt_manager/core/security/secure_storage_service.dart';
import 'package:pointycastle/pointycastle.dart';
import 'dart:typed_data';

// SecurityService wraps the `local_auth` APIs and exposes a small,
// testable surface for the app to perform biometric authentication.
class SecurityService {
  SecurityService._internal();
  static final SecurityService instance = SecurityService._internal();

  final LocalAuthentication _auth = LocalAuthentication();
  static const _pinKey = 'app_pin_hash';
  static const _pinSaltKey = 'app_pin_salt';
  static const _pinFailCountKey = 'app_pin_fail_count';
  static const _pinLockoutUntilKey = 'app_pin_lockout_until_ms';

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
  Future<bool> authenticate({
    String reason = 'Authenticate to continue',
  }) async {
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
    // Generate a random salt and store salt + salted hash.
    final saltBytes = List<int>.generate(
      16,
      (_) => Random.secure().nextInt(256),
    );
    final salt = base64.encode(saltBytes);
    // Store a salted PBKDF2-derived hash for verification
    final hashBytes = _deriveKeyPBKDF2(
      Uint8List.fromList(utf8.encode(pin)),
      Uint8List.fromList(saltBytes),
      10000,
      32,
    );
    final hash = _bytesToHex(hashBytes);
    await SecureStorageService.instance.write(_pinSaltKey, salt);
    await SecureStorageService.instance.write(_pinKey, hash);
    await SecureStorageService.instance.delete(_pinFailCountKey);
    await SecureStorageService.instance.delete(_pinLockoutUntilKey);
  }

  Future<bool> verifyPin(String pin) async {
    // Check lockout
    final lockoutStr = await SecureStorageService.instance.read(_pinLockoutUntilKey);
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    if (lockoutStr != null) {
      final until = int.tryParse(lockoutStr) ?? 0;
      if (until > nowMs) return false;
    }

    final stored = await SecureStorageService.instance.read(_pinKey);
    final salt = await SecureStorageService.instance.read(_pinSaltKey);
    if (stored == null || salt == null) return false;
    final saltBytes = Uint8List.fromList(base64.decode(salt));
    final hashBytes = _deriveKeyPBKDF2(
      Uint8List.fromList(utf8.encode(pin)),
      saltBytes,
      10000,
      32,
    );
    final storedBytes = _hexToBytes(stored);
    final ok = _constantTimeEquals(storedBytes, hashBytes);

    if (ok) {
      // Reset counters
      await SecureStorageService.instance.delete(_pinFailCountKey);
      await SecureStorageService.instance.delete(_pinLockoutUntilKey);
      return true;
    }

    // Wrong PIN: increment fail count and set lockout if threshold exceeded
    final failsStr = await SecureStorageService.instance.read(_pinFailCountKey);
    final fails = (int.tryParse(failsStr ?? '0') ?? 0) + 1;
    await SecureStorageService.instance.write(_pinFailCountKey, fails.toString());

    if (fails >= 5) {
      // Exponential backoff starting at 30s, doubling up to 15min
      final base = 30000; // 30s
      final maxMs = 900000; // 15min
      final lockMs = (base * (1 << (fails - 5))).clamp(base, maxMs);
      await SecureStorageService.instance.write(
        _pinLockoutUntilKey,
        (nowMs + lockMs).toString(),
      );
    }
    return false;
  }

  Future<bool> hasPin() async {
    final stored = await SecureStorageService.instance.read(_pinKey);
    final salt = await SecureStorageService.instance.read(_pinSaltKey);
    return stored != null && salt != null;
  }

  Future<void> deletePin() async {
    await SecureStorageService.instance.delete(_pinKey);
    await SecureStorageService.instance.delete(_pinSaltKey);
  }

  /// Derive an encryption key for DB usage from the user's PIN.
  /// The derived key is not stored; only the salt and verification hash
  /// are persisted by `setPin`.
  Future<String?> deriveKeyFromPin(String pin) async {
    final salt = await SecureStorageService.instance.read(_pinSaltKey);
    if (salt == null) return null;
    final saltBytes = Uint8List.fromList(base64.decode(salt));
    final derived = _deriveKeyPBKDF2(
      Uint8List.fromList(utf8.encode(pin)),
      saltBytes,
      10000,
      32,
    );
    return _bytesToHex(derived);
  }

  // Derive a key using PBKDF2 (HMAC-SHA256) via pointycastle
  Uint8List _deriveKeyPBKDF2(
    Uint8List password,
    Uint8List salt,
    int iterations,
    int dkLen,
  ) {
    final pbkdf2 = KeyDerivator('PBKDF2/HMAC/SHA-256')
      ..init(Pbkdf2Parameters(salt, iterations, dkLen));
    return pbkdf2.process(password);
  }

  String _bytesToHex(Uint8List bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  Uint8List _hexToBytes(String hex) {
    final out = Uint8List(hex.length ~/ 2);
    for (var i = 0; i < hex.length; i += 2) {
      out[i ~/ 2] = int.parse(hex.substring(i, i + 2), radix: 16);
    }
    return out;
  }

  bool _constantTimeEquals(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}
