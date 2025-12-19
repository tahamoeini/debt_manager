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
    final env =
        await BackupCrypto.encryptJsonAsync(jsonEncode({'x': 42}), 'pw1');
    expect(
      () => BackupCrypto.decryptJsonAsync(env, 'pw2'),
      throwsA(isA<Exception>()),
    );
  });

  test('Tampered ciphertext fails with MAC validation error', () async {
    final env =
        await BackupCrypto.encryptJsonAsync(jsonEncode({'x': 42}), 'pw');
    final cipher = base64Decode(env['cipher'] as String);
    // Flip a bit
    cipher[0] = cipher[0] ^ 0xFF;
    final tampered = Map<String, dynamic>.from(env);
    tampered['cipher'] = base64Encode(cipher);
    expect(
      () => BackupCrypto.decryptJsonAsync(tampered, 'pw'),
      throwsA(isA<Exception>()),
    );
  });

  group('BackupCrypto comprehensive tests', () {
    const testPassword = 'secure_password_123';

    test('envelope contains all required fields', () async {
      final testJson = jsonEncode({'id': 1, 'title': 'Test'});
      final envelope = await BackupCrypto.encryptJsonAsync(
        testJson,
        testPassword,
      );

      expect(envelope, isA<Map<String, dynamic>>());
      expect(envelope['v'], BackupCrypto.version);
      expect(envelope['salt'], isA<String>());
      expect(envelope['nonce'], isA<String>());
      expect(envelope['cipher'], isA<String>());
    });

    test('large JSON roundtrip', () async {
      // Create a large JSON payload
      final largeLoans = List.generate(
        50,
        (i) => {'id': i, 'title': 'Loan $i', 'amount': 1000 + i},
      );
      final largeJson = jsonEncode({'loans': largeLoans});

      final envelope = await BackupCrypto.encryptJsonAsync(
        largeJson,
        testPassword,
      );

      final decrypted = await BackupCrypto.decryptJsonAsync(
        envelope,
        testPassword,
      );

      expect(decrypted, largeJson);
    });

    test('special characters in password', () async {
      const specialPassword = 'p@ssw0rd!#\$%^&*()_+-=[]{}|;:,.<>?';
      final testJson = jsonEncode({'data': 'test'});

      final envelope = await BackupCrypto.encryptJsonAsync(
        testJson,
        specialPassword,
      );

      final decrypted = await BackupCrypto.decryptJsonAsync(
        envelope,
        specialPassword,
      );

      expect(decrypted, testJson);
    });

    test('unicode in JSON payload (Persian)', () async {
      final unicodeJson = jsonEncode({
        'title': 'وام',
        'amount': 10000,
        'note': 'تست یونیکد',
      });

      final envelope = await BackupCrypto.encryptJsonAsync(
        unicodeJson,
        testPassword,
      );

      final decrypted = await BackupCrypto.decryptJsonAsync(
        envelope,
        testPassword,
      );

      expect(decrypted, unicodeJson);
    });

    test('different encryptions produce different ciphers', () async {
      final testJson = jsonEncode({'data': 'test'});

      final envelope1 = await BackupCrypto.encryptJsonAsync(
        testJson,
        testPassword,
      );

      final envelope2 = await BackupCrypto.encryptJsonAsync(
        testJson,
        testPassword,
      );

      // Due to random salt and nonce, ciphers should be different
      expect(envelope1['cipher'], isNot(equals(envelope2['cipher'])));
    });

    test('consistent decryption with same envelope', () async {
      final testJson = jsonEncode({'data': 'test'});

      final envelope = await BackupCrypto.encryptJsonAsync(
        testJson,
        testPassword,
      );

      final decrypted1 = await BackupCrypto.decryptJsonAsync(
        envelope,
        testPassword,
      );

      final decrypted2 = await BackupCrypto.decryptJsonAsync(
        envelope,
        testPassword,
      );

      expect(decrypted1, decrypted2);
      expect(decrypted1, testJson);
    });

    test('empty JSON roundtrip', () async {
      const emptyJson = '{}';

      final envelope = await BackupCrypto.encryptJsonAsync(
        emptyJson,
        testPassword,
      );

      final decrypted = await BackupCrypto.decryptJsonAsync(
        envelope,
        testPassword,
      );

      expect(decrypted, emptyJson);
    });

    test('unsupported envelope version throws', () async {
      final invalidEnvelope = {
        'v': 1, // Old version
        'salt': base64Encode(
            [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]),
        'nonce': base64Encode([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]),
        'cipher': base64Encode(
            [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]),
      };

      expect(
        () => BackupCrypto.decryptJsonAsync(
          invalidEnvelope,
          testPassword,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('corrupt envelope structure throws', () async {
      final corruptEnvelope = {
        'v': 2,
        // Missing 'salt', 'nonce', or 'cipher'
      };

      expect(
        () => BackupCrypto.decryptJsonAsync(
          corruptEnvelope as Map<String, dynamic>,
          testPassword,
        ),
        throwsA(isA<TypeError>()),
      );
    });

    test('very long password', () async {
      final longPassword = 'a' * 1000;
      final testJson = jsonEncode({'data': 'test'});

      final envelope = await BackupCrypto.encryptJsonAsync(
        testJson,
        longPassword,
      );

      final decrypted = await BackupCrypto.decryptJsonAsync(
        envelope,
        longPassword,
      );

      expect(decrypted, testJson);
    });
  });
}
