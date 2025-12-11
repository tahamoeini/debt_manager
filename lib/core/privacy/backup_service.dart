import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt_pkg;
import 'package:path_provider/path_provider.dart';

class BackupService {
  // Derive a 32-byte key from password using PBKDF2 (SHA256)
  static List<int> _deriveKey(String password, String salt, {int iterations = 10000}) {
    final pass = utf8.encode(password);
    final saltBytes = utf8.encode(salt);
    final hmac = Hmac(sha256, pass);
    var key = <int>[];
    var block = <int>[];
    for (var i = 1; key.length < 32; i++) {
      final blockInput = <int>[]..addAll(block)..addAll(saltBytes)..addAll([0, 0, 0, i]);
      block = hmac.convert(blockInput).bytes;
      key.addAll(block);
    }
    return key.sublist(0, 32);
  }

  static Future<File> _backupFile(String name) async {
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory('${dir.path}/backups');
    if (!await folder.exists()) await folder.create(recursive: true);
    return File('${folder.path}/$name');
  }

  static Future<String> encryptAndSave(String plainJson, String password, {required String filename}) async {
    final salt = DateTime.now().millisecondsSinceEpoch.toString();
    final keyBytes = _deriveKey(password, salt);
    final key = encrypt_pkg.Key(Uint8List.fromList(keyBytes));
    final iv = encrypt_pkg.IV.fromSecureRandom(16);
    final encrypter = encrypt_pkg.Encrypter(encrypt_pkg.AES(key, mode: encrypt_pkg.AESMode.cbc));
    final encrypted = encrypter.encrypt(plainJson, iv: iv);

    // Store salt + iv + cipher in base64 JSON wrapper
    final wrapper = json.encode({
      'salt': salt,
      'iv': iv.base64,
      'data': encrypted.base64,
    });

    final file = await _backupFile(filename);
    await file.writeAsString(wrapper, flush: true);
    return file.path;
  }

  static Future<String> decryptFromFile(String path, String password) async {
    final f = File(path);
    if (!await f.exists()) throw Exception('Backup file not found');
    final raw = await f.readAsString();
    final map = json.decode(raw) as Map<String, dynamic>;
    final salt = map['salt'] as String;
    final ivb64 = map['iv'] as String;
    final datab64 = map['data'] as String;

    final keyBytes = _deriveKey(password, salt);
    final key = encrypt_pkg.Key(Uint8List.fromList(keyBytes));
    final iv = encrypt_pkg.IV.fromBase64(ivb64);
    final encrypter = encrypt_pkg.Encrypter(encrypt_pkg.AES(key, mode: encrypt_pkg.AESMode.cbc));
    final decrypted = encrypter.decrypt64(datab64, iv: iv);
    return decrypted;
  }

  static Future<void> deleteAllBackups() async {
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory('${dir.path}/backups');
    if (await folder.exists()) {
      await folder.delete(recursive: true);
    }
  }
}
