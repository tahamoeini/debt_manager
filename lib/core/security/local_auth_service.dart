import 'package:local_auth/local_auth.dart';

class LocalAuthService {
  static final LocalAuthService instance = LocalAuthService._internal();
  LocalAuthService._internal();
  factory LocalAuthService() => instance;

  final LocalAuthentication _auth = LocalAuthentication();

  /// Attempt biometric/local device authentication. Returns true if succeeded.
  Future<bool> authenticate(
      {String reason = 'Authenticate to continue'}) async {
    try {
      final can = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();
      if (!can && !isDeviceSupported) return false;
      final didAuthenticate = await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: false,
      );
      return didAuthenticate;
    } catch (_) {
      return false;
    }
  }
}
