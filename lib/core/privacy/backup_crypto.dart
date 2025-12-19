import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';

class BackupCrypto {
  static const int version = 2; // AES-256-GCM + PBKDF2-HMAC-SHA256

  static Future<SecretKey> _deriveKey(
    String password,
    Uint8List salt,
  ) async {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: 150000,
      bits: 256,
    );
    return pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: salt,
    );
  }

  static Map<String, dynamic> encryptJson(String json, String password) =>
      throw UnimplementedError('Use encryptJsonAsync');

  static Future<Map<String, dynamic>> encryptJsonAsync(
    String json,
    String password,
  ) async {
    final rand = Random.secure();
    final salt =
        Uint8List.fromList(List<int>.generate(16, (_) => rand.nextInt(256)));
    final nonce =
        Uint8List.fromList(List<int>.generate(12, (_) => rand.nextInt(256)));

    final algorithm = AesGcm.with256bits();
    final key = await _deriveKey(password, salt);
    final box = await algorithm.encrypt(
      utf8.encode(json),
      secretKey: key,
      nonce: nonce,
    );

    // Concatenate cipherText + mac for compact storage
    final combined = Uint8List.fromList([
      ...box.cipherText,
      ...box.mac.bytes,
    ]);

    return {
      'v': version,
      'salt': base64.encode(salt),
      'nonce': base64.encode(nonce),
      'cipher': base64.encode(combined),
    };
  }

  static Future<String> decryptJsonAsync(
    Map<String, dynamic> envelope,
    String password,
  ) async {
    final v = envelope['v'] as int? ?? 1;
    if (v != 2) {
      throw StateError('Unsupported envelope version: $v');
    }
    final salt = base64.decode(envelope['salt'] as String);
    final nonce = base64.decode(envelope['nonce'] as String);
    final combined = base64.decode(envelope['cipher'] as String);

    final algorithm = AesGcm.with256bits();
    final key = await _deriveKey(password, Uint8List.fromList(salt));

    // Split combined into cipherText + mac (last 16 bytes for GCM-128 tag)
    if (combined.length < 16) {
      throw StateError('Invalid ciphertext');
    }
    final macLen = 16;
    final cipherText = combined.sublist(0, combined.length - macLen);
    final macBytes = combined.sublist(combined.length - macLen);

    final box = SecretBox(cipherText, nonce: nonce, mac: Mac(macBytes));
    final decrypted = await algorithm.decrypt(box, secretKey: key);
    return utf8.decode(decrypted);
  }
}
