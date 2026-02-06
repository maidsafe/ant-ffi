import 'dart:convert';
import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:ant_ffi/ant_ffi.dart';

void main() {
  group('PointerAddress', () {
    test('fromPublicKey creates valid address', () {
      final secretKey = SecretKey.random();
      final publicKey = secretKey.publicKey();

      final address = PointerAddress.fromPublicKey(publicKey);

      expect(address.toHex(), isNotEmpty);

      address.dispose();
      publicKey.dispose();
      secretKey.dispose();
    });

    test('fromHex roundtrip', () {
      final secretKey = SecretKey.random();
      final publicKey = secretKey.publicKey();
      final address1 = PointerAddress.fromPublicKey(publicKey);
      final hex = address1.toHex();

      final address2 = PointerAddress.fromHex(hex);
      expect(address2.toHex(), equals(hex));

      address2.dispose();
      address1.dispose();
      publicKey.dispose();
      secretKey.dispose();
    });

    test('owner returns correct public key', () {
      final secretKey = SecretKey.random();
      final publicKey = secretKey.publicKey();
      final address = PointerAddress.fromPublicKey(publicKey);

      final owner = address.owner();
      expect(owner.toHex(), equals(publicKey.toHex()));

      owner.dispose();
      address.dispose();
      publicKey.dispose();
      secretKey.dispose();
    });

    test('throws after dispose', () {
      final secretKey = SecretKey.random();
      final address = PointerAddress.fromPublicKey(secretKey.publicKey());
      address.dispose();
      secretKey.dispose();

      expect(() => address.toHex(), throwsStateError);
    });
  });

  group('PointerTarget', () {
    test('chunk creates valid target', () {
      final chunkAddress = ChunkAddress.fromContent(Uint8List.fromList(utf8.encode('test content')));
      final target = PointerTarget.chunk(chunkAddress);

      expect(target.toHex(), isNotEmpty);

      target.dispose();
      chunkAddress.dispose();
    });

    test('pointer creates valid target', () {
      final secretKey = SecretKey.random();
      final pointerAddress = PointerAddress.fromPublicKey(secretKey.publicKey());

      final target = PointerTarget.pointer(pointerAddress);

      expect(target.toHex(), isNotEmpty);

      target.dispose();
      pointerAddress.dispose();
      secretKey.dispose();
    });

    test('scratchpad creates valid target', () {
      final secretKey = SecretKey.random();
      final scratchpadAddress = ScratchpadAddress.fromPublicKey(secretKey.publicKey());

      final target = PointerTarget.scratchpad(scratchpadAddress);

      expect(target.toHex(), isNotEmpty);

      target.dispose();
      scratchpadAddress.dispose();
      secretKey.dispose();
    });

    test('graphEntry creates valid target', () {
      final secretKey = SecretKey.random();
      final graphEntryAddress = GraphEntryAddress.fromOwner(secretKey.publicKey());

      final target = PointerTarget.graphEntry(graphEntryAddress);

      expect(target.toHex(), isNotEmpty);

      target.dispose();
      graphEntryAddress.dispose();
      secretKey.dispose();
    });

    test('throws after dispose', () {
      final chunkAddress = ChunkAddress.fromContent(Uint8List.fromList(utf8.encode('test')));
      final target = PointerTarget.chunk(chunkAddress);
      target.dispose();
      chunkAddress.dispose();

      expect(() => target.toHex(), throwsStateError);
    });
  });

  group('NetworkPointer', () {
    test('create with counter 0', () {
      final secretKey = SecretKey.random();
      final chunkAddress = ChunkAddress.fromContent(Uint8List.fromList(utf8.encode('target content')));
      final target = PointerTarget.chunk(chunkAddress);

      final pointer = NetworkPointer.create(secretKey, 0, target);

      expect(pointer.counter(), equals(0));

      pointer.dispose();
      target.dispose();
      chunkAddress.dispose();
      secretKey.dispose();
    });

    test('counter returns correct value', () {
      final secretKey = SecretKey.random();
      final chunkAddress = ChunkAddress.fromContent(Uint8List.fromList(utf8.encode('test')));
      final target = PointerTarget.chunk(chunkAddress);

      final pointer = NetworkPointer.create(secretKey, 42, target);

      expect(pointer.counter(), equals(42));

      pointer.dispose();
      target.dispose();
      chunkAddress.dispose();
      secretKey.dispose();
    });

    test('address returns valid PointerAddress', () {
      final secretKey = SecretKey.random();
      final chunkAddress = ChunkAddress.fromContent(Uint8List.fromList(utf8.encode('test')));
      final target = PointerTarget.chunk(chunkAddress);
      final pointer = NetworkPointer.create(secretKey, 0, target);

      final address = pointer.address();

      expect(address.toHex(), isNotEmpty);

      address.dispose();
      pointer.dispose();
      target.dispose();
      chunkAddress.dispose();
      secretKey.dispose();
    });

    test('target returns valid PointerTarget', () {
      final secretKey = SecretKey.random();
      final chunkAddress = ChunkAddress.fromContent(Uint8List.fromList(utf8.encode('test')));
      final target = PointerTarget.chunk(chunkAddress);
      final pointer = NetworkPointer.create(secretKey, 0, target);

      final retrievedTarget = pointer.target();

      expect(retrievedTarget.toHex(), isNotEmpty);

      retrievedTarget.dispose();
      pointer.dispose();
      target.dispose();
      chunkAddress.dispose();
      secretKey.dispose();
    });

    test('throws after dispose', () {
      final secretKey = SecretKey.random();
      final chunkAddress = ChunkAddress.fromContent(Uint8List.fromList(utf8.encode('test')));
      final target = PointerTarget.chunk(chunkAddress);
      final pointer = NetworkPointer.create(secretKey, 0, target);
      pointer.dispose();
      target.dispose();
      chunkAddress.dispose();
      secretKey.dispose();

      expect(() => pointer.counter(), throwsStateError);
    });
  });

  group('ScratchpadAddress', () {
    test('fromPublicKey creates valid address', () {
      final secretKey = SecretKey.random();
      final publicKey = secretKey.publicKey();

      final address = ScratchpadAddress.fromPublicKey(publicKey);

      expect(address.toHex(), isNotEmpty);

      address.dispose();
      publicKey.dispose();
      secretKey.dispose();
    });

    test('fromHex roundtrip', () {
      final secretKey = SecretKey.random();
      final publicKey = secretKey.publicKey();
      final address1 = ScratchpadAddress.fromPublicKey(publicKey);
      final hex = address1.toHex();

      final address2 = ScratchpadAddress.fromHex(hex);
      expect(address2.toHex(), equals(hex));

      address2.dispose();
      address1.dispose();
      publicKey.dispose();
      secretKey.dispose();
    });

    test('owner returns correct public key', () {
      final secretKey = SecretKey.random();
      final publicKey = secretKey.publicKey();
      final address = ScratchpadAddress.fromPublicKey(publicKey);

      final owner = address.owner();
      expect(owner.toHex(), equals(publicKey.toHex()));

      owner.dispose();
      address.dispose();
      publicKey.dispose();
      secretKey.dispose();
    });

    test('throws after dispose', () {
      final secretKey = SecretKey.random();
      final address = ScratchpadAddress.fromPublicKey(secretKey.publicKey());
      address.dispose();
      secretKey.dispose();

      expect(() => address.toHex(), throwsStateError);
    });
  });

  group('Scratchpad', () {
    test('create returns valid scratchpad', () {
      final secretKey = SecretKey.random();
      final data = Uint8List.fromList(utf8.encode('Hello, Scratchpad!'));

      final scratchpad = Scratchpad.create(secretKey, 1, data, 0);

      expect(scratchpad.counter(), equals(0));
      expect(scratchpad.dataEncoding(), equals(1));

      scratchpad.dispose();
      secretKey.dispose();
    });

    test('counter returns correct value', () {
      final secretKey = SecretKey.random();
      final data = Uint8List.fromList(utf8.encode('test'));

      final scratchpad = Scratchpad.create(secretKey, 1, data, 42);

      expect(scratchpad.counter(), equals(42));

      scratchpad.dispose();
      secretKey.dispose();
    });

    test('dataEncoding returns correct value', () {
      final secretKey = SecretKey.random();
      final data = Uint8List.fromList(utf8.encode('test'));

      final scratchpad = Scratchpad.create(secretKey, 99, data, 0);

      expect(scratchpad.dataEncoding(), equals(99));

      scratchpad.dispose();
      secretKey.dispose();
    });

    test('address returns valid ScratchpadAddress', () {
      final secretKey = SecretKey.random();
      final data = Uint8List.fromList(utf8.encode('test'));
      final scratchpad = Scratchpad.create(secretKey, 1, data, 0);

      final address = scratchpad.address();

      expect(address.toHex(), isNotEmpty);

      address.dispose();
      scratchpad.dispose();
      secretKey.dispose();
    });

    test('owner returns correct public key', () {
      final secretKey = SecretKey.random();
      final publicKey = secretKey.publicKey();
      final data = Uint8List.fromList(utf8.encode('test'));
      final scratchpad = Scratchpad.create(secretKey, 1, data, 0);

      final owner = scratchpad.owner();

      expect(owner.toHex(), equals(publicKey.toHex()));

      owner.dispose();
      publicKey.dispose();
      scratchpad.dispose();
      secretKey.dispose();
    });

    test('encryptedData returns non-empty bytes', () {
      final secretKey = SecretKey.random();
      final data = Uint8List.fromList(utf8.encode('Secret data'));
      final scratchpad = Scratchpad.create(secretKey, 1, data, 0);

      final encrypted = scratchpad.encryptedData();

      expect(encrypted, isNotEmpty);

      scratchpad.dispose();
      secretKey.dispose();
    });

    test('decryptData roundtrip', () {
      final secretKey = SecretKey.random();
      final originalData = Uint8List.fromList(utf8.encode('Hello, encrypted world!'));
      final scratchpad = Scratchpad.create(secretKey, 1, originalData, 0);

      final decrypted = scratchpad.decryptData(secretKey);

      expect(decrypted, equals(originalData));

      scratchpad.dispose();
      secretKey.dispose();
    });

    test('throws after dispose', () {
      final secretKey = SecretKey.random();
      final data = Uint8List.fromList(utf8.encode('test'));
      final scratchpad = Scratchpad.create(secretKey, 1, data, 0);
      scratchpad.dispose();
      secretKey.dispose();

      expect(() => scratchpad.counter(), throwsStateError);
    });
  });

  group('RegisterAddress', () {
    test('fromOwner creates valid address', () {
      final secretKey = SecretKey.random();
      final publicKey = secretKey.publicKey();

      final address = RegisterAddress.fromOwner(publicKey);

      expect(address.toHex(), isNotEmpty);

      address.dispose();
      publicKey.dispose();
      secretKey.dispose();
    });

    test('fromHex roundtrip', () {
      final secretKey = SecretKey.random();
      final publicKey = secretKey.publicKey();
      final address1 = RegisterAddress.fromOwner(publicKey);
      final hex = address1.toHex();

      final address2 = RegisterAddress.fromHex(hex);
      expect(address2.toHex(), equals(hex));

      address2.dispose();
      address1.dispose();
      publicKey.dispose();
      secretKey.dispose();
    });

    test('owner returns correct public key', () {
      final secretKey = SecretKey.random();
      final publicKey = secretKey.publicKey();
      final address = RegisterAddress.fromOwner(publicKey);

      final owner = address.owner();
      expect(owner.toHex(), equals(publicKey.toHex()));

      owner.dispose();
      address.dispose();
      publicKey.dispose();
      secretKey.dispose();
    });

    test('throws after dispose', () {
      final secretKey = SecretKey.random();
      final address = RegisterAddress.fromOwner(secretKey.publicKey());
      address.dispose();
      secretKey.dispose();

      expect(() => address.toHex(), throwsStateError);
    });
  });

  group('ChunkAddress', () {
    test('fromContent creates valid address', () {
      final data = Uint8List.fromList(utf8.encode('test content'));

      final address = ChunkAddress.fromContent(data);

      expect(address.toHex(), isNotEmpty);

      address.dispose();
    });

    test('fromHex roundtrip', () {
      final data = Uint8List.fromList(utf8.encode('test content'));
      final address1 = ChunkAddress.fromContent(data);
      final hex = address1.toHex();

      final address2 = ChunkAddress.fromHex(hex);
      expect(address2.toHex(), equals(hex));

      address2.dispose();
      address1.dispose();
    });

    test('same content produces same address', () {
      final data = Uint8List.fromList(utf8.encode('same content'));

      final address1 = ChunkAddress.fromContent(data);
      final address2 = ChunkAddress.fromContent(data);

      expect(address1.toHex(), equals(address2.toHex()));

      address1.dispose();
      address2.dispose();
    });

    test('different content produces different address', () {
      final data1 = Uint8List.fromList(utf8.encode('content 1'));
      final data2 = Uint8List.fromList(utf8.encode('content 2'));

      final address1 = ChunkAddress.fromContent(data1);
      final address2 = ChunkAddress.fromContent(data2);

      expect(address1.toHex(), isNot(equals(address2.toHex())));

      address1.dispose();
      address2.dispose();
    });

    test('toBytes returns valid bytes', () {
      final data = Uint8List.fromList(utf8.encode('test content'));
      final address = ChunkAddress.fromContent(data);

      final bytes = address.toBytes();

      expect(bytes, isNotEmpty);

      address.dispose();
    });

    test('throws after dispose', () {
      final data = Uint8List.fromList(utf8.encode('test'));
      final address = ChunkAddress.fromContent(data);
      address.dispose();

      expect(() => address.toHex(), throwsStateError);
    });
  });
}
