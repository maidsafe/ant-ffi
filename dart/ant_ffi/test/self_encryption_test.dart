import 'dart:convert';
import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:ant_ffi/ant_ffi.dart';

void main() {
  group('SelfEncryption', () {
    test('encrypt and decrypt roundtrip', () {
      final original = 'Hello, Autonomi!';
      final data = Uint8List.fromList(utf8.encode(original));

      final encrypted = encrypt(data);
      expect(encrypted, isNotEmpty);
      expect(encrypted, isNot(equals(data)));

      final decrypted = decrypt(encrypted);
      final result = utf8.decode(decrypted);

      expect(result, equals(original));
    });

    test('encrypt produces consistent output for same input', () {
      final data = Uint8List.fromList(utf8.encode('Test data'));

      final encrypted1 = encrypt(data);
      final encrypted2 = encrypt(data);

      // Self-encryption is deterministic, so same input = same output
      expect(encrypted1, equals(encrypted2));
    });

    test('encryptString and decryptToString roundtrip', () {
      final original = 'Test string with unicode: \u{1F600}';

      final encrypted = encryptString(original);
      expect(encrypted, isNotEmpty);

      final decrypted = decryptToString(encrypted);
      expect(decrypted, equals(original));
    });

    test('rejects data smaller than 3 bytes', () {
      // Self-encryption requires at least 3 bytes
      final data = Uint8List(0);
      expect(() => encrypt(data), throwsA(isA<AntFfiException>()));

      final smallData = Uint8List.fromList([1, 2]);
      expect(() => encrypt(smallData), throwsA(isA<AntFfiException>()));
    });

    test('handles large data', () {
      // Create 1MB of random-ish data
      final data = Uint8List(1024 * 1024);
      for (var i = 0; i < data.length; i++) {
        data[i] = i % 256;
      }

      final encrypted = encrypt(data);
      final decrypted = decrypt(encrypted);

      expect(decrypted, equals(data));
    });
  });
}
