import 'dart:convert';
import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:ant_ffi/ant_ffi.dart';

/// Default Anvil/Hardhat test private key #0 (pre-funded on local testnets)
const defaultTestKey =
    '0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80';

/// End-to-end integration tests for client operations.
///
/// These tests require a local Autonomi testnet running.
/// Run with: dart test --tags integration
///
/// To start a local testnet:
/// cd C:\tools\ant && setup-testnet.bat
@Tags(['integration'])
void main() {
  late Client client;
  late Wallet wallet;
  late Network network;

  setUpAll(() async {
    try {
      client = await Client.initLocal();
      network = Network.local();
      wallet = Wallet.fromPrivateKey(network, defaultTestKey);
    } catch (e) {
      fail('Local testnet not available: $e');
    }
  });

  tearDownAll(() {
    wallet.dispose();
    network.dispose();
    client.dispose();
  });

  group('Public Data Operations', () {
    test('dataPutPublic and dataGetPublic roundtrip', () async {
      final data = 'Hello, Autonomi Network! ${DateTime.now().millisecondsSinceEpoch}';

      final result = await client.dataPutPublic(data, wallet);

      expect(result.address.toHex(), isNotEmpty);
      expect(result.cost, isNotEmpty);

      // Retrieve the data
      final retrieved = await client.dataGetPublic(result.address.toHex());
      expect(retrieved, equals(data));

      result.address.dispose();
    });

    test('dataCost returns valid cost estimate', () async {
      final data = Uint8List.fromList(List.filled(1000, 0x58)); // 1KB of 'X'

      final cost = await client.dataCost(data);

      expect(cost, isNotEmpty);
    });
  });

  group('Private Data Operations', () {
    test('dataPut and dataGet roundtrip', () async {
      final data = Uint8List.fromList(
        utf8.encode('Secret data: ${DateTime.now().millisecondsSinceEpoch}'),
      );

      final result = await client.dataPut(data, wallet);

      expect(result.dataMap, isNotNull);
      expect(result.cost, isNotEmpty);

      // Retrieve the private data
      final retrieved = await client.dataGet(result.dataMap);
      expect(retrieved, equals(data));

      result.dataMap.dispose();
    });
  });

  group('Chunk Operations', () {
    test('chunkPut and chunkGet roundtrip', () async {
      final data = Uint8List.fromList(
        utf8.encode('Chunk content: ${DateTime.now().millisecondsSinceEpoch}'),
      );

      final result = await client.chunkPut(data, wallet);

      expect(result.address.toHex(), isNotEmpty);
      expect(result.cost, isNotEmpty);

      // Retrieve the chunk
      final chunk = await client.chunkGet(result.address);
      expect(chunk.value(), equals(data));

      chunk.dispose();
      result.address.dispose();
    });
  });

  group('Pointer Operations', () {
    test('pointerPut and pointerGet roundtrip', () async {
      final ownerKey = SecretKey.random();

      // Create a chunk address to point to
      final chunkAddress = ChunkAddress.fromContent(
        Uint8List.fromList(utf8.encode('target content')),
      );
      final target = PointerTarget.chunk(chunkAddress);

      // Create and store the pointer
      final pointer = NetworkPointer.create(ownerKey, 0, target);
      await client.pointerPut(pointer, wallet);

      // Retrieve the pointer
      final address = pointer.address();
      final retrieved = await client.pointerGet(address);

      expect(retrieved.counter(), equals(0));

      retrieved.dispose();
      address.dispose();
      pointer.dispose();
      target.dispose();
      chunkAddress.dispose();
      ownerKey.dispose();
    });

    test('pointer update with higher counter', () async {
      final ownerKey = SecretKey.random();

      // Create initial pointer
      final target1 = PointerTarget.chunk(
        ChunkAddress.fromContent(Uint8List.fromList(utf8.encode('target1'))),
      );
      final pointer1 = NetworkPointer.create(ownerKey, 0, target1);
      await client.pointerPut(pointer1, wallet);

      // Update the pointer with higher counter
      final target2 = PointerTarget.chunk(
        ChunkAddress.fromContent(Uint8List.fromList(utf8.encode('target2'))),
      );
      final pointer2 = NetworkPointer.create(ownerKey, 1, target2);
      await client.pointerPut(pointer2, wallet);

      // Retrieve and verify the updated pointer
      final address = pointer2.address();
      final retrieved = await client.pointerGet(address);

      expect(retrieved.counter(), equals(1));

      retrieved.dispose();
      address.dispose();
      pointer2.dispose();
      pointer1.dispose();
      target2.dispose();
      target1.dispose();
      ownerKey.dispose();
    });
  });

  group('Scratchpad Operations', () {
    test('scratchpadPut and scratchpadGet roundtrip', () async {
      final ownerKey = SecretKey.random();
      final data = Uint8List.fromList(
        utf8.encode('Scratchpad content: ${DateTime.now().millisecondsSinceEpoch}'),
      );

      // Create and store the scratchpad
      final scratchpad = Scratchpad.create(ownerKey, 1, data, 0);
      await client.scratchpadPut(scratchpad, wallet);

      // Retrieve the scratchpad
      final address = scratchpad.address();
      final retrieved = await client.scratchpadGet(address);

      expect(retrieved.counter(), equals(0));
      expect(retrieved.dataEncoding(), equals(1));

      // Decrypt and verify data
      final decrypted = retrieved.decryptData(ownerKey);
      expect(decrypted, equals(data));

      retrieved.dispose();
      address.dispose();
      scratchpad.dispose();
      ownerKey.dispose();
    });

    test('scratchpad update with higher counter', () async {
      final ownerKey = SecretKey.random();

      // Create initial scratchpad
      final scratchpad1 = Scratchpad.create(
        ownerKey,
        1,
        Uint8List.fromList(utf8.encode('initial data')),
        0,
      );
      await client.scratchpadPut(scratchpad1, wallet);

      // Update the scratchpad with higher counter
      final updatedData = Uint8List.fromList(utf8.encode('updated data'));
      final scratchpad2 = Scratchpad.create(ownerKey, 1, updatedData, 1);
      await client.scratchpadPut(scratchpad2, wallet);

      // Retrieve and verify the updated scratchpad
      final address = scratchpad2.address();
      final retrieved = await client.scratchpadGet(address);

      expect(retrieved.counter(), equals(1));
      expect(retrieved.decryptData(ownerKey), equals(updatedData));

      retrieved.dispose();
      address.dispose();
      scratchpad2.dispose();
      scratchpad1.dispose();
      ownerKey.dispose();
    });
  });

  group('Register Operations', () {
    test('registerCreate and registerGet roundtrip', () async {
      final ownerKey = SecretKey.random();
      final value = Uint8List.fromList(
        utf8.encode('Register value: ${DateTime.now().millisecondsSinceEpoch}'),
      );

      // Create the register
      final address = await client.registerCreate(value, ownerKey, wallet);

      expect(address.toHex(), isNotEmpty);

      // Retrieve the register value
      final retrieved = await client.registerGet(address);
      expect(retrieved, equals(value));

      address.dispose();
      ownerKey.dispose();
    });

    test('registerUpdate updates register value', () async {
      final ownerKey = SecretKey.random();
      final initialValue = Uint8List.fromList(utf8.encode('initial value'));

      // Create the register
      final address = await client.registerCreate(initialValue, ownerKey, wallet);

      // Update the register
      final updatedValue = Uint8List.fromList(utf8.encode('updated value'));
      await client.registerUpdate(updatedValue, ownerKey, wallet);

      // Retrieve and verify the updated value
      final retrieved = await client.registerGet(address);
      expect(retrieved, equals(updatedValue));

      address.dispose();
      ownerKey.dispose();
    });
  });

  group('Graph Entry Operations', () {
    test('graphEntryPut and graphEntryGet roundtrip', () async {
      final ownerKey = SecretKey.random();
      final content = Uint8List.fromList(
        utf8.encode('Graph entry content: ${DateTime.now().millisecondsSinceEpoch}'),
      );

      // Create and store the graph entry
      final entry = GraphEntry.create(
        ownerKey,
        Uint8List(0), // empty parents
        content,
        Uint8List(0), // empty descendants
      );
      await client.graphEntryPut(entry, wallet);

      // Retrieve the graph entry
      final address = entry.address();
      final retrieved = await client.graphEntryGet(address);

      expect(retrieved.content(), equals(content));

      retrieved.dispose();
      address.dispose();
      entry.dispose();
      ownerKey.dispose();
    });
  });

  group('Vault Operations', () {
    test('vaultPut and vaultGet user data roundtrip', () async {
      final vaultKey = VaultSecretKey.random();
      final userData = UserData.create();

      // Store user data to the vault
      await client.vaultPut(vaultKey, userData, wallet);

      // Retrieve user data from the vault
      final retrieved = await client.vaultGet(vaultKey);

      expect(retrieved, isNotNull);

      retrieved.dispose();
      userData.dispose();
      vaultKey.dispose();
    });
  });

  group('Archive Operations', () {
    test('archivePutPublic and archiveGetPublic roundtrip', () async {
      // Create an archive with a file
      var archive = PublicArchive.create();

      // Upload some data first to get an address
      final result = await client.dataPutPublic('file content', wallet);

      // Add the file to the archive
      final metadata = Metadata.create(12);
      archive = archive.addFile('/test/file.txt', result.address, metadata);

      expect(archive.fileCount(), equals(1));

      // Store the archive
      final address = await client.archivePutPublic(archive, wallet);

      expect(address.toHex(), isNotEmpty);

      // Retrieve the archive
      final retrieved = await client.archiveGetPublic(address);

      expect(retrieved.fileCount(), equals(1));

      retrieved.dispose();
      address.dispose();
      archive.dispose();
      metadata.dispose();
      result.address.dispose();
    });
  });

  group('Error Handling', () {
    test('get non-existent pointer throws', () async {
      final ownerKey = SecretKey.random();
      final address = PointerAddress.fromPublicKey(ownerKey.publicKey());

      expect(
        () async => await client.pointerGet(address),
        throwsA(isA<AntFfiException>()),
      );

      address.dispose();
      ownerKey.dispose();
    });

    test('get non-existent scratchpad throws', () async {
      final ownerKey = SecretKey.random();
      final address = ScratchpadAddress.fromPublicKey(ownerKey.publicKey());

      expect(
        () async => await client.scratchpadGet(address),
        throwsA(isA<AntFfiException>()),
      );

      address.dispose();
      ownerKey.dispose();
    });

    test('get non-existent register throws', () async {
      final ownerKey = SecretKey.random();
      final address = RegisterAddress.fromOwner(ownerKey.publicKey());

      expect(
        () async => await client.registerGet(address),
        throwsA(isA<AntFfiException>()),
      );

      address.dispose();
      ownerKey.dispose();
    });

    test('get non-existent graph entry throws', () async {
      final ownerKey = SecretKey.random();
      final address = GraphEntryAddress.fromOwner(ownerKey.publicKey());

      expect(
        () async => await client.graphEntryGet(address),
        throwsA(isA<AntFfiException>()),
      );

      address.dispose();
      ownerKey.dispose();
    });
  });
}
