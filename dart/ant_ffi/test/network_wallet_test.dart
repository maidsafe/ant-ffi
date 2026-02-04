import 'package:test/test.dart';
import 'package:ant_ffi/ant_ffi.dart';

/// Default Anvil/Hardhat test private key #0 (pre-funded on local testnets)
const defaultTestKey =
    '0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80';

void main() {
  group('Network', () {
    test('create local network', () {
      final network = Network.local();
      expect(network, isNotNull);
      network.dispose();
    });

    test('create mainnet network', () {
      final network = Network.mainnet();
      expect(network, isNotNull);
      network.dispose();
    });

    test('throws after dispose', () {
      final network = Network.local();
      network.dispose();
      // Accessing handle after dispose should throw
      expect(() => network.handle, throwsStateError);
    });
  });

  group('Wallet', () {
    test('create wallet from private key', () {
      final network = Network.local();
      final wallet = Wallet.fromPrivateKey(network, defaultTestKey);

      expect(wallet, isNotNull);

      wallet.dispose();
      network.dispose();
    });

    test('get wallet address', () {
      final network = Network.local();
      final wallet = Wallet.fromPrivateKey(network, defaultTestKey);

      final address = wallet.address();
      expect(address, isNotEmpty);
      // Anvil test key #0 address
      expect(address.toLowerCase(), contains('0x'));

      wallet.dispose();
      network.dispose();
    });

    test('same private key produces same address', () {
      final network = Network.local();
      final wallet1 = Wallet.fromPrivateKey(network, defaultTestKey);
      final wallet2 = Wallet.fromPrivateKey(network, defaultTestKey);

      expect(wallet1.address(), equals(wallet2.address()));

      wallet1.dispose();
      wallet2.dispose();
      network.dispose();
    });

    test('throws after dispose', () {
      final network = Network.local();
      final wallet = Wallet.fromPrivateKey(network, defaultTestKey);
      wallet.dispose();

      expect(() => wallet.address(), throwsStateError);

      network.dispose();
    });
  });

  group('DataAddress', () {
    test('fromHex roundtrip', () {
      // Create a valid hex address (64 chars = 32 bytes)
      const hexAddress =
          '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';

      final address = DataAddress.fromHex(hexAddress);
      final hex = address.toHex();

      expect(hex, equals(hexAddress));

      address.dispose();
    });

    test('throws after dispose', () {
      const hexAddress =
          '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';

      final address = DataAddress.fromHex(hexAddress);
      address.dispose();

      expect(() => address.toHex(), throwsStateError);
    });
  });
}
