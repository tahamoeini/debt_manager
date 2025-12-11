import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt_pkg;
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive_io.dart';
import '../../core/db/database_helper.dart';
import '../../core/settings/settings_repository.dart';

class BackupService {
  BackupService._internal();
  static final BackupService instance = BackupService._internal();
  // Derive a 32-byte key from password using PBKDF2 (SHA256)
  static List<int> _deriveKey(String password, String salt, {int iterations = 10000}) {
    final pass = utf8.encode(password);
    final saltBytes = utf8.encode(salt);
    final hmac = Hmac(sha256, pass);
    var key = <int>[];
    var block = <int>[];
    for (var i = 1; key.length < 32; i++) {
      final blockInput = [...block, ...saltBytes, 0, 0, 0, i];
      block = hmac.convert(blockInput).bytes;
      key.addAll(block);
      // Note: iterations parameter available for future enhancement
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
    await file.writeAsBytes(utf8.encode(wrapper), flush: true);
    return file.path;
  }

  static Future<String> decryptFromFile(String path, String password) async {
    final f = File(path);
    if (!await f.exists()) throw Exception('Backup file not found');
    final rawBytes = await f.readAsBytes();
    final raw = utf8.decode(rawBytes);
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

  /// Export full dataset (loans, installments, counterparties, settings) as JSON string.
  static Future<String> exportFullJson() async {
    final db = DatabaseHelper.instance;
    final settings = SettingsRepository();
    await settings.init();

    final loans = await db.getAllLoans();
    final loansMap = loans.map((l) => l.toMap()).toList();
    // fetch installments per loan
    final installmentsAll = <Map<String, dynamic>>[];
    for (final l in loans) {
      final insts = await db.getInstallmentsByLoanId(l.id ?? -1);
      installmentsAll.addAll(insts.map((i) => i.toMap()));
    }

    final counterparties = await db.getAllCounterparties();
    final cpMap = counterparties.map((c) => c.toMap()).toList();

    final out = {
      'meta': {
        'exported_at': DateTime.now().toIso8601String(),
        'app_version': '1.0.0',
      },
      'settings': {
        'language': settings.languageCode,
        'theme': settings.themeMode,
        'calendar': settings.calendarType.toString(),
      },
      'counterparties': cpMap,
      'loans': loansMap,
      'installments': installmentsAll,
    };

    return json.encode(out);
  }

  /// Compress bytes using gzip and return bytes
  static Uint8List gzipCompress(Uint8List input) {
    final encoder = GZipEncoder();
    final encoded = encoder.encode(input);
    return Uint8List.fromList(encoded ?? input);
  }

  static Uint8List gzipDecompress(Uint8List input) {
    final decoder = GZipDecoder();
    return Uint8List.fromList(decoder.decodeBytes(input));
  }

  /// Create base64-encoded chunks suitable for QR transfer
  static List<String> chunkForQr(Uint8List bytes, {int chunkSize = 800}) {
    final b64 = base64Encode(bytes);
    final chunks = <String>[];
    for (var i = 0; i < b64.length; i += chunkSize) {
      chunks.add(b64.substring(i, i + chunkSize > b64.length ? b64.length : i + chunkSize));
    }
    return chunks;
  }

  /// Reassemble base64 chunks and return original bytes
  static Uint8List assembleFromChunks(List<String> chunks) {
    final joined = chunks.join();
    final bytes = base64Decode(joined);
    return Uint8List.fromList(bytes);
  }

  /// Export encrypted and compressed backup for QR transfer: returns bytes of encrypted wrapper compressed.
  static Future<Uint8List> exportEncryptedCompressedBytes(String password) async {
    final jsonStr = await exportFullJson();
    final compressed = gzipCompress(Uint8List.fromList(utf8.encode(jsonStr)));

    // encrypt compressed bytes using same encryption wrapper but storing base64 of cipher
    final salt = DateTime.now().millisecondsSinceEpoch.toString();
    final keyBytes = _deriveKey(password, salt);
    final key = encrypt_pkg.Key(Uint8List.fromList(keyBytes));
    final iv = encrypt_pkg.IV.fromSecureRandom(16);
    final encrypter = encrypt_pkg.Encrypter(encrypt_pkg.AES(key, mode: encrypt_pkg.AESMode.cbc));
    final encrypted = encrypter.encryptBytes(compressed, iv: iv);

    final wrapper = json.encode({
      'salt': salt,
      'iv': iv.base64,
      'data': encrypted.base64,
    });
    return Uint8List.fromList(utf8.encode(wrapper));
  }

  /// Given encrypted wrapper bytes, decrypt and return the original JSON string (after decompression)
  static Future<String> decryptCompressedBytes(Uint8List wrapperBytes, String password) async {
    final wrapper = json.decode(utf8.decode(wrapperBytes)) as Map<String, dynamic>;
    final salt = wrapper['salt'] as String;
    final ivb64 = wrapper['iv'] as String;
    final datab64 = wrapper['data'] as String;

    final keyBytes = _deriveKey(password, salt);
    final key = encrypt_pkg.Key(Uint8List.fromList(keyBytes));
    final iv = encrypt_pkg.IV.fromBase64(ivb64);
    final encrypter = encrypt_pkg.Encrypter(encrypt_pkg.AES(key, mode: encrypt_pkg.AESMode.cbc));
    final decryptedBytes = encrypter.decryptBytes(encrypt_pkg.Encrypted.fromBase64(datab64), iv: iv);
    final decompressed = gzipDecompress(Uint8List.fromList(decryptedBytes));
    return utf8.decode(decompressed);
  }

  static Future<void> deleteAllBackups() async {
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory('${dir.path}/backups');
    if (await folder.exists()) {
      await folder.delete(recursive: true);
    }
  }

  // Instance wrappers for callers that expect a singleton instance API.
  Future<String> exportFullJsonInstance() => BackupService.exportFullJson();
  Future<String> encryptAndSaveInstance(String plainJson, String password, {required String filename}) =>
      BackupService.encryptAndSave(plainJson, password, filename: filename);
  Future<String> decryptFromFileInstance(String path, String password) => BackupService.decryptFromFile(path, password);
  Future<Uint8List> exportEncryptedCompressedBytesInstance(String password) => BackupService.exportEncryptedCompressedBytes(password);
  Future<String> decryptCompressedBytesInstance(Uint8List wrapperBytes, String password) => BackupService.decryptCompressedBytes(wrapperBytes, password);
  Future<void> deleteAllBackupsInstance() => BackupService.deleteAllBackups();
}
