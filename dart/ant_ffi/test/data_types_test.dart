import 'dart:convert';
import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:ant_ffi/ant_ffi.dart';

void main() {
  group('Chunk', () {
    test('create chunk from data', () {
      final data = Uint8List.fromList(utf8.encode('Test chunk data'));
      final chunk = Chunk(data);

      expect(chunk.value(), equals(data));
      expect(chunk.size(), greaterThan(0));

      chunk.dispose();
    });

    test('chunk address is derived from content', () {
      final data = Uint8List.fromList(utf8.encode('Test chunk data'));
      final chunk = Chunk(data);
      final address = chunk.address();

      expect(address.toHex(), isNotEmpty);

      // Same content should produce same address
      final chunk2 = Chunk(data);
      final address2 = chunk2.address();
      expect(address2.toHex(), equals(address.toHex()));

      chunk.dispose();
      chunk2.dispose();
      address.dispose();
      address2.dispose();
    });

    test('different content produces different addresses', () {
      final chunk1 = Chunk(Uint8List.fromList(utf8.encode('Data 1')));
      final chunk2 = Chunk(Uint8List.fromList(utf8.encode('Data 2')));

      final address1 = chunk1.address();
      final address2 = chunk2.address();

      expect(address1.toHex(), isNot(equals(address2.toHex())));

      chunk1.dispose();
      chunk2.dispose();
      address1.dispose();
      address2.dispose();
    });

    test('isTooBig for normal data', () {
      final data = Uint8List.fromList(utf8.encode('Small data'));
      final chunk = Chunk(data);

      expect(chunk.isTooBig(), isFalse);

      chunk.dispose();
    });

    test('chunkMaxSize returns positive value', () {
      final maxSize = chunkMaxSize();
      expect(maxSize, greaterThan(0));
    });

    test('chunkMaxRawSize returns positive value', () {
      final maxRawSize = chunkMaxRawSize();
      expect(maxRawSize, greaterThan(0));
      // Both should be approximately 4MB
      expect(maxRawSize, greaterThan(1024 * 1024));
    });

    test('throws after dispose', () {
      final chunk = Chunk(Uint8List.fromList([1, 2, 3]));
      chunk.dispose();

      expect(() => chunk.value(), throwsStateError);
    });
  });

  group('ChunkAddress', () {
    test('fromHex roundtrip', () {
      final chunk = Chunk(Uint8List.fromList(utf8.encode('Test data')));
      final address = chunk.address();
      final hex = address.toHex();

      final address2 = ChunkAddress.fromHex(hex);
      expect(address2.toHex(), equals(hex));

      chunk.dispose();
      address.dispose();
      address2.dispose();
    });

    test('toBytes and fromBytes roundtrip', () {
      final chunk = Chunk(Uint8List.fromList(utf8.encode('Test data')));
      final address = chunk.address();
      final bytes = address.toBytes();

      final address2 = ChunkAddress.fromBytes(bytes);
      expect(address2.toHex(), equals(address.toHex()));

      chunk.dispose();
      address.dispose();
      address2.dispose();
    });

    test('fromContent computes address', () {
      final data = Uint8List.fromList(utf8.encode('Test data'));
      final address = ChunkAddress.fromContent(data);

      // Should match the address of a chunk with same content
      final chunk = Chunk(data);
      final chunkAddress = chunk.address();

      expect(address.toHex(), equals(chunkAddress.toHex()));

      address.dispose();
      chunk.dispose();
      chunkAddress.dispose();
    });

    test('throws after dispose', () {
      final address = ChunkAddress.fromContent(Uint8List.fromList([1, 2, 3]));
      address.dispose();

      expect(() => address.toHex(), throwsStateError);
    });
  });
}
