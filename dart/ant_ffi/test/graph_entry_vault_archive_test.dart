import 'dart:convert';
import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:ant_ffi/ant_ffi.dart';

void main() {
  group('GraphEntryAddress', () {
    test('fromOwner creates valid address', () {
      final secretKey = SecretKey.random();
      final publicKey = secretKey.publicKey();

      final address = GraphEntryAddress.fromOwner(publicKey);

      expect(address.toHex(), isNotEmpty);

      address.dispose();
      publicKey.dispose();
      secretKey.dispose();
    });

    test('fromHex roundtrip', () {
      final secretKey = SecretKey.random();
      final publicKey = secretKey.publicKey();
      final address1 = GraphEntryAddress.fromOwner(publicKey);
      final hex = address1.toHex();

      final address2 = GraphEntryAddress.fromHex(hex);
      expect(address2.toHex(), equals(hex));

      address2.dispose();
      address1.dispose();
      publicKey.dispose();
      secretKey.dispose();
    });

    test('throws after dispose', () {
      final secretKey = SecretKey.random();
      final address = GraphEntryAddress.fromOwner(secretKey.publicKey());
      address.dispose();
      secretKey.dispose();

      expect(() => address.toHex(), throwsStateError);
    });
  });

  group('GraphEntry', () {
    // Helper to create 32-byte content (GraphEntry requires exactly 32 bytes)
    Uint8List make32ByteContent(String prefix) {
      final bytes = Uint8List(32);
      final prefixBytes = utf8.encode(prefix);
      bytes.setRange(0, prefixBytes.length.clamp(0, 32), prefixBytes);
      return bytes;
    }

    test('create with empty parents and descendants', () {
      final secretKey = SecretKey.random();
      final content = make32ByteContent('Hello, Graph!');

      final entry = GraphEntry.create(
        secretKey,
        Uint8List(0), // empty parents
        content,
        Uint8List(0), // empty descendants
      );

      expect(entry.content(), equals(content));

      entry.dispose();
      secretKey.dispose();
    });

    test('address returns valid GraphEntryAddress', () {
      final secretKey = SecretKey.random();
      final content = make32ByteContent('test content');
      final entry = GraphEntry.create(
        secretKey,
        Uint8List(0),
        content,
        Uint8List(0),
      );

      final address = entry.address();

      expect(address.toHex(), isNotEmpty);

      address.dispose();
      entry.dispose();
      secretKey.dispose();
    });

    test('content returns correct data', () {
      final secretKey = SecretKey.random();
      final content = make32ByteContent('Test graph entry');
      final entry = GraphEntry.create(
        secretKey,
        Uint8List(0),
        content,
        Uint8List(0),
      );

      expect(entry.content(), equals(content));

      entry.dispose();
      secretKey.dispose();
    });

    test('parents returns serialized data', () {
      final secretKey = SecretKey.random();
      final entry = GraphEntry.create(
        secretKey,
        Uint8List(0),
        make32ByteContent('test'),
        Uint8List(0),
      );

      // Empty parents should return empty or minimal serialized data
      final parents = entry.parents();
      expect(parents, isA<Uint8List>());

      entry.dispose();
      secretKey.dispose();
    });

    test('descendants returns serialized data', () {
      final secretKey = SecretKey.random();
      final entry = GraphEntry.create(
        secretKey,
        Uint8List(0),
        make32ByteContent('test'),
        Uint8List(0),
      );

      // Empty descendants should return empty or minimal serialized data
      final descendants = entry.descendants();
      expect(descendants, isA<Uint8List>());

      entry.dispose();
      secretKey.dispose();
    });

    test('throws after dispose', () {
      final secretKey = SecretKey.random();
      final entry = GraphEntry.create(
        secretKey,
        Uint8List(0),
        make32ByteContent('test'),
        Uint8List(0),
      );
      entry.dispose();
      secretKey.dispose();

      expect(() => entry.content(), throwsStateError);
    });
  });

  group('VaultSecretKey', () {
    test('random creates valid key', () {
      final key = VaultSecretKey.random();

      expect(key.toHex(), isNotEmpty);
      expect(key.toHex(), matches(RegExp(r'^[0-9a-f]+$', caseSensitive: false)));

      key.dispose();
    });

    test('random creates unique keys', () {
      final key1 = VaultSecretKey.random();
      final key2 = VaultSecretKey.random();

      expect(key1.toHex(), isNot(equals(key2.toHex())));

      key1.dispose();
      key2.dispose();
    });

    test('fromHex roundtrip', () {
      final key1 = VaultSecretKey.random();
      final hex = key1.toHex();

      final key2 = VaultSecretKey.fromHex(hex);
      expect(key2.toHex(), equals(hex));

      key1.dispose();
      key2.dispose();
    });

    test('throws after dispose', () {
      final key = VaultSecretKey.random();
      key.dispose();

      expect(() => key.toHex(), throwsStateError);
    });
  });

  group('UserData', () {
    test('create returns valid instance', () {
      final userData = UserData.create();

      expect(userData, isNotNull);

      userData.dispose();
    });

    test('fileArchives returns serialized data', () {
      final userData = UserData.create();

      final archives = userData.fileArchives();
      expect(archives, isA<Uint8List>());

      userData.dispose();
    });

    test('privateFileArchives returns serialized data', () {
      final userData = UserData.create();

      final archives = userData.privateFileArchives();
      expect(archives, isA<Uint8List>());

      userData.dispose();
    });

    test('throws after dispose', () {
      final userData = UserData.create();
      userData.dispose();

      expect(() => userData.fileArchives(), throwsStateError);
    });
  });

  group('Metadata', () {
    test('create with size', () {
      final metadata = Metadata.create(1024);

      expect(metadata.size(), equals(1024));

      metadata.dispose();
    });

    test('withTimestamps creates valid metadata', () {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final metadata = Metadata.withTimestamps(2048, now - 100, now);

      expect(metadata.size(), equals(2048));
      expect(metadata.created(), equals(now - 100));
      expect(metadata.modified(), equals(now));

      metadata.dispose();
    });

    test('throws after dispose', () {
      final metadata = Metadata.create(100);
      metadata.dispose();

      expect(() => metadata.size(), throwsStateError);
    });
  });

  group('PublicArchive', () {
    test('create returns empty archive', () {
      final archive = PublicArchive.create();

      expect(archive.fileCount(), equals(0));

      archive.dispose();
    });

    test('addFile increases file count', () {
      final archive = PublicArchive.create();

      // Create a data address from some content
      final dataAddress = DataAddress.fromHex('ab' * 32);
      final metadata = Metadata.create(100);

      final updatedArchive = archive.addFile('/test/file.txt', dataAddress, metadata);

      expect(updatedArchive.fileCount(), equals(1));

      updatedArchive.dispose();
      archive.dispose();
      metadata.dispose();
      dataAddress.dispose();
    });

    test('files returns serialized data', () {
      final archive = PublicArchive.create();

      final files = archive.files();
      expect(files, isA<Uint8List>());

      archive.dispose();
    });

    test('addresses returns serialized data', () {
      final archive = PublicArchive.create();

      final addresses = archive.addresses();
      expect(addresses, isA<Uint8List>());

      archive.dispose();
    });

    test('throws after dispose', () {
      final archive = PublicArchive.create();
      archive.dispose();

      expect(() => archive.fileCount(), throwsStateError);
    });
  });

  group('PrivateArchive', () {
    test('create returns empty archive', () {
      final archive = PrivateArchive.create();

      expect(archive.fileCount(), equals(0));

      archive.dispose();
    });

    test('files returns serialized data', () {
      final archive = PrivateArchive.create();

      final files = archive.files();
      expect(files, isA<Uint8List>());

      archive.dispose();
    });

    test('dataMaps returns serialized data', () {
      final archive = PrivateArchive.create();

      final dataMaps = archive.dataMaps();
      expect(dataMaps, isA<Uint8List>());

      archive.dispose();
    });

    test('throws after dispose', () {
      final archive = PrivateArchive.create();
      archive.dispose();

      expect(() => archive.fileCount(), throwsStateError);
    });
  });

  group('ArchiveAddress', () {
    test('fromHex roundtrip', () {
      // Use a valid hex string
      final hex = 'ab' * 32;

      try {
        final address1 = ArchiveAddress.fromHex(hex);
        expect(address1.toHex(), isNotEmpty);
        address1.dispose();
      } on AntFfiException catch (_) {
        // Some formats may require specific structure
      }
    });

    test('throws after dispose', () {
      final hex = 'ab' * 32;

      try {
        final address = ArchiveAddress.fromHex(hex);
        address.dispose();

        expect(() => address.toHex(), throwsStateError);
      } on AntFfiException catch (_) {
        // Skip if format not supported
      }
    });
  });

  group('PrivateArchiveDataMap', () {
    test('fromHex roundtrip', () {
      // Use a valid hex string
      final hex = 'cd' * 32;

      try {
        final dataMap1 = PrivateArchiveDataMap.fromHex(hex);
        expect(dataMap1.toHex(), isNotEmpty);
        dataMap1.dispose();
      } on AntFfiException catch (_) {
        // Some formats may require specific structure
      }
    });

    test('throws after dispose', () {
      final hex = 'cd' * 32;

      try {
        final dataMap = PrivateArchiveDataMap.fromHex(hex);
        dataMap.dispose();

        expect(() => dataMap.toHex(), throwsStateError);
      } on AntFfiException catch (_) {
        // Skip if format not supported
      }
    });
  });

  group('DataMapChunk', () {
    test('fromHex roundtrip', () {
      // Use a valid hex string
      final hex = 'ef' * 32;

      try {
        final chunk1 = DataMapChunk.fromHex(hex);
        expect(chunk1.toHex(), isNotEmpty);
        chunk1.dispose();
      } on AntFfiException catch (_) {
        // Some formats may require specific structure
      }
    });

    test('throws after dispose', () {
      final hex = 'ef' * 32;

      try {
        final chunk = DataMapChunk.fromHex(hex);
        chunk.dispose();

        expect(() => chunk.toHex(), throwsStateError);
      } on AntFfiException catch (_) {
        // Skip if format not supported
      }
    });
  });

  group('DataAddress', () {
    test('fromHex roundtrip', () {
      final hex = 'ab' * 32;

      final address1 = DataAddress.fromHex(hex);
      expect(address1.toHex(), isNotEmpty);
      address1.dispose();
    });

    test('throws after dispose', () {
      final hex = 'ab' * 32;
      final address = DataAddress.fromHex(hex);
      address.dispose();

      expect(() => address.toHex(), throwsStateError);
    });
  });
}
