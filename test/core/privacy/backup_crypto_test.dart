import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:debt_manager/core/privacy/backup_crypto.dart';

void main() {
  test('AES-GCM PBKDF2 round-trip encrypt/decrypt JSON', () async {
    final password = 'strong-password-123';
    final jsonStr = jsonEncode({'a': 1, 'b': 'test'});
    final env = await BackupCrypto.encryptJsonAsync(jsonStr, password);
    final decrypted = await BackupCrypto.decryptJsonAsync(env, password);
    expect(decrypted, jsonStr);
  });

  test('Wrong password fails decryption', () async {
    final env = await BackupCrypto.encryptJsonAsync(jsonEncode({'x': 42}), 'pw1');
    expect(() => BackupCrypto.decryptJsonAsync(env, 'pw2'), throwsA(isA<Exception>()));
  });

  test('Tampered ciphertext fails with MAC validation error', () async {
    final env = await BackupCrypto.encryptJsonAsync(jsonEncode({'x': 42}), 'pw');
    final cipher = base64Decode(env['cipher'] as String);
    // Flip a bit
    cipher[0] = cipher[0] ^ 0xFF;
    final tampered = Map<String, dynamic>.from(env);
    tampered['cipher'] = base64Encode(cipher);
    expect(() => BackupCrypto.decryptJsonAsync(tampered, 'pw'), throwsA(isA<Exception>()));
  });
}
