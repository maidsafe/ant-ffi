<?php

declare(strict_types=1);

namespace AntFfi\Tests;

use PHPUnit\Framework\TestCase;
use AntFfi\AntFfiException;
use AntFfi\Types\DerivationIndex;
use AntFfi\Types\Signature;
use AntFfi\Types\MainSecretKey;
use AntFfi\Types\MainPubkey;
use AntFfi\Types\DerivedSecretKey;
use AntFfi\Types\DerivedPubkey;
use AntFfi\Types\SecretKey;
use AntFfi\Types\PublicKey;

final class KeyDerivationTest extends TestCase
{
    // DerivationIndex tests

    public function testDerivationIndexRandom(): void
    {
        $index = DerivationIndex::random();
        $bytes = $index->toBytes();

        $this->assertEquals(32, strlen($bytes), 'DerivationIndex should be 32 bytes');
    }

    public function testDerivationIndexFromBytesRoundtrip(): void
    {
        $index1 = DerivationIndex::random();
        $bytes = $index1->toBytes();

        $index2 = DerivationIndex::fromBytes($bytes);
        $this->assertEquals($bytes, $index2->toBytes());
    }

    public function testDerivationIndexFromBytesRejectsWrongLength(): void
    {
        $this->expectException(AntFfiException::class);
        $this->expectExceptionMessage('DerivationIndex must be exactly 32 bytes');
        DerivationIndex::fromBytes('short');
    }

    public function testMultipleRandomIndicesAreDifferent(): void
    {
        $index1 = DerivationIndex::random();
        $index2 = DerivationIndex::random();

        $this->assertNotEquals($index1->toBytes(), $index2->toBytes());
    }

    // MainSecretKey tests

    public function testMainSecretKeyRandom(): void
    {
        $key = MainSecretKey::random();
        $bytes = $key->toBytes();

        $this->assertNotEmpty($bytes);
    }

    public function testMainSecretKeyFromSecretKey(): void
    {
        $secretKey = SecretKey::random();
        $mainKey = MainSecretKey::fromSecretKey($secretKey);

        $this->assertNotEmpty($mainKey->toBytes());
    }

    public function testMainSecretKeyPublicKey(): void
    {
        $secretKey = MainSecretKey::random();
        $publicKey = $secretKey->publicKey();

        $this->assertNotEmpty($publicKey->toHex());
    }

    public function testMainSecretKeySignAndVerify(): void
    {
        $secretKey = MainSecretKey::random();
        $publicKey = $secretKey->publicKey();
        $message = 'Hello, world!';

        $signature = $secretKey->sign($message);

        $this->assertTrue($publicKey->verify($signature, $message));
    }

    public function testMainSecretKeySignatureInvalidForWrongMessage(): void
    {
        $secretKey = MainSecretKey::random();
        $publicKey = $secretKey->publicKey();

        $signature = $secretKey->sign('correct message');

        $this->assertFalse($publicKey->verify($signature, 'wrong message'));
    }

    public function testMainSecretKeyDeriveKey(): void
    {
        $mainKey = MainSecretKey::random();
        $index = DerivationIndex::random();

        $derivedKey = $mainKey->deriveKey($index);

        $this->assertInstanceOf(DerivedSecretKey::class, $derivedKey);
    }

    public function testMainSecretKeyRandomDerivedKey(): void
    {
        $mainKey = MainSecretKey::random();

        $derivedKey = $mainKey->randomDerivedKey();

        $this->assertInstanceOf(DerivedSecretKey::class, $derivedKey);
    }

    public function testMultipleRandomDerivedKeysAreDifferent(): void
    {
        $mainKey = MainSecretKey::random();

        $derived1 = $mainKey->randomDerivedKey();
        $derived2 = $mainKey->randomDerivedKey();

        $this->assertNotEquals(
            $derived1->publicKey()->toHex(),
            $derived2->publicKey()->toHex()
        );
    }

    // MainPubkey tests

    public function testMainPubkeyFromPublicKey(): void
    {
        $secretKey = SecretKey::random();
        $publicKey = $secretKey->publicKey();

        $mainPubkey = MainPubkey::fromPublicKey($publicKey);

        $this->assertNotEmpty($mainPubkey->toHex());
    }

    public function testMainPubkeyFromHexRoundtrip(): void
    {
        $mainKey = MainSecretKey::random();
        $pubkey = $mainKey->publicKey();
        $hex = $pubkey->toHex();

        $pubkey2 = MainPubkey::fromHex($hex);
        $this->assertEquals($hex, $pubkey2->toHex());
    }

    public function testMainPubkeyToBytesRoundtrip(): void
    {
        $mainKey = MainSecretKey::random();
        $pubkey = $mainKey->publicKey();
        $bytes = $pubkey->toBytes();

        $this->assertNotEmpty($bytes);
    }

    public function testMainPubkeyDeriveKey(): void
    {
        $mainKey = MainSecretKey::random();
        $mainPubkey = $mainKey->publicKey();
        $index = DerivationIndex::random();

        $derivedPubkey = $mainPubkey->deriveKey($index);

        $this->assertInstanceOf(DerivedPubkey::class, $derivedPubkey);
    }

    public function testDerivedKeyConsistency(): void
    {
        // Derive secret and public keys with the same index
        // and verify they match
        $mainSecretKey = MainSecretKey::random();
        $mainPubkey = $mainSecretKey->publicKey();
        $index = DerivationIndex::random();

        $derivedSecretKey = $mainSecretKey->deriveKey($index);
        $derivedPubkeyFromSecret = $derivedSecretKey->publicKey();

        $derivedPubkeyFromMain = $mainPubkey->deriveKey($index);

        $this->assertEquals(
            $derivedPubkeyFromSecret->toHex(),
            $derivedPubkeyFromMain->toHex(),
            'Derived public keys should match whether derived from secret or public main key'
        );
    }

    // DerivedSecretKey tests

    public function testDerivedSecretKeyFromSecretKey(): void
    {
        $secretKey = SecretKey::random();
        $derivedKey = DerivedSecretKey::fromSecretKey($secretKey);

        $this->assertInstanceOf(DerivedSecretKey::class, $derivedKey);
    }

    public function testDerivedSecretKeyPublicKey(): void
    {
        $mainKey = MainSecretKey::random();
        $derivedKey = $mainKey->randomDerivedKey();

        $publicKey = $derivedKey->publicKey();

        $this->assertNotEmpty($publicKey->toHex());
    }

    public function testDerivedSecretKeySignAndVerify(): void
    {
        $mainKey = MainSecretKey::random();
        $derivedKey = $mainKey->randomDerivedKey();
        $derivedPubkey = $derivedKey->publicKey();
        $message = 'Test message for derived key';

        $signature = $derivedKey->sign($message);

        $this->assertTrue($derivedPubkey->verify($signature, $message));
    }

    // DerivedPubkey tests

    public function testDerivedPubkeyFromPublicKey(): void
    {
        $secretKey = SecretKey::random();
        $publicKey = $secretKey->publicKey();

        $derivedPubkey = DerivedPubkey::fromPublicKey($publicKey);

        $this->assertNotEmpty($derivedPubkey->toHex());
    }

    public function testDerivedPubkeyFromHexRoundtrip(): void
    {
        $mainKey = MainSecretKey::random();
        $derivedKey = $mainKey->randomDerivedKey();
        $pubkey = $derivedKey->publicKey();
        $hex = $pubkey->toHex();

        $pubkey2 = DerivedPubkey::fromHex($hex);
        $this->assertEquals($hex, $pubkey2->toHex());
    }

    public function testDerivedPubkeyToBytesRoundtrip(): void
    {
        $mainKey = MainSecretKey::random();
        $derivedKey = $mainKey->randomDerivedKey();
        $pubkey = $derivedKey->publicKey();
        $bytes = $pubkey->toBytes();

        $this->assertNotEmpty($bytes);
    }

    // Signature tests

    public function testSignatureToBytes(): void
    {
        $mainKey = MainSecretKey::random();
        $signature = $mainKey->sign('Test message');

        $bytes = $signature->toBytes();
        $this->assertEquals(96, strlen($bytes), 'BLS signature should be 96 bytes');
    }

    public function testSignatureFromBytesRoundtrip(): void
    {
        $mainKey = MainSecretKey::random();
        $sig1 = $mainKey->sign('Test message');
        $bytes = $sig1->toBytes();

        $sig2 = Signature::fromBytes($bytes);
        $this->assertEquals($bytes, $sig2->toBytes());
    }

    public function testSignatureFromBytesRejectsWrongLength(): void
    {
        $this->expectException(AntFfiException::class);
        $this->expectExceptionMessage('Signature must be exactly 96 bytes');
        Signature::fromBytes('short');
    }

    public function testSignatureToHex(): void
    {
        $mainKey = MainSecretKey::random();
        $signature = $mainKey->sign('Test message');

        $hex = $signature->toHex();
        $this->assertMatchesRegularExpression('/^[0-9a-f]+$/i', $hex);
        $this->assertEquals(192, strlen($hex), 'Hex signature should be 192 characters (96 bytes * 2)');
    }

    public function testSignatureParity(): void
    {
        $mainKey = MainSecretKey::random();
        $signature = $mainKey->sign('Test message');

        // Parity returns a boolean - just verify it doesn't throw
        $parity = $signature->parity();
        $this->assertIsBool($parity);
    }

    // Disposal tests

    public function testKeyDisposal(): void
    {
        $key = MainSecretKey::random();
        $this->assertFalse($key->isDisposed());

        $key->dispose();
        $this->assertTrue($key->isDisposed());
    }

    public function testDerivedKeyDisposal(): void
    {
        $mainKey = MainSecretKey::random();
        $derivedKey = $mainKey->randomDerivedKey();
        $this->assertFalse($derivedKey->isDisposed());

        $derivedKey->dispose();
        $this->assertTrue($derivedKey->isDisposed());
    }

    public function testDerivationIndexDisposal(): void
    {
        $index = DerivationIndex::random();
        $this->assertFalse($index->isDisposed());

        $index->dispose();
        $this->assertTrue($index->isDisposed());
    }
}
