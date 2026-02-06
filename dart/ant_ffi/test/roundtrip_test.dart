/// Round-trip integration test for Dart FFI bindings.
///
/// This test:
/// 1. Initializes a client connected to local network
/// 2. Creates a wallet from EVM private key
/// 3. Generates random test data
/// 4. Uploads data to the network
/// 5. Downloads data from the network
/// 6. Verifies the downloaded data matches the original
///
/// Requirements:
/// - Local Autonomi network running (antctl local status)
/// - Local EVM testnet running (evm-testnet)
///
/// Run with: dart test test/roundtrip_test.dart
/// Note: This test is excluded from normal test runs and must be run manually.
@Tags(['e2e', 'integration'])
library;

import 'dart:io';
import 'dart:math';
import 'package:test/test.dart';
import 'package:ant_ffi/ant_ffi.dart';

/// Default Anvil/Hardhat test private key #0 (pre-funded on local testnets)
const defaultTestKey =
    '0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80';

/// Gets the EVM private key from environment or uses default test key.
String getEvmPrivateKey() {
  final key = Platform.environment['EVM_PRIVATE_KEY'] ??
      Platform.environment['SECRET_KEY'];
  if (key != null && key.isNotEmpty) {
    print('  Using EVM_PRIVATE_KEY from environment');
    return key;
  }
  print('  Using default Anvil/Hardhat test key #0');
  return defaultTestKey;
}

/// Gets peer addresses from environment.
/// Returns null if ANT_PEERS is not set.
List<String>? getPeerAddresses() {
  final peersEnv = Platform.environment['ANT_PEERS'];
  if (peersEnv != null && peersEnv.isNotEmpty) {
    print('  Using ANT_PEERS from environment');
    return peersEnv.split(',').map((p) => p.trim()).toList();
  }
  // No default - use `antctl local status --details` to get addresses
  // and set ANT_PEERS environment variable
  return null;
}

/// Generates random data of the specified size.
String randomData(int size) {
  final random = Random();
  final chars = List.generate(size, (_) => random.nextInt(256));
  return String.fromCharCodes(chars);
}

void main() {
  group('Round-Trip Integration', () {
    late Client client;
    late Network network;
    late Wallet wallet;

    setUpAll(() async {
      print('\n=== Round-Trip Integration Test ===\n');

      // Get private key
      final privateKey = getEvmPrivateKey();

      // Create network
      print('Creating network...');
      network = Network.local();
      print('  Network created (local mode)');

      // Try initLocal() first, fall back to initWithPeers if ANT_PEERS is set
      print('Initializing client...');
      try {
        client = await Client.initLocal();
        print('  Client connected via initLocal()');
      } catch (e) {
        print('  initLocal() failed: $e');

        final peers = getPeerAddresses();
        if (peers != null) {
          print('  Trying initWithPeers()...');
          print('  Peer addresses: $peers');

          try {
            client = await Client.initWithPeers(peers, network);
            print('  Client connected via initWithPeers()');
          } catch (e2) {
            print('  ERROR: Both init methods failed');
            print('  initLocal error: $e');
            print('  initWithPeers error: $e2');
            rethrow;
          }
        } else {
          print('  ERROR: initLocal failed and ANT_PEERS not set');
          print('\n  Make sure local network is running (25+ nodes):');
          print('    antctl local status');
          print('\n  Or set ANT_PEERS from `antctl local status --details`');
          rethrow;
        }
      }

      // Create wallet
      print('Creating wallet...');
      try {
        wallet = Wallet.fromPrivateKey(network, privateKey);
        print('  Wallet address: ${wallet.address()}');
      } catch (e) {
        print('  ERROR: Failed to create wallet: $e');
        print('\n  Make sure EVM testnet is running');
        client.dispose();
        rethrow;
      }

      print('');
    });

    tearDownAll(() {
      print('\nCleanup...');
      wallet.dispose();
      network.dispose();
      client.dispose();
      print('  Resources disposed\n');
    });

    test('upload and download public data roundtrip', () async {
      // Generate test data
      final testData =
          'Hello from Dart FFI round-trip test! ${DateTime.now()} ${randomData(100)}';
      print('Test data size: ${testData.length} bytes');

      // Upload data
      print('Uploading data to network...');
      final result = await client.dataPutPublic(testData, wallet);
      print('  Upload successful!');
      print('  Address: ${result.address.toHex()}');
      print('  Cost: ${result.cost}');

      // Download data
      print('Downloading data from network...');
      final downloadedData = await client.dataGetPublic(result.address.toHex());
      print('  Download successful!');
      print('  Downloaded size: ${downloadedData.length} bytes');

      // Verify data
      print('Verifying data integrity...');
      expect(downloadedData, equals(testData),
          reason: 'Downloaded data should match original');
      print('  Data matches! Round-trip successful!');

      // Cleanup
      result.address.dispose();
    }, timeout: Timeout(Duration(minutes: 5)));
  });
}
