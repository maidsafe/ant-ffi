import 'package:test/test.dart';
import 'package:ant_ffi/ant_ffi.dart';

void main() {
  group('SecretKey', () {
    test('random creates valid key', () {
      final key = SecretKey.random();
      expect(key.toHex(), isNotEmpty);
      key.dispose();
    });

    test('random creates unique keys', () {
      final key1 = SecretKey.random();
      final key2 = SecretKey.random();

      expect(key1.toHex(), isNot(equals(key2.toHex())));

      key1.dispose();
      key2.dispose();
    });

    test('fromHex roundtrip', () {
      final key1 = SecretKey.random();
      final hex = key1.toHex();

      final key2 = SecretKey.fromHex(hex);
      expect(key2.toHex(), equals(hex));

      key1.dispose();
      key2.dispose();
    });

    test('publicKey derivation', () {
      final secret = SecretKey.random();
      final public = secret.publicKey();

      expect(public.toHex(), isNotEmpty);
      expect(public.toHex(), isNot(equals(secret.toHex())));

      secret.dispose();
      public.dispose();
    });

    test('same secret key produces same public key', () {
      final secret = SecretKey.random();
      final hex = secret.toHex();

      final public1 = secret.publicKey();
      secret.dispose();

      final secret2 = SecretKey.fromHex(hex);
      final public2 = secret2.publicKey();

      expect(public1.toHex(), equals(public2.toHex()));

      public1.dispose();
      public2.dispose();
      secret2.dispose();
    });

    test('throws after dispose', () {
      final key = SecretKey.random();
      key.dispose();

      expect(() => key.toHex(), throwsStateError);
    });
  });

  group('PublicKey', () {
    test('fromHex roundtrip', () {
      final secret = SecretKey.random();
      final public = secret.publicKey();
      final hex = public.toHex();

      final public2 = PublicKey.fromHex(hex);
      expect(public2.toHex(), equals(hex));

      secret.dispose();
      public.dispose();
      public2.dispose();
    });

    test('throws after dispose', () {
      final secret = SecretKey.random();
      final public = secret.publicKey();
      public.dispose();
      secret.dispose();

      expect(() => public.toHex(), throwsStateError);
    });
  });
}
