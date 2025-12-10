import 'package:local_auth/local_auth.dart';

/// SecurityService wraps the `local_auth` APIs and exposes a small,
/// testable surface for the app to perform biometric authentication.
class SecurityService {
  SecurityService._internal();
  static final SecurityService instance = SecurityService._internal();

  final LocalAuthentication _auth = LocalAuthentication();

  /// Whether biometrics are available on this device and enrolled.
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

  /// Perform biometric authentication with a platform-provided prompt.
  /// Returns true on success, false otherwise.
  Future<bool> authenticate({String reason = 'Authenticate to continue'}) async {
    try {
      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
      return didAuthenticate;
    } catch (_) {
      return false;
    }
  }
}
