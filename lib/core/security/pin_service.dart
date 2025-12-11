import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'secure_storage_service.dart';

class PinService {
  static final PinService instance = PinService._internal();
  PinService._internal();
  factory PinService() => instance;

  final SecureStorageService _secure = SecureStorageService();

  Future<void> setPin(String pin) async {
    final salt = _generateSalt();
    final hash = _hashPin(pin, salt);
    await _secure.write('pin_salt', salt);
    await _secure.write('pin_hash', hash);
  }

  Future<void> removePin() async {
    await _secure.delete('pin_salt');
    await _secure.delete('pin_hash');
  }

  Future<bool> hasPin() async {
    final h = await _secure.read('pin_hash');
    return h != null;
  }

  Future<bool> verifyPin(String pin) async {
    final salt = await _secure.read('pin_salt');
    final stored = await _secure.read('pin_hash');
    if (salt == null || stored == null) return false;
    final h = _hashPin(pin, salt);
    return constantTimeEquality(h, stored);
  }

  String _generateSalt() {
    final r = Random.secure();
    final bytes = List<int>.generate(16, (_) => r.nextInt(256));
    return base64Url.encode(bytes);
  }

  String _hashPin(String pin, String salt) {
    final bytes = utf8.encode(salt + pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  bool constantTimeEquality(String a, String b) {
    if (a.length != b.length) return false;
    var res = 0;
    for (var i = 0; i < a.length; i++) {
      res |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return res == 0;
  }
}
