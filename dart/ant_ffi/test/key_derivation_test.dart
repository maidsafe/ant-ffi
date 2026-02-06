import 'dart:convert';
import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:ant_ffi/ant_ffi.dart';

void main() {
  group('DerivationIndex', () {
    test('random creates valid 32-byte index', () {
      final index = DerivationIndex.random();
      expect(index.toBytes().length, equals(32));
      index.dispose();
    });

    test('random creates unique indices', () {
      final index1 = DerivationIndex.random();
      final index2 = DerivationIndex.random();

      expect(index1.toBytes(), isNot(equals(index2.toBytes())));

      index1.dispose();
      index2.dispose();
    });

    test('fromBytes roundtrip', () {
      final index1 = DerivationIndex.random();
      final bytes = index1.toBytes();

      final index2 = DerivationIndex.fromBytes(bytes);
      expect(index2.toBytes(), equals(bytes));

      index1.dispose();
      index2.dispose();
    });

    test('fromBytes rejects wrong length', () {
      expect(
        () => DerivationIndex.fromBytes(Uint8List(16)),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws after dispose', () {
      final index = DerivationIndex.random();
      index.dispose();

      expect(() => index.toBytes(), throwsStateError);
    });
  });

  group('Signature', () {
    test('toBytes returns 96 bytes', () {
      final key = MainSecretKey.random();
      final message = utf8.encode('Test message');
      final signature = key.sign(Uint8List.fromList(message));

      expect(signature.toBytes().length, equals(96));

      signature.dispose();
      key.dispose();
    });

    test('fromBytes roundtrip', () {
      final key = MainSecretKey.random();
      final message = utf8.encode('Test message');
      final sig1 = key.sign(Uint8List.fromList(message));
      final bytes = sig1.toBytes();

      final sig2 = Signature.fromBytes(bytes);
      expect(sig2.toBytes(), equals(bytes));

      sig1.dispose();
      sig2.dispose();
      key.dispose();
    });

    test('fromBytes rejects wrong length', () {
      expect(
        () => Signature.fromBytes(Uint8List(32)),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('toHex returns 192 characters', () {
      final key = MainSecretKey.random();
      final message = utf8.encode('Test message');
      final signature = key.sign(Uint8List.fromList(message));

      final hex = signature.toHex();
      expect(hex.length, equals(192));
      expect(hex, matches(RegExp(r'^[0-9a-f]+$', caseSensitive: false)));

      signature.dispose();
      key.dispose();
    });

    test('parity returns boolean', () {
      final key = MainSecretKey.random();
      final signature = key.sign(Uint8List.fromList(utf8.encode('Test')));

      // Just verify it returns a valid boolean without throwing
      expect(signature.parity(), isA<bool>());

      signature.dispose();
      key.dispose();
    });

    test('throws after dispose', () {
      final key = MainSecretKey.random();
      final signature = key.sign(Uint8List.fromList(utf8.encode('Test')));
      signature.dispose();
      key.dispose();

      expect(() => signature.toBytes(), throwsStateError);
    });
  });

  group('MainSecretKey', () {
    test('random creates valid key', () {
      final key = MainSecretKey.random();
      expect(key.toBytes(), isNotEmpty);
      key.dispose();
    });

    test('random creates unique keys', () {
      final key1 = MainSecretKey.random();
      final key2 = MainSecretKey.random();

      expect(key1.toBytes(), isNot(equals(key2.toBytes())));

      key1.dispose();
      key2.dispose();
    });

    test('fromSecretKey creates valid key', () {
      final secretKey = SecretKey.random();
      final mainKey = MainSecretKey.fromSecretKey(secretKey);

      expect(mainKey.toBytes(), isNotEmpty);

      mainKey.dispose();
      secretKey.dispose();
    });

    test('publicKey returns valid MainPubkey', () {
      final secretKey = MainSecretKey.random();
      final publicKey = secretKey.publicKey();

      expect(publicKey.toHex(), isNotEmpty);

      publicKey.dispose();
      secretKey.dispose();
    });

    test('sign and verify', () {
      final secretKey = MainSecretKey.random();
      final publicKey = secretKey.publicKey();
      final message = Uint8List.fromList(utf8.encode('Hello, world!'));

      final signature = secretKey.sign(message);

      expect(publicKey.verify(signature, message), isTrue);

      signature.dispose();
      publicKey.dispose();
      secretKey.dispose();
    });

    test('signature invalid for wrong message', () {
      final secretKey = MainSecretKey.random();
      final publicKey = secretKey.publicKey();

      final signature = secretKey.sign(Uint8List.fromList(utf8.encode('correct message')));

      expect(
        publicKey.verify(signature, Uint8List.fromList(utf8.encode('wrong message'))),
        isFalse,
      );

      signature.dispose();
      publicKey.dispose();
      secretKey.dispose();
    });

    test('deriveKey returns DerivedSecretKey', () {
      final mainKey = MainSecretKey.random();
      final index = DerivationIndex.random();

      final derivedKey = mainKey.deriveKey(index);

      expect(derivedKey.publicKey().toHex(), isNotEmpty);

      derivedKey.dispose();
      index.dispose();
      mainKey.dispose();
    });

    test('randomDerivedKey returns DerivedSecretKey', () {
      final mainKey = MainSecretKey.random();

      final derivedKey = mainKey.randomDerivedKey();

      expect(derivedKey.publicKey().toHex(), isNotEmpty);

      derivedKey.dispose();
      mainKey.dispose();
    });

    test('multiple randomDerivedKey calls return different keys', () {
      final mainKey = MainSecretKey.random();

      final derived1 = mainKey.randomDerivedKey();
      final derived2 = mainKey.randomDerivedKey();

      expect(derived1.publicKey().toHex(), isNot(equals(derived2.publicKey().toHex())));

      derived1.dispose();
      derived2.dispose();
      mainKey.dispose();
    });

    test('throws after dispose', () {
      final key = MainSecretKey.random();
      key.dispose();

      expect(() => key.toBytes(), throwsStateError);
    });
  });

  group('MainPubkey', () {
    test('fromPublicKey creates valid key', () {
      final secretKey = SecretKey.random();
      final publicKey = secretKey.publicKey();

      final mainPubkey = MainPubkey.fromPublicKey(publicKey);

      expect(mainPubkey.toHex(), isNotEmpty);

      mainPubkey.dispose();
      publicKey.dispose();
      secretKey.dispose();
    });

    test('fromHex roundtrip', () {
      final mainKey = MainSecretKey.random();
      final pubkey = mainKey.publicKey();
      final hex = pubkey.toHex();

      final pubkey2 = MainPubkey.fromHex(hex);
      expect(pubkey2.toHex(), equals(hex));

      pubkey2.dispose();
      pubkey.dispose();
      mainKey.dispose();
    });

    test('toBytes returns valid bytes', () {
      final mainKey = MainSecretKey.random();
      final pubkey = mainKey.publicKey();

      expect(pubkey.toBytes(), isNotEmpty);

      pubkey.dispose();
      mainKey.dispose();
    });

    test('deriveKey returns DerivedPubkey', () {
      final mainKey = MainSecretKey.random();
      final mainPubkey = mainKey.publicKey();
      final index = DerivationIndex.random();

      final derivedPubkey = mainPubkey.deriveKey(index);

      expect(derivedPubkey.toHex(), isNotEmpty);

      derivedPubkey.dispose();
      index.dispose();
      mainPubkey.dispose();
      mainKey.dispose();
    });

    test('throws after dispose', () {
      final key = MainSecretKey.random();
      final pubkey = key.publicKey();
      pubkey.dispose();
      key.dispose();

      expect(() => pubkey.toHex(), throwsStateError);
    });
  });

  group('Key Derivation Consistency', () {
    test('derived keys match when using same index', () {
      final mainSecretKey = MainSecretKey.random();
      final mainPubkey = mainSecretKey.publicKey();
      final index = DerivationIndex.random();

      final derivedSecretKey = mainSecretKey.deriveKey(index);
      final derivedPubkeyFromSecret = derivedSecretKey.publicKey();

      final derivedPubkeyFromMain = mainPubkey.deriveKey(index);

      expect(
        derivedPubkeyFromSecret.toHex(),
        equals(derivedPubkeyFromMain.toHex()),
      );

      derivedPubkeyFromSecret.dispose();
      derivedPubkeyFromMain.dispose();
      derivedSecretKey.dispose();
      index.dispose();
      mainPubkey.dispose();
      mainSecretKey.dispose();
    });
  });

  group('DerivedSecretKey', () {
    test('fromSecretKey creates valid key', () {
      final secretKey = SecretKey.random();
      final derivedKey = DerivedSecretKey.fromSecretKey(secretKey);

      expect(derivedKey.publicKey().toHex(), isNotEmpty);

      derivedKey.dispose();
      secretKey.dispose();
    });

    test('publicKey returns DerivedPubkey', () {
      final mainKey = MainSecretKey.random();
      final derivedKey = mainKey.randomDerivedKey();

      final publicKey = derivedKey.publicKey();

      expect(publicKey.toHex(), isNotEmpty);

      publicKey.dispose();
      derivedKey.dispose();
      mainKey.dispose();
    });

    test('sign and verify', () {
      final mainKey = MainSecretKey.random();
      final derivedKey = mainKey.randomDerivedKey();
      final derivedPubkey = derivedKey.publicKey();
      final message = Uint8List.fromList(utf8.encode('Test message for derived key'));

      final signature = derivedKey.sign(message);

      expect(derivedPubkey.verify(signature, message), isTrue);

      signature.dispose();
      derivedPubkey.dispose();
      derivedKey.dispose();
      mainKey.dispose();
    });

    test('throws after dispose', () {
      final mainKey = MainSecretKey.random();
      final derivedKey = mainKey.randomDerivedKey();
      derivedKey.dispose();
      mainKey.dispose();

      expect(() => derivedKey.publicKey(), throwsStateError);
    });
  });

  group('DerivedPubkey', () {
    test('fromPublicKey creates valid key', () {
      final secretKey = SecretKey.random();
      final publicKey = secretKey.publicKey();

      final derivedPubkey = DerivedPubkey.fromPublicKey(publicKey);

      expect(derivedPubkey.toHex(), isNotEmpty);

      derivedPubkey.dispose();
      publicKey.dispose();
      secretKey.dispose();
    });

    test('fromHex roundtrip', () {
      final mainKey = MainSecretKey.random();
      final derivedKey = mainKey.randomDerivedKey();
      final pubkey = derivedKey.publicKey();
      final hex = pubkey.toHex();

      final pubkey2 = DerivedPubkey.fromHex(hex);
      expect(pubkey2.toHex(), equals(hex));

      pubkey2.dispose();
      pubkey.dispose();
      derivedKey.dispose();
      mainKey.dispose();
    });

    test('toBytes returns valid bytes', () {
      final mainKey = MainSecretKey.random();
      final derivedKey = mainKey.randomDerivedKey();
      final pubkey = derivedKey.publicKey();

      expect(pubkey.toBytes(), isNotEmpty);

      pubkey.dispose();
      derivedKey.dispose();
      mainKey.dispose();
    });

    test('throws after dispose', () {
      final mainKey = MainSecretKey.random();
      final derivedKey = mainKey.randomDerivedKey();
      final pubkey = derivedKey.publicKey();
      pubkey.dispose();
      derivedKey.dispose();
      mainKey.dispose();

      expect(() => pubkey.toHex(), throwsStateError);
    });
  });
}
